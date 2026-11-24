import re

path = r"C:\Users\eastc\east_command_hospital_ai\lib\main.dart"
with open(path, "r", encoding="utf-8", errors="replace") as f:
    text = f.read()

hospital_am = "\u121d\u1235\u122b\u1245 \u12d5\u12dd \u12f0\u1228\u1303 3 \u1206\u1352\u1273\u120d"
subtitle_am = hospital_am + " \u2014 \u12e8\u1324\u1293 \u1218\u1228\u1303\u1293 \u12ad\u120a\u1292\u12ab\u120d \u12f5\u130b\u134d"
address_lbl = "\u12a0\u12f5\u122b\u123b"
contact_lbl = "\u12e8\u1218\u130c\u1293\u129b \u12a0\u12f5\u122b\u123b\u12ce\u127d"
city_am = "\u12f5\u122c\u12f3\u12cb"
loading_am = "\u1218\u120d\u1235 \u1260\u121b\u12d8\u1263\u1260\u1225 \u120b\u12ed..."
no_ans_am = "\u1218\u120d\u1235 \u12a0\u120d\u1270\u1308\u1298\u121d\u1361"
srv_err_am = "\u1235\u1205\u1270\u1275 \u12a0\u130b\u1325\u1219\u120d\u1361 \u1230\u122d\u1268\u1229 \u12e8\u1270\u1230\u1233\u1223\u1270 \u121d\u120b\u123b \u1230\u1275\u1273\u120d\u1201"
net_err_am = "\u12e8\u130d\u1295\u1299\u1290\u1275 \u1235\u1205\u1270\u1275\u1261 \u12a0\u120d\u1270\u127b\u1208\u121d\u1361"

# Sidebar subtitle
text = re.sub(
    r"('ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል'|'[^\n']*3\s*[^\n']*')",
    f"'{hospital_am}'",
    text,
    count=1,
)

# Center subtitle
text = re.sub(
    r"('ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል\s*—\s*የጤና መረጃና ክሊኒካል ድጋፍ'|'[^\n']*3\s*[^\n']*—[^\n']*')",
    f"'{subtitle_am}'",
    text,
)

# Location / አድራሻ
text = re.sub(r"'Location / [^']*'", f"'Location / {address_lbl}'", text)

# Address line 1
text = re.sub(
    r"('[^\n']*3\s*[^\n']*\(East Command Level 3 Hospital - ECL3H\)\\n')",
    f"'{hospital_am} (East Command Level 3 Hospital - ECL3H)\\\\n'",
    text,
)

# City line
text = re.sub(
    r"('ከተማ \(City\): [^\n']*\(Dire Dawa\), Ethiopia')",
    f"'\u12a8\u1270\u121b (City): {city_am} (Dire Dawa), Ethiopia'",
    text,
)

# Contact / የመገናኛ አድራሻዎች
text = re.sub(r"'Contact / [^']*'", f"'Contact / {contact_lbl}'", text)

# Loading text
text = re.sub(r"'መልስ በማዘጋጀት ላይ\.\.\.'", f"'{loading_am}'", text)

# Fallback / error messages
text = re.sub(r'"መልስ አልተገኘም።"', f'"{no_ans_am}"', text)
text = re.sub(r'"ስህተት አጋጥሟል፡ ሰርቨሩ የተሳሳተ ምላሽ ሰጥቷል።"', f'"{srv_err_am}"', text)
text = re.sub(r'"የግንኙነት ስህተት፡ ከባክኤንድ ሰርቨር ጋር መገናኘት አልተቻለም።"', f'"{net_err_am}"', text)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("DONE")
