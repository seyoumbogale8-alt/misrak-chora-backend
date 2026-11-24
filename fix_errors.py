p = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
s = open(p, encoding="utf-8", errors="replace").read()

s = s.replace(
    "\u1218\u120d\u1235 \u12a0\u120d\u1270\u1308\u1298\u121d\u1361",
    "\u1218\u120d\u1235 \u12a0\u120d\u1270\u1308\u1298\u121d\u1361"
)

import re
# Replace corrupted fallback strings inside _sendQuery catch/else blocks
s = re.sub(
    r'("[^"]*[\ufffd?][^"]*ስህተት[^"]*")',
    '"\u12e8\u130d\u1295\u1299\u1290\u1275 \u1235\u1205\u1270\u1275\u1361 \u12a8\u1263\u12ad\u12a4\u1295\u12f5 \u1230\u122d\u1268\u1229 \u130b\u122d \u1218\u130c\u1293\u1298\u1275 \u12a0\u120d\u1270\u127b\u1208\u121d\u1361"',
    s
)

# Direct replacement for the exact corrupted connection error line in _sendQuery
lines = s.splitlines(keepends=True)
for i, line in enumerate(lines):
    if "\ufffd" in line and i > 200 and i < 360:
        if "ከባክኤንድ" in line or "ስህተት" in line or "ሰርቨር" in line or "?" in line:
            lines[i] = '          "text": "\u12e8\u130d\u1295\u1299\u1290\u1275 \u1235\u1205\u1270\u1275\u1361 \u12a8\u1263\u12ad\u12a4\u1295\u12f5 \u1230\u122d\u1268\u1229 \u130b\u122d \u1218\u120c\u1293\u1298\u1275 \u12a0\u120d\u1270\u127b\u1208\u121d\u1361".replace("\u1218\u120c\u1293\u1298\u1275", "\u1218\u130c\u1293\u1298\u1275"),\n'

open(p, "w", encoding="utf-8").write("".join(lines))
print("ALL_DONE")
