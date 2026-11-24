path = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(path, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

hospital_am = "\u121d\u1235\u122b\u1245 \u12d5\u12dd \u12f0\u1228\u1303 3 \u1206\u1352\u1273\u120d"

for i, line in enumerate(lines):
    if "Misrak Chora AI" in line and i + 8 < len(lines):
        for j in range(i + 1, min(i + 10, len(lines))):
            if "fontSize: 11" in lines[j]:
                for k in range(j - 1, max(i, j - 5), -1):
                    if "'" in lines[k]:
                        lines[k] = f"                        '{hospital_am}',\n"
                        break
                break

with open(path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("SIDEBAR_FIXED")
