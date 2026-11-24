p = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(p, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

val = "\u121d\u1235\u122b\u1245 \u12d5\u12dd \u12f0\u1228\u1303 3 \u1206\u1352\u1273\u120d"

for i in range(min(len(lines), 560)):
    window = "".join(lines[i : min(len(lines), i + 4)])
    if "fontSize: 11" in window and ("'" in lines[i] or "\ufffd" in lines[i]):
        lines[i] = f"                        '{val}',\n"

with open(p, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("HEADER_OK")
