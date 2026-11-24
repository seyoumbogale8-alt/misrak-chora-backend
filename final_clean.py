p = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(p, "r", encoding="utf-8", errors="replace") as f:
    s = f.read()

def u(codes):
    return "".join(chr(c) for c in codes)

hosp = u([0x121d, 0x1235, 0x122b, 0x1245, 0x20, 0x12d5, 0x12dd, 0x20, 0x12f0, 0x1228, 0x1303, 0x20, 0x33, 0x20, 0x1206, 0x1235, 0x1352, 0x1273, 0x120d])
contact_am = u([0x12e8, 0x1218, 0x130c, 0x1293, 0x129b, 0x20, 0x12a0, 0x12f5, 0x122b, 0x123b, 0x12ce, 0x127d])
conn_err = u([
    0x12e8, 0x130d, 0x1295, 0x1299, 0x1290, 0x1275, 0x20,
    0x1235, 0x1205, 0x1270, 0x1275, 0x1361, 0x20,
    0x12a8, 0x1263, 0x12a5, 0x1254, 0x1295, 0x12f5, 0x20,
    0x1230, 0x122d, 0x1268, 0x1229, 0x20, 0x130b, 0x122d, 0x20,
    0x1218, 0x130c, 0x1293, 0x1298, 0x1275, 0x20,
    0x12a0, 0x120d, 0x1270, 0x1308, 0x129d, 0x1208, 0x121d, 0x1361
])

lines = s.splitlines(keepends=True)
for i, line in enumerate(lines):
    if '"text":' in line and ("0x12" in line or "12e8" in line or "12a8" in line or "1218" in line or "130c" in line or "1293" in line or "1298" in line or "1275" in line or "12a0" in line or "120d" in line or "1270" in line or "1308" in line or "129d" in line or "1208" in line or "121d" in line or "1361" in line or "1235" in line or "1205" in line or "1230" in line or "122d" in line or "1268" in line or "1229" in line or "130b" in line or "0x" in line or "መ" in line or "ሆ" in line or "" in line or "?" in line):
        if i > 180 and i < 360:
            lines[i] = f'          "text": "{conn_err}",\n'
    if "fontSize: 11" in "".join(lines[i:min(len(lines), i+4)]) and i < 570:
        lines[i] = f"                        '{hosp}',\n"
    if "(East Command Level 3 Hospital - ECL3H)" in line:
        lines[i] = f"            '{hosp} (East Command Level 3 Hospital - ECL3H)\\\\n'\n"
    if "Contact / " in line:
        lines[i] = f"            'Contact / {contact_am}',\n"

with open(p, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("FINAL_CLEAN")
