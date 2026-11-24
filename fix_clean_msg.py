p = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(p, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

good_line = '          "text": "\u12e8\u130d\u1295\u1299\u1290\u1275 \u1235\u1205\u1270\u1275\u1361 \u12a8\u1263\u12ad\u12a4\u1295\u12f5 \u1230\u122d\u1268\u1229 \u130b\u122d \u1218\u130c\u1293\u1298\u1275 \u12a0\u120d\u1270\u127b\u1208\u121d\u1361",\n'

for i, line in enumerate(lines):
    if '"text":' in line and ("መሌናኘት" in line or "መጌናኘት" in line or "መገናኘት" in line or "ከባክኤንድ" in line or "\ufffd" in line):
        lines[i] = good_line

with open(p, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("CLEAN_NOW")
