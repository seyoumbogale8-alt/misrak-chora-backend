import json
from pathlib import Path
import pandas as pd

CANDIDATE_FILES = [
    Path(
        r"C:\Users\eastc\Downloads\38833FF26BA1D.UnigramPreview_g9c9v27vpyspw!App\Copy of ESV_ICD11Disease_Injury_Editions_Final_Version _2.xlsx"
    ),
    Path("Copy of ESV_ICD11Disease_Injury_Editions_Final_Version _2.xlsx"),
]

OUTPUT_FILE = Path("backend") / "icd11_kb.py"

SKIP_SHEETS = {"Sheet1"}


def find_excel_file() -> Path:
    for p in CANDIDATE_FILES:
        if p.exists():
            return p
    raise FileNotFoundError(
        "የ ICD-11 Excel ፋይሉ አልተገኘም። እባክህ የፋይሉን መንገድ አረጋግጥ።"
    )


def clean_text(val) -> str:
    if pd.isna(val):
        return ""
    s = str(val).strip()
    return "" if s.lower() in {"nan", "none", "null"} else s


def pick_column(row: pd.Series, candidates: list[str]) -> str:
    lower_map = {str(k).strip().lower(): k for k in row.index}
    for cand in candidates:
        key = lower_map.get(cand.strip().lower())
        if key is not None:
            val = clean_text(row.get(key))
            if val:
                return val
    return ""


def main():
    excel_path = find_excel_file()
    print(f"የተገኘው Excel ፋይል: {excel_path}")

    xl = pd.ExcelFile(excel_path)
    sheets = xl.sheet_names
    print(f"የተገኙ Sheets: {sheets}")

    records = []
    seen_keys = set()

    for sheet_name in sheets:
        if sheet_name in SKIP_SHEETS:
            continue

        df = pd.read_excel(excel_path, sheet_name=sheet_name)
        print(f"  - '{sheet_name}' እየተነበበ ነው ({len(df)} ረድፎች)...")

        for _, row in df.iterrows():
            code = pick_column(row, ["Code", "ICD Code", "ICD-11 Code"])
            raw_cat = pick_column(row, ["Category", "Title", "Name", "Disease", "Condition"])
            name = (
                raw_cat.replace("- - -", "")
                .replace("- -", "")
                .lstrip("- ")
                .strip()
            )
            chapter = pick_column(row, ["Chapter Name", "Chapter", "Block"])
            definition = pick_column(
                row, ["Defination", "Definition", "Description", "Desc"]
            )
            synonyms = pick_column(
                row, ["Synonymus", "synonymous", "Synonyms", "Synonym", "Inclusion"]
            )

            # በራሱ ረድፍ ውስጥ ያሉ ሌሎች ጠቃሚ ጽሑፎችንም አጠቃላይ መፈለጊያ እንዲሆኑ ማሰባሰብ
            extra_parts = []
            for col_name, val in row.items():
                txt = clean_text(val)
                if txt and txt not in {code, raw_cat, name, chapter, definition, synonyms}:
                    extra_parts.append(f"{col_name}: {txt}")
            extra_info = " | ".join(extra_parts)

            if not (code or name or definition or synonyms or extra_info):
                continue

            dedup_key = (
                sheet_name.strip().lower(),
                code.lower(),
                name.lower(),
                definition[:120].lower(),
            )
            if dedup_key in seen_keys:
                continue
            seen_keys.add(dedup_key)

            records.append({
                "sheet": sheet_name,
                "code": code,
                "name": name if name else (code if code else sheet_name),
                "chapter": chapter,
                "definition": definition,
                "synonyms": synonyms,
                "extra": extra_info,
            })

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    py_content = (
        "# Auto-generated Full ICD-11 Knowledge Base (All Sheets)\n"
        f"# Total entries: {len(records)}\n\n"
        "ICD11_KB = " + json.dumps(records, ensure_ascii=False, indent=2) + "\n"
    )
    OUTPUT_FILE.write_text(py_content, encoding="utf-8")
    print(f"ተሳክቷል! በድምሩ {len(records)} entries ከሁሉም sheets ወደ {OUTPUT_FILE} ገብተዋል።")


if __name__ == "__main__":
    main()