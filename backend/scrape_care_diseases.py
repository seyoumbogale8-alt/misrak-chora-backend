import json
import os
import re
import time
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.carehospitals.com/am/diseases-conditions"
OUTPUT_FILE = "care_am_diseases.json"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "am,en-US;q=0.9,en;q=0.8",
}


def clean_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def load_existing_data(filepath: str) -> list:
    if os.path.exists(filepath):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
        except Exception as e:
            print(f"ማስጠንቀቂያ፡ ነባር ፋይል ማንበብ አልተቻለም ({e})")
    return []


def save_data(filepath: str, records: list):
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)


def get_soup(url: str, retries: int = 3):
    for attempt in range(1, retries + 1):
        try:
            resp = requests.get(url, headers=HEADERS, timeout=25)
            if resp.status_code == 200:
                resp.encoding = resp.apparent_encoding or "utf-8"
                return BeautifulSoup(resp.text, "html.parser")
            elif resp.status_code == 404:
                return None
        except Exception as e:
            if attempt == retries:
                print(f"የኔትወርክ ስህተት ({url}): {e}")
            time.sleep(1.5 * attempt)
    return None


def discover_disease_links(start_url: str) -> dict:
    """
    ከዋናው የ Care Hospitals የበሽታዎች ገጽ (እና የ pagination/alphabet ገጾች ካሉ)
    የእያንዳንዱን በሽታ ዝርዝር ሊንክ ይሰበስባል።
    """
    visited_pages = set()
    queue_pages = [start_url]
    disease_links = {}  # url -> title

    while queue_pages:
        page_url = queue_pages.pop(0)
        if page_url in visited_pages:
            continue
        visited_pages.add(page_url)

        print(f"ገጽ በመፈተሽ ላይ፡ {page_url}")
        soup = get_soup(page_url)
        if not soup:
            continue

        for a_tag in soup.find_all("a", href=True):
            href = a_tag["href"].strip()
            if not href or href.startswith("#") or href.startswith("javascript:"):
                continue

            full_url = urljoin(page_url, href).split("#")[0].rstrip("/")
            parsed = urlparse(full_url)

            if "carehospitals.com" not in parsed.netloc:
                continue

            path = parsed.path

            # ተጨማሪ የ diseases-conditions ዝርዝር/pagination ገጾች ካሉ
            if "/am/diseases-conditions" in path and path != "/am/diseases-conditions":
                # የአንድ በሽታ ዝርዝር ገጽ ወይስ ሌላ የዝርዝር ገጽ መሆኑን ለመለየት
                parts = [p for p in path.split("/") if p]
                # ብዙውን ጊዜ /am/diseases-conditions/<disease-slug> 3 ክፍሎች አሉት
                if len(parts) >= 3 and parts[0] == "am" and parts[1] == "diseases-conditions":
                    title = clean_text(a_tag.get_text(" ", strip=True))
                    if not title:
                        title = parts[-1].replace("-", " ").title()
                    if full_url not in disease_links:
                        disease_links[full_url] = title
                elif ("page" in full_url.lower() or "alphabet" in full_url.lower()) and full_url not in visited_pages:
                    if full_url not in queue_pages:
                        queue_pages.append(full_url)

    return disease_links


def extract_sections_from_soup(soup: BeautifulSoup) -> dict:
    """
    ከበሽታው ገጽ ውስጥ ምንነት (Overview)፣ ምልክቶች (Symptoms)፣
    መንስኤዎች (Causes) እና ሕክምና (Treatment) ይለያል።
    """
    container = (
        soup.find("main")
        or soup.find("article")
        or soup.find("div", class_=re.compile(r"(content|detail|disease|condition|body)", re.I))
        or soup.body
    )

    sections = {
        "overview": [],
        "symptoms": [],
        "causes": [],
        "treatment": [],
        "other": [],
    }

    if not container:
        return {k: "" for k in sections}

    current_bucket = "overview"

    # የርዕስ መለያ ቁልፍ ቃላት (አማርኛ እና እንግሊዝኛ)
    heading_map = {
        "symptoms": [
            "ምልክት", "ምልክቶች", "symptom", "symptoms", "signs"
        ],
        "causes": [
            "መንስኤ", "መንስኤዎች", "cause", "causes", "risk factor", "risk factors"
        ],
        "treatment": [
            "ሕክምና", "ህክምና", "ማከም", "መከላከል", "treatment", "treatments",
            "therapy", "management", "prevention", "remedies"
        ],
        "overview": [
            "ምንነት", "መግቢያ", "አጠቃላይ", "overview", "about", "what is", "definition"
        ],
    }

    elements = container.find_all(["h1", "h2", "h3", "h4", "p", "li"], recursive=True)

    for el in elements:
        txt = clean_text(el.get_text(" ", strip=True))
        if not txt or len(txt) < 2:
            continue

        # የአሰሳ/ሜኑ ጽሁፎችን ለማስወገድ
        if el.find_parent(["nav", "header", "footer"]):
            continue

        if el.name in ["h1", "h2", "h3", "h4"]:
            lower_txt = txt.lower()
            matched = None
            for bucket, keywords in heading_map.items():
                if any(kw in lower_txt for kw in keywords):
                    matched = bucket
                    break
            if matched:
                current_bucket = matched
            else:
                current_bucket = "other"
            continue

        if el.name == "li":
            formatted = f"• {txt}"
        else:
            formatted = txt

        # ተደጋጋሚ መስመሮችን መከላከል
        if not sections[current_bucket] or sections[current_bucket][-1] != formatted:
            sections[current_bucket].append(formatted)

    # overview ባዶ ከሆነ የመጀመሪያዎቹን paragraphs መውሰድ
    if not sections["overview"]:
        fallback_paras = [
            clean_text(p.get_text(" ", strip=True))
            for p in container.find_all("p")
            if len(clean_text(p.get_text(" ", strip=True))) > 25
        ]
        sections["overview"] = fallback_paras[:3]

    return {
        "overview": "\n".join(sections["overview"]).strip(),
        "symptoms": "\n".join(sections["symptoms"]).strip(),
        "causes": "\n".join(sections["causes"]).strip(),
        "treatment": "\n".join(sections["treatment"]).strip(),
    }


def extract_disease_details(url: str, fallback_title: str) -> dict | None:
    soup = get_soup(url)
    if not soup:
        return None

    h1 = soup.find("h1")
    title = clean_text(h1.get_text(" ", strip=True)) if h1 else fallback_title
    if not title:
        title = fallback_title

    details = extract_sections_from_soup(soup)

    # ምንም መረጃ ካልተገኘ መዝለል
    if not any(details.values()):
        return None

    return {
        "source": "carehospitals.com",
        "url": url,
        "disease_name": title,
        "overview": details["overview"],
        "symptoms": details["symptoms"],
        "causes": details["causes"],
        "treatment": details["treatment"],
    }


def main():
    existing_records = load_existing_data(OUTPUT_FILE)
    done_urls = {item.get("url") for item in existing_records if item.get("url")}

    all_links = discover_disease_links(BASE_URL)
    remaining = [(u, t) for u, t in all_links.items() if u not in done_urls]

    print(f"\nጠቅላላ የተገኙ የበሽታ ሊንኮች፡ {len(all_links)}")
    print(f"ቀደም ብለው የተቀመጡ፡ {len(done_urls)} | አዲስ የሚሰበሰቡ፡ {len(remaining)}\n")

    for idx, (url, title) in enumerate(remaining, start=1):
        record = extract_disease_details(url, title)
        if record:
            existing_records.append(record)
            status = "OK"
        else:
            status = "SKIP"

        if idx % 10 == 0 or idx == len(remaining):
            save_data(OUTPUT_FILE, existing_records)
            print(f"[{idx}/{len(remaining)}] ተቀምጧል ({status}) - {title[:45]}")
        else:
            print(f"[{idx}/{len(remaining)}] ({status}) - {title[:45]}")

        time.sleep(0.35)

    save_data(OUTPUT_FILE, existing_records)
    print(f"\nተጠናቋል! ጠቅላላ የተቀመጡ የበሽታ መረጃዎች፡ {len(existing_records)} -> {OUTPUT_FILE}")


if __name__ == "__main__":
    main()