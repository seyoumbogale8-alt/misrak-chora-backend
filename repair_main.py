p = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(p, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

hosp = "".join(chr(c) for c in [0x121d, 0x1235, 0x122b, 0x1245, 0x20, 0x12d5, 0x12dd, 0x20, 0x12f0, 0x1228, 0x1303, 0x20, 0x33, 0x20, 0x1206, 0x1235, 0x1352, 0x1273, 0x120d])
contact_am = "".join(chr(c) for c in [0x12e8, 0x1218, 0x130c, 0x1293, 0x129b, 0x20, 0x12a0, 0x12f5, 0x122b, 0x123b, 0x12ce, 0x127d])
conn_err = "".join(chr(c) for c in [
    0x12e8, 0x130d, 0x1295, 0x1299, 0x1290, 0x1275, 0x20,
    0x1235, 0x1205, 0x1270, 0x1275, 0x1361, 0x20,
    0x12a8, 0x1263, 0x12a5, 0x1254, 0x1295, 0x12f5, 0x20,
    0x1230, 0x122d, 0x1268, 0x1229, 0x20, 0x130b, 0x122d, 0x20,
    0x1218, 0x130c, 0x1293, 0x1298, 0x1275, 0x20,
    0x12a0, 0x120d, 0x1270, 0x1308, 0x129d, 0x1208, 0x121d, 0x1361
])

new_lines = []
skip_until_561 = False

for idx, line in enumerate(lines, start=1):
    # መስመር 220 አካባቢ ያለውን የተበላሸ "text": መስመር ማስተካከል
    if idx == 220 or ('"text":' in line and ('መጌናኘት' in line or 'መሌናኘት' in line or 'ባእቔንድ' in line or 'አልተገኝለም' in line)):
        new_lines.append(f'          "text": "{conn_err}",\n')
        continue

    # በመስመር 535-560 አካባቢ የተበላሸውን Expanded/Column/Text block በንጹሕ መተካት
    if idx == 535 and "Expanded" in line:
        new_lines.append("""                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misrak Chora AI',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '""" + hosp + """',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
""")
        skip_until_561 = True
        continue

    if skip_until_561:
        if idx <= 560:
            continue
        else:
            skip_until_561 = False

    if "Contact / " in line:
        new_lines.append(f"            'Contact / {contact_am}',\n")
        continue

    new_lines.append(line)

with open(p, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("REPAIRED_CLEANLY")
