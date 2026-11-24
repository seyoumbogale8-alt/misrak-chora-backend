path = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(path, "r", encoding="utf-8", errors="replace") as f:
    text = f.read()

def u(codes):
    return "".join(chr(c) for c in codes)

# ትክክለኛ አማርኛ በ code points ብቻ:
# ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል
hosp = u([0x121d, 0x1235, 0x122b, 0x1245, 0x20, 0x12d5, 0x12dd, 0x20, 0x12f0, 0x1228, 0x1303, 0x20, 0x33, 0x20, 0x1206, 0x1235, 0x1352, 0x1273, 0x120d])

# የመገናኛ አድራሻዎች
contact_am = u([0x12e8, 0x1218, 0x130c, 0x1293, 0x129b, 0x20, 0x12a0, 0x12f5, 0x122b, 0x123b, 0x12ce, 0x127d])

# የግንኙነት ስህተት፡ ከባክኤንድ ሰርቨሩ ጋር መገናኘት አልተቻለም፡
conn_err = u([
    0x12e8, 0x130d, 0x1295, 0x1299, 0x1290, 0x1275, 0x20,
    0x1235, 0x1205, 0x1270, 0x1275, 0x1361, 0x20,
    0x12a8, 0x1263, 0x12a5, 0x1254, 0x1295, 0x12f5, 0x20,
    0x1230, 0x122d, 0x1268, 0x1229, 0x20, 0x130b, 0x122d, 0x20,
    0x1218, 0x130c, 0x1293, 0x1298, 0x1275, 0x20,
    0x12a0, 0x120d, 0x1270, 0x1308, 0x129d, 0x1208, 0x121d, 0x1361
])

import re

# 1. Sidebar subtitle (fontSize: 11 ያለበት)
text = re.sub(
    r"('[^']*',\s*style:\s*const TextStyle\(\s*color:\s*_textMuted,\s*fontSize:\s*11)",
    f"'{hosp}',\n                          style: const TextStyle(\n                            color: _textMuted,\n                            fontSize: 11",
    text,
)

# 2. Address line 1 (East Command Level 3 Hospital - ECL3H)
text = re.sub(
    r"'[^']*\(East Command Level 3 Hospital - ECL3H\)\\n'",
    f"'{hosp} (East Command Level 3 Hospital - ECL3H)\\\\n'",
    text,
)

# 3. Contact / የመገናኛ አድራሻዎች
text = re.sub(
    r"'Contact / [^']*'",
    f"'Contact / {contact_am}'",
    text,
)

# 4. Connection error strings inside "text": "..."
text = re.sub(
    r'("text":\s*)"[^"]*\u12a8\u1263\u12ad\u12a4\u1295\u12f5[^"]*"',
    rf'\1"{conn_err}"',
    text,
)

# 5. ከላይ የተበላሸው ሆስፒታል ያለባቸውን የተዛቡ ቅርጾች ማጽዳት
text = text.replace(u([0x121d, 0x1235, 0x122b, 0x1245, 0x20, 0x12d5, 0x12dd, 0x20, 0x12f0, 0x1228, 0x1303, 0x20, 0x33, 0x20, 0x1206, 0x1235, 0x1273, 0x120b]), hosp)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("PERFECT_FIX_APPLIED")
