import json
import os
import re
import time
from urllib.parse import urljoin, urlparse, parse_qs, urlencode
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.medicoverhospitals.in/am/diseases/"
OUTPUT_FILE = "medicover_am_diseases.json"
MAX_PAGES = 67

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "am,en-US;q=0.9,en;q=0.8",
}


def fetch_soup(url: str, retries: int = 3, delay: float = 0.8):
    for attempt in range(1, retries + 1):
        try:
            resp = requests.get(url, headers=HEADERS, timeout=25)
            if resp.status_code == 200:
                resp.encoding = resp.apparent_encoding or "utf-8"
                return BeautifulSoup(resp.text, "html.parser")
        except requests.RequestException:
            pass
        time.sleep(delay * attempt)
    return None


def build_page_url(page_num: int) -> str:
    if page_num == 1:
        return BASE_URL
    parsed = urlparse(BASE_URL)
    qs = parse_qs(parsed.query)
    qs["page"] = [str(page_num)]
    new_query = urlencode(qs, doseq=True)
    return parsed._replace(query=new_query).geturl()


def extract_disease_links_from_page(soup: BeautifulSoup, page_url: str):
    links = {}
    if not soup:
        return links

    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        full_url = urljoin(page_url, href)
        parsed = urlparse(full_url)

        if "medicoverhospitals.in" not in parsed.netloc:
            continue
        if "/am/diseases/" not in parsed.path:
            continue

        path_clean = parsed.path.rstrip("/")
        # የዋናውን /am/diseases ገጽ እና የፊደል/page ሊንኮችን መለየት
        if path_clean.endswith("/am/diseases"):
            continue
        if re.search(r"/(page|letter)/", path_clean, re.IGNORECASE):
            continue

        title = " ".join(a.get_text(" ", strip=True).split())
        if len(title) < 2:
            continue
        # የፊደል ማጣሪያ ቁልፎች (A-Z / ሁሉ) ከሆኑ ዝለል
        if title.upper() in {
            "ሁሉ", "ALL", "A", "B", "C", "D", "E", "F", "G", "H", "I",
            "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
            "V", "W", "X", "Y", "Z"
        }:
            continue

        clean_url = f"{parsed.scheme}://{parsed.netloc}{parsed.path}"
        if clean_url not in links:
            links[clean_url] = title

    return links


def clean_text_blocks(elements):
    lines = []
    for el in elements:
        txt = " ".join(el.get_text(" ", strip=True).split())
        if txt and txt not in lines:
            lines.append(txt)
    return "\n".join(lines).strip()


def extract_disease_details(url: str, fallback_title: str):
    soup = fetch_soup(url)
    if not soup:
        return None

    for tag in soup(["script", "style", "noscript", "header", "footer", "nav", "form"]):
        tag.decompose()

    main_container = (
        soup.find("main")
        or soup.find("article")
        or soup.find(class_=re.compile(r"(disease|content|detail|article|main)", re.I))
        or soup.body
    )
    if not main_container:
        return None

    h1 = main_container.find(["h1", "h2"])
    title = " ".join(h1.get_text(" ", strip=True).split()) if h1 else fallback_title

    sections = {
        "overview": "",
        "causes": "",
        "types": "",
        "treatment": "",
        "doctor": "",
        "faqs": "",
        "full_text": "",
    }

    current_key = "overview"
    section_buffers = {k: [] for k in sections if k != "full_text"}

    headings = main_container.find_all(["h1", "h2", "h3", "h4", "strong"])
    all_blocks = main_container.find_all(["h1", "h2", "h3", "h4", "p", "li", "ul", "ol", "div"])

    # በርዕሶች መሰረት ክፍሎችን መመደብ
    for block in all_blocks:
        if block.name in {"div", "ul", "ol"} and block.find(["p", "li", "h2", "h3"]):
            continue

        text = " ".join(block.get_text(" ", strip=True).split())
        if not text or len(text) < 2:
            continue

        if block.name in {"h1", "h2", "h3", "h4"}:
            lower_t = text.lower()
            if "መንስኤ" in text or "cause" in lower_t:
                current_key = "causes"
                continue
            elif "ዓይነት" in text or "type" in lower_t or "kind" in lower_t:
                current_key = "types"
                continue
            elif "ማከም" in text or "ሕክምና" in text or "treatment" in lower_t or "management" in lower_t:
                current_key = "treatment"
                continue
            elif "ዶክተር" in text or "doctor" in lower_t or "specialist" in lower_t:
                current_key = "doctor"
                continue
            elif "ተደጋጋሚ" in text or "ጥያቄ" in text or "faq" in lower_t or "question" in lower_t:
                current_key = "faqs"
                continue
            else:
                current_key = "overview"
                continue

        if text not in section_buffers[current_key]:
            section_buffers[current_key].append(text)

    for k, buf in section_buffers.items():
        sections[k] = "\n".join(buf).strip()

    combined_parts = [
        f"በሽታ: {title}",
        f"መግቢያ: {sections['overview']}" if sections["overview"] else "",
        f"የበሽታው ዓይነት: {sections['types']}" if sections["types"] else "",
        f"መንስኤዎች: {sections['causes']}" if sections["causes"] else "",
        f"ማከም: {sections['treatment']}" if sections["treatment"] else "",
        f"ዶክተር ያግኙ: {sections['doctor']}" if sections["doctor"] else "",
        f"ተደጋጋሚ ጥያቄዎች: {sections['faqs']}" if sections["faqs"] else "",
    ]
    sections["full_text"] = "\n\n".join([p for p in combined_parts if p]).strip()

    return {
        "title": title,
        "url": url,
        **sections,
    }


def load_existing_data():
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
        except Exception:
            pass
    return []


def save_data(data):
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def main():
    print("1/2: ከ 1 እስከ 67 ያሉትን ገጾች በመቃኘት የበሽታ ሊንኮችን በመሰብሰብ ላይ...")
    all_links = {}

    for page_num in range(1, MAX_PAGES + 1):
        page_url = build_page_url(page_num)
        soup = fetch_soup(page_url)
        page_links = extract_disease_links_from_page(soup, page_url)
        before_count = len(all_links)
        all_links.update(page_links)
        added = len(all_links) - before_count
        print(f"   ገጽ {page_num}/{MAX_PAGES}: +{added} አዲስ ሊንክ (ጠቅላላ: {len(all_links)})")
        time.sleep(0.4)

    existing_records = load_existing_data()
    done_urls = {item.get("url") for item in existing_records if item.get("url")}
    remaining = [(u, t) for u, t in all_links.items() if u not in done_urls]

    print(f"\n2/2: ቀድሞ የተቀመጡ: {len(existing_records)} | አዲስ የሚወጡ: {len(remaining)}")

    for idx, (url, title) in enumerate(remaining, start=1):
        detail = extract_disease_details(url, title)
        if detail:
            existing_records.append(detail)
            status = "OK"
        else:
            status = "SKIP"

        if idx % 10 == 0 or idx == len(remaining):
            save_data(existing_records)
            print(f"   [{idx}/{len(remaining)}] ተቀምጧል ({status}) - {title[:45]}")

        time.sleep(0.35)

    save_data(existing_records)
    print(f"\nተጠናቋል! ጠቅላላ የተቀመጡ በሽታዎች: {len(existing_records)} -> {OUTPUT_FILE}")


if __name__ == "__main__":
    main()