import json
import os
from backend.icd11_kb import ICD11_KB

os.makedirs("assets", exist_ok=True)
cleaned = []
for item in ICD11_KB:
    cleaned.append({
        "code": str(item.get("code", "")).strip(),
        "name": str(item.get("name", "")).strip(),
        "chapter": str(item.get("chapter", "")).strip(),
        "definition": str(item.get("definition", "")).strip(),
        "synonyms": str(item.get("synonyms", "")).strip(),
    })

with open("assets/icd11_kb.json", "w", encoding="utf-8") as f:
    json.dump(cleaned, f, ensure_ascii=False)

print(f"Successfully exported {len(cleaned)} ICD-11 records to assets/icd11_kb.json")
