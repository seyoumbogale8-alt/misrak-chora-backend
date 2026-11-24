import os
import sys
import re
import traceback
from flask import Flask, jsonify, request
from flask_cors import CORS

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from icd11_kb import ICD11_KB
from triage_engine import get_triage_response
from conversation_manager import *

app = Flask(__name__)
CORS(app)

IDENTITY_AM = (
    "እኔ የምስራቅ ጮራ AI እባላለሁ። በምስራቅ ዕዝ ደረጃ 3 ሆስፒታል የማገልገልዎ AI ነኝ። "
    "የተፈጠርኩትም በምስራቅ ዕዝ ደረጃ 3 ሆስፒታል የአይ ሲቲ ሙያተኛ በሆነው በአስር አለቃ ስዩም ቦጋለ ነው።"
)

IDENTITY_EN = (
    "I am Misrak Chora AI, your AI assistant at East Command Level 3 Hospital. "
    "I was created by Corporal Seyoum Bogale, an ICT specialist at East Command Level 3 Hospital."
)

HOSPITAL_INFO_AM = (
    "የምስራቅ ዕዝ ደረጃ 3 ሆስፒታል መረጃ፦\n"
    "- ስም፦ ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል\n"
    "- የስርዓቱ ስም፦ የምስራቅ ጮራ AI (ክሊኒካል ድጋፍ እና የጤና መረጃ ስርዓት)\n"
    "- ፈጣሪ፦ አስር አለቃ ስዩም ቦጋለ (የአይ ሲቲ ሙያተኛ - ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል)\n"
    "- አገልግሎት፦ የተለያዩ የጤና ሁኔታዎችንና የሕክምና ምድቦችን ክሊኒካል መረጃ እንዲሁም የሆስፒታል አጠቃላይ መረጃ ማቅረብ።\n"
    "- ማሳሰቢያ፦ ከባድ ወይም አጣዳፊ የጤና ምልክት ሲታይ ሳይዘገዩ በቀጥታ ወደ ሆስፒታል ወይም ወደ ሕክምና ባለሙያ መቅረብ ይመከራል።"
)

HOSPITAL_INFO_EN = (
    "East Command Level 3 Hospital Information:\n"
    "- System: Misrak Chora AI (Clinical Decision Support & Health Information System)\n"
    "- Creator: Corporal Seyoum Bogale (ICT Specialist, East Command Level 3 Hospital)\n"
    "- Purpose: Provides clinical guidance and health information as well as hospital details.\n"
    "- Note: For urgent or severe symptoms, please seek immediate in-person medical evaluation at the hospital."
)

GREETING_AM = (
    "ሰላም! እኔ በምስራቅ ዕዝ ደረጃ 3 ሆስፒታል የምገኝ ምስራቅ ጮራ AI ረዳት ነኝ። "
    "ዛሬ በጤናዎ ወይም በሚሰማዎት ምልክት በምን ልረዳዎ እችላለሁ?"
)

GREETING_EN = (
    "Hello! I am Misrak Chora AI, your assistant at East Command Level 3 Hospital. "
    "How can I help you with your health or symptoms today?"
)

AMHARIC_GREETINGS = {
    "ሰላም",
    "ሰላም እንዴት ነህ",
    "ሰላም እንዴት ነሽ",
    "ሰላም እንዴት ናችሁ",
    "ሰላም ነው",
    "ጤና ይስጥልኝ",
    "ታዲያስ",
    "እንዴት ነህ",
    "እንዴት ነሽ",
    "እንዴት ናችሁ",
}

ENGLISH_GREETINGS = {
    "hi",
    "hii",
    "hiii",
    "hey",
    "heyy",
    "hello",
    "selam",
    "salam",
    "good morning",
    "good afternoon",
    "good evening",
    "how are you",
}

ENGLISH_TYPO_MAP = {
    "bllod": "blood",
    "blod": "blood",
    "bloood": "blood",
    "canser": "cancer",
    "cancr": "cancer",
    "kanser": "cancer",
    "leukmia": "leukemia",
    "leukaema": "leukaemia",
    "fver": "fever",
    "fevr": "fever",
    "hedache": "headache",
    "headche": "headache",
    "diabetis": "diabetes",
    "diabtes": "diabetes",
    "astma": "asthma",
    "asma": "asthma",
    "pneumona": "pneumonia",
    "pnumonia": "pneumonia",
    "malara": "malaria",
    "tyfoid": "typhoid",
    "typus": "typhus",
    "hypertnsion": "hypertension",
    "hipertension": "hypertension",
    "symptms": "symptoms",
    "symtoms": "symptoms",
    "simptoms": "symptoms",
    "cuase": "cause",
    "cuases": "causes",
    "creted": "created",
    "creaetd": "created",
    "hosptal": "hospital",
    "hospial": "hospital",
    "syphils": "syphilis",
    "syphilllis": "syphilis",
}

DIRECT_DISEASE_GUIDES = {
    "syphilis": {
        "name_en": "Syphilis",
        "name_am": "ቂጥኝ",
        "meaning_am": (
            "ቂጥኝ (Syphilis) በዋናነት በግብረ ሥጋ ግንኙነት እንዲሁም ከእናት ወደ ፅንስ/ሕፃን ሊተላለፍ የሚችል "
            "በባክቴሪያ (Treponema pallidum) የሚከሰት ተላላፊ የጤና ሁኔታ ነው። በደረጃ (Primary፣ Secondary፣ Latent እና Tertiary) ሊያልፍ ይችላል።"
        ),
        "symptoms_am": (
            "በመጀመሪያ ደረጃ ሕመም የማይሰማው ቁስል (chancre) በብልት፣ በአፍ ወይም በፊንጥጣ አካባቢ ሊወጣ ይችላል፤ "
            "በሁለተኛ ደረጃ የቆዳ ሽፍታ (በተለይ በእጅ መዳፍና በእግር መዳፍ ሊታይ ይችላል)፣ ትኩሳት፣ የሊምፍ እጢ ማበጥ፣ የጉሮሮ ሕመምና ድካም ሊከሰት ይችላል። "
            "በዘገየ ሕክምና የነርቭ፣ የልብ ወይም የሌሎች አካላት ጉዳት ሊያስከትል ይችላል።"
        ),
        "causes_am": (
            "የሚከሰተው በ Treponema pallidum ባክቴሪያ አማካኝነት ሲሆን፣ ጥንቃቄ የጎደለው የግብረ ሥጋ ግንኙነት፣ "
            "የቁስል ወይም የሽፍታ ንክኪ፣ እንዲሁም በእርግዝና ወቅት ከእናት ወደ ፅንስ በመተላለፍ ነው።"
        ),
        "treatment_am": (
            "በሐኪም ወይም በጤና ተቋም የደም ምርመራ (እንደ VDRL/RPR/TPHA ያሉ) በማድረግ ማረጋገጥ እና በሐኪም ትዕዛዝ "
            "ተገቢ አንቲባዮቲክ (በሕክምና መመሪያ መሰረት ፔንሲሊን ወይም ተለዋጭ ሕክምና) ሙሉ በሙሉ መውሰድ ያስፈልጋል። "
            "ሕክምና እስኪጠናቀቅ የግብረ ሥጋ ግንኙነት መቆጠብ እና የቅርብ የግብረ ሥጋ አጋርም አብሮ እንዲመረመርና እንዲታከም ማድረግ ወሳኝ ነው።"
        ),
        "meaning_en": (
            "Syphilis is a bacterial infection caused by Treponema pallidum, primarily transmitted through sexual contact "
            "and potentially from mother to baby during pregnancy or childbirth."
        ),
        "symptoms_en": (
            "Painless sore(s) (chancre) on genitals, mouth, or anus in early stages; skin rash (often involving palms and soles), "
            "fever, swollen lymph nodes, sore throat, and fatigue in secondary stage."
        ),
        "causes_en": (
            "Caused by the bacterium Treponema pallidum through sexual contact with an infected sore/lesion or vertical transmission during pregnancy."
        ),
        "treatment_en": (
            "Confirm with appropriate blood testing at a health facility and complete physician-prescribed antibiotic therapy (such as penicillin as guided)."
        ),
    },
    "gonorrhoea": {
        "name_en": "Gonorrhoea",
        "name_am": "ጨብጥ",
        "meaning_am": (
            "ጨብጥ (Gonorrhoea) በ Neisseria gonorrhoeae ባክቴሪያ የሚከሰት፣ በግብረ ሥጋ ግንኙነት ወይም በወሊድ ወቅት "
            "ሊተላለፍ የሚችል የአባላዘር / የሽንትና የመራቢያ አካላት ተላላፊ ሁኔታ ነው።"
        ),
        "symptoms_am": (
            "በሽንት ወቅት ማቃጠል ወይም ሕመም፣ ከብልት ያልተለመደ ፈሳሽ መውጣት፣ የታችኛው የሆድ ወይም የዳሌ ሕመም፣ "
            "እንዲሁም በአንዳንድ ሰዎች ምልክት ሳይታይ ሊቆይ ይችላል።"
        ),
        "causes_am": (
            "በ Neisseria gonorrhoeae ባክቴሪያ ኢንፌክሽን ምክንያት በግብረ ሥጋ ንክኪ ወይም ከእናት ወደ ሕፃን በመተላለፍ ይከሰታል።"
        ),
        "treatment_am": (
            "በጤና ተቋም ምርመራ በማድረግ በሐኪም የታዘዘ አንቲባዮቲክ ሕክምና መውሰድ፣ ሕክምና እስኪጠናቀቅ የግብረ ሥጋ ግንኙነት ማቆም "
            "እና የግብረ ሥጋ አጋርን አብሮ ማሳከም ያስፈልጋል።"
        ),
        "meaning_en": "Gonorrhoea is a sexually transmitted bacterial infection caused by Neisseria gonorrhoeae.",
        "symptoms_en": "Painful or burning urination, unusual genital discharge, pelvic or lower abdominal pain, or sometimes no symptoms.",
        "causes_en": "Caused by Neisseria gonorrhoeae transmitted via sexual contact or during childbirth.",
        "treatment_en": "Seek clinical evaluation and complete prescribed antibiotics; abstain from sexual activity until cured and treat partners.",
    },
    "malaria": {
        "name_en": "Malaria",
        "name_am": "ወባ",
        "meaning_am": "ወባ በፕላዝሞዲየም (Plasmodium) ጥገኛ ተውሳክ የሚከሰትና በአኖፌለስ ትንኝ ንክሻ የሚተላለፍ የጤና ሁኔታ ነው።",
        "symptoms_am": "ከፍተኛ ትኩሳት፣ ብርድ ብርድ ማለትና መንቀጥቀጥ፣ ራስ ምታት፣ የሰውነት ድካምና የጡንቻ ሕመም፣ ማቅለሽለሽ ወይም ማስታወክ ሊታይ ይችላል።",
        "causes_am": "በኢንፌክሽን የተያዘች የአኖፌለስ ትንኝ ንክሻ አማካኝነት Plasmodium ጥገኛ ወደ ደም ውስጥ በመግባት ይከሰታል።",
        "treatment_am": "በቅርብ ጤና ተቋም ወይም ሆስፒታል በፍጥነት በመመርመር በሐኪም ትዕዛዝ የተሰጠውን የወባ መድኃኒት ሙሉ በሙሉ መውሰድና ከባድ ምልክት ሲታይ አስቸኳይ ሕክምና ማግኘት ያስፈልጋል።",
        "meaning_en": "Malaria is a mosquito-borne disease caused by Plasmodium parasites.",
        "symptoms_en": "Fever, chills and shivering, headache, body aches/fatigue, nausea or vomiting.",
        "causes_en": "Transmitted through the bite of infected Anopheles mosquitoes.",
        "treatment_en": "Prompt diagnostic testing and full course of prescribed antimalarial medication; urgent care for severe symptoms.",
    },
    "typhoid": {
        "name_en": "Typhoid Fever",
        "name_am": "ታይፎይድ",
        "meaning_am": "ታይፎይድ በ Salmonella typhi ባክቴሪያ የሚከሰትና በተበከለ ምግብ ወይም ውሃ አማካኝነት የሚተላለፍ የጤና ሁኔታ ነው።",
        "symptoms_am": "ቀጣይነት ያለው ትኩሳት፣ ራስ ምታት፣ ድካም፣ የሆድ ሕመም፣ የምግብ ፍላጎት ማጣት፣ ተቅማጥ ወይም የሆድ ድርቀት ሊታይ ይችላል።",
        "causes_am": "Salmonella typhi ባክቴሪያ ያለበት ውሃ ወይም ምግብ መውሰድ እና የንጽሕና ጉድለት።",
        "treatment_am": "የሕክምና ምርመራ በማድረግ በሐኪም የታዘዘ አንቲባዮቲክ መውሰድ፣ ንጹሕ ውሃና በቂ ፈሳሽ መጠጣት እንዲሁም የምግብና የእጅ ንጽሕናን መጠበቅ ያስፈልጋል።",
        "meaning_en": "Typhoid fever is a bacterial infection caused by Salmonella typhi spread via contaminated food or water.",
        "symptoms_en": "Sustained fever, headache, weakness, abdominal pain, loss of appetite, diarrhoea or constipation.",
        "causes_en": "Ingestion of food or water contaminated with Salmonella typhi.",
        "treatment_en": "Medical evaluation and prescribed antibiotic therapy, adequate fluids, and strict food/hand hygiene.",
    },
}

AMHARIC_KB_BRIDGE = {
    "ተላላፊ": ["infectious", "communicable", "parasitic", "viral", "bacterial"],
    "ጥገኛ": ["parasitic", "protozoal", "helminthiasis", "worm", "schistosomiasis", "filariasis", "onchocerciasis"],
    "ቫይረስ": ["viral", "virus"],
    "ኤች አይ ቪ": ["hiv", "immunodeficiency", "aids"],
    "ኤችአይቪ": ["hiv", "immunodeficiency", "aids"],
    "ኤድስ": ["hiv", "aids", "immunodeficiency"],
    "ጉንፋን": ["nasopharyngitis", "influenza", "common cold", "upper respiratory"],
    "ኮቪድ": ["covid", "coronavirus", "sars"],
    "ሄፓታይተስ": ["hepatitis", "liver", "hepatic"],
    "ኩፍኝ": ["measles"],
    "የእብድ ውሻ": ["rabies"],
    "ባክቴሪያ": ["bacterial", "bacteria"],
    "ሳንባ ነቀርሳ": ["tuberculosis", "tb", "mycobacterium"],
    "ቲቢ": ["tuberculosis", "tb"],
    "ኮሌራ": ["cholera"],
    "ታይፎይድ": ["typhoid", "salmonella", "enteric fever"],
    "ታይፈስ": ["typhus", "rickettsia", "louse", "flea"],
    "ሳምባ ምች": ["pneumonia", "lung", "respiratory"],
    "መተንፈሻ": ["respiratory", "pneumonia", "ari", "cough", "lung", "bronchitis"],
    "ማጅራት ገትር": ["meningitis"],
    "ወባ": ["malaria", "plasmodium", "mosquito"],
    "አሜባ": ["amoebiasis", "amebiasis", "entamoeba"],
    "ጃርዲያ": ["giardiasis", "giardia"],
    "ትላትሎች": ["helminthiasis", "intestinal", "worm", "ascariasis", "hookworm", "schistosomiasis"],
    "ወስፋት": ["ascariasis", "ascaris", "helminthiasis", "worm", "intestinal"],
    "መንጠቆ ትል": ["hookworm", "ancylostoma", "necator", "helminthiasis", "anaemia"],
    "ፈንገስ": ["mycosis", "fungal", "dermatophytosis", "tinea", "onychomycosis", "candidiasis"],
    "ጭርት": ["dermatophytosis", "tinea", "fungal", "skin"],
    "ሥር የሰደደ": ["chronic", "noncommunicable", "disease"],
    "ስር የሰደደ": ["chronic", "noncommunicable", "disease"],
    "የደም ግፊት": ["hypertension", "blood pressure", "cardiovascular", "stroke"],
    "ሃይፐርቴንሽን": ["hypertension"],
    "የልብ ድካም": ["heart failure", "cardiac", "myocardial", "ischaemic", "cardiovascular"],
    "የልብ": ["cardiovascular", "heart", "myocardial", "stroke", "hypertension", "pericarditis"],
    "ልቤን": ["heart", "cardiovascular", "chest", "pericarditis", "palpitations"],
    "ውጋት": ["pain", "stabbing", "chest", "heart", "pleurisy", "pericarditis"],
    "ስትሮክ": ["stroke", "cerebrovascular", "infarction", "haemorrhage"],
    "የስኳር": ["diabetes", "diabetes mellitus", "glucose", "insulin"],
    "ዲያቤቲስ": ["diabetes", "glucose", "insulin"],
    "እንቅርት": ["thyroid", "goitre", "goiter", "hypothyroidism", "hyperthyroidism"],
    "ታይሮይድ": ["thyroid", "hypothyroidism", "hyperthyroidism"],
    "ውፍረት": ["obesity", "overweight", "weight gain"],
    "ካንሰር": ["neoplasm", "cancer", "carcinoma", "malignant", "leukaemia", "leukemia", "breast", "cervix", "prostate", "lymphoma"],
    "የደም ካንሰር": ["leukaemia", "leukemia", "blood cancer"],
    "ዕጢ": ["neoplasm", "tumour", "tumor"],
    "አስም": ["asthma"],
    "ብሮንካይተስ": ["bronchitis", "copd", "pulmonary"],
    "ሳምባ መታፈን": ["copd", "pulmonary", "emphysema", "bronchitis"],
    "የምግብ መፈጨት": ["digestive", "gastrointestinal", "gastric", "intestinal", "dyspepsia"],
    "ጨጓራ": ["gastritis", "dyspepsia", "ulcer", "peptic", "stomach", "gastric"],
    "ቁስለት": ["ulcer", "peptic", "gastric", "duodenal"],
    "ጋስትራይተስ": ["gastritis"],
    "አልሰር": ["ulcer", "peptic", "gastric"],
    "ሐሞት ጠጠር": ["cholelithiasis", "gallbladder", "biliary", "calculus"],
    "የጉበት ስብ": ["steatosis", "fatty liver", "liver", "hepatic"],
    "ትርፍ አንጀት": ["appendicitis", "appendix"],
    "ኪንታሮት": ["haemorrhoids", "hemorrhoids", "haemorrhoid", "anal"],
    "ሄርኒያ": ["hernia", "inguinal hernia", "umbilical hernia", "abdominal"],
    "እጢ መውጣት": ["hernia", "prolapse", "swelling"],
    "የጣፊያ እብጠት": ["pancreatitis", "pancreas", "pancreatic"],
    "ጣፊያ": ["pancreatitis", "pancreas", "pancreatic"],
    "ሴሊያክ": ["coeliac", "celiac", "gluten"],
    "ግሉተን": ["coeliac", "celiac", "gluten"],
    "የአንጀት መታጠፍ": ["intestinal obstruction", "obstruction of intestine", "ileus", "bowel"],
    "የአንጀት መዘጋት": ["intestinal obstruction", "obstruction of intestine", "bowel"],
    "ሆድ": ["abdominal", "abdomen", "stomach", "gastric", "intestinal", "colicky", "pain"],
    "ሆዴን": ["abdominal", "abdomen", "stomach", "gastric", "intestinal", "colicky", "pain"],
    "ይቆርጠኛል": ["abdominal pain", "cramp", "colic", "gastritis", "dyspepsia", "diarrhoea", "intestinal"],
    "ያቆርጠኛል": ["abdominal pain", "cramp", "colic", "gastritis", "dyspepsia", "diarrhoea", "intestinal"],
    "እግር": ["leg", "foot", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "varicose", "oedema", "gout", "fracture"],
    "እግሬን": ["leg", "foot", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "varicose", "oedema", "gout", "fracture"],
    "እግሩን": ["leg", "foot", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "varicose", "oedema", "gout", "fracture"],
    "ስራመድ": ["walking", "gait", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "pain", "stiffness"],
    "መራመድ": ["walking", "gait", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "pain", "stiffness"],
    "ሲራመድ": ["walking", "gait", "limb", "joint", "arthritis", "arthralgia", "myalgia", "sciatica", "pain", "stiffness"],
    "ኩላሊት": ["kidney", "renal", "nephritis", "calculus", "failure", "polycystic"],
    "የኩላሊት ጠጠር": ["calculus of kidney", "urolithiasis", "renal", "kidney"],
    "ኩላሊት ስራ ማቆም": ["renal failure", "kidney failure", "renal"],
    "የሽንት ቧንቧ": ["urinary", "cystitis", "pyelonephritis", "urine", "bladder"],
    "ሽንት": ["urine", "urinary", "bladder", "renal", "dysuria"],
    "የነርቭ": ["nervous", "neurological", "epilepsy", "migraine", "parkinson", "alzheimer"],
    "የሚጥል በሽታ": ["epilepsy", "seizure", "convulsion"],
    "ማይግሬን": ["migraine", "headache"],
    "ፓርኪንሰንስ": ["parkinson", "parkinsonism"],
    "የመርሳት በሽታ": ["alzheimer", "dementia", "memory"],
    "ቁርጥማት": ["arthritis", "arthralgia", "rheumatoid", "joint"],
    "መገጣጠሚያ": ["joint", "arthritis", "arthralgia", "rheumatoid", "stiffness", "dislocation", "fracture", "gout", "chikungunya"],
    "አጥንት": ["bone", "skeletal", "osteoporosis", "fracture"],
    "አጥንት መሳሳት": ["osteoporosis", "bone", "skeletal"],
    "ዲስክ": ["intervertebral disc", "disc", "spine", "lumbar", "back"],
    "ጀርባ": ["back", "spine", "spinal", "lumbar", "dorsalgia"],
    "ጡንቻ": ["muscle", "muscular", "myalgia", "spasm"],
    "አእምሮ": ["mental", "behavioural", "psychiatric", "mood", "anxiety", "depression"],
    "ባህሪ": ["behavioural", "behavioral", "mental", "disorder", "adhd", "autism"],
    "ድብርት": ["depression", "depressive", "mood"],
    "ባይፖላር": ["bipolar", "mood"],
    "ጭንቀት": ["anxiety", "stress", "panic", "phobia", "obsessive-compulsive"],
    "ድንጋጤ": ["panic", "anxiety"],
    "ስኪዞፈሪንያ": ["schizophrenia", "psychotic"],
    "ሱሰኝነት": ["substance", "alcohol", "dependence", "use disorder"],
    "እንቅልፍ": ["sleep", "insomnia", "somnolence", "sleep apnoea", "sleep apnea", "narcolepsy", "trypanosomiasis"],
    "ዘር": ["hereditary", "genetic", "congenital", "familial"],
    "ሲክል ሴል": ["sickle", "sickle-cell", "anaemia", "anemia"],
    "ሄሞፊሊያ": ["haemophilia", "hemophilia", "coagulation", "bleeding"],
    "ዳውን": ["down syndrome", "trisomy", "chromosomal"],
    "ራስን": ["autoimmune", "immune", "lupus", "rheumatoid"],
    "ሉፐስ": ["lupus", "systemic lupus erythematosus", "autoimmune"],
    "ሩማቶይድ": ["rheumatoid", "arthritis", "autoimmune"],
    "ንጥረ-ምግብ": ["nutritional", "malnutrition", "deficiency", "vitamin", "protein", "stunting", "wasting"],
    "እጥረት": ["deficiency", "malnutrition", "insufficiency"],
    "ደም ማነስ": ["anaemia", "anemia", "iron deficiency", "hookworm"],
    "አኒሚያ": ["anaemia", "anemia"],
    "ቫይታሚን ዲ": ["vitamin d", "rickets", "osteomalacia"],
    "ሪኬትስ": ["rickets", "vitamin d"],
    "ፕሮቲን": ["protein", "malnutrition", "kwashiorkor"],
    "ክዋሺዮርኮር": ["kwashiorkor", "malnutrition", "protein"],
    "አለርጂ": ["allergy", "allergic", "hypersensitivity", "anaphylaxis"],
    "መመረዝ": ["poisoning", "toxic", "intoxication", "foodborne", "sepsis"],
    "ኬሚካል": ["chemical", "toxic", "poisoning", "exposure"],
    "ቆዳ": ["skin", "cutaneous", "dermatitis", "rash", "pruritus"],
    "ኤክማ": ["eczema", "dermatitis", "atopic"],
    "ሶሪያሲስ": ["psoriasis", "psoriatic"],
    "ብጉር": ["acne", "follicular", "sebaceous"],
    "ለምጽ": ["vitiligo", "melanin", "depigmentation", "hypopigmentation"],
    "አልማዝ ባለጭራ": ["herpes zoster", "zoster", "shingles", "varicella"],
    "ሮዛሺያ": ["rosacea", "facial erythema", "flushing", "telangiectasia"],
    "አሎፔሺያ": ["alopecia areata", "alopecia", "hair loss", "hair"],
    "የጥፍር ፈንገስ": ["onychomycosis", "tinea unguium", "nail", "fungal"],
    "ጥፍር": ["nail", "onychomycosis", "ungual", "fungal"],
    "ፀጉር": ["hair", "alopecia", "scalp", "follicle"],
    "እከክ": ["scabies", "mite", "sarcoptes", "pruritus", "itching"],
    "ስጋ ደዌ": ["leprosy", "hansen", "mycobacterium leprae", "peripheral nerve"],
    "ዓይን": ["eye", "ocular", "vision", "visual", "lens", "cornea", "conjunctiva"],
    "ሞራ ግርዶሽ": ["cataract", "lens", "opacity"],
    "ግላኮማ": ["glaucoma", "intraocular", "optic nerve"],
    "ትራኮማ": ["trachoma", "chlamydia", "conjunctiva", "cornea", "blindness"],
    "የዓይን መቅላት": ["conjunctivitis", "conjunctiva", "eye", "redness"],
    "ጆሮ": ["ear", "otic", "vestibular", "hearing", "otitis", "tympanic", "mumps", "tinnitus", "meniere"],
    "አፍንጫ": ["nasal", "sinus", "rhinitis", "sinusitis"],
    "ጉሮሮ": ["throat", "pharyngeal", "laryngeal", "tonsillitis"],
    "ሳይነስ": ["sinusitis", "sinus", "nasal"],
    "ቶንሲል": ["tonsillitis", "tonsil", "pharyngeal"],
    "መካከለኛው ጆሮ": ["otitis media", "otitis", "ear"],
    "ቬርቲጎ": ["vertigo", "vestibular", "dizziness", "meniere"],
    "ጥርስ": ["tooth", "dental", "caries", "gingival", "oral"],
    "መቦርቦር": ["caries", "dental caries", "tooth"],
    "ድድ": ["gingivitis", "periodontitis", "gingival", "gum", "oral"],
    "የአፍ ውስጥ ቁስለት": ["stomatitis", "aphthous", "oral", "ulcer", "mucosa"],
    "ማህጸን": ["uterine", "uterus", "fibroid", "leiomyoma", "endometriosis"],
    "የማህጸን እጢ": ["leiomyoma of uterus", "fibroid", "uterine", "uterus"],
    "ፖሊሲስቲክ": ["polycystic", "ovarian", "pcos", "ovary"],
    "ኢንዶሜትሪዮሲስ": ["endometriosis", "endometrium", "uterine"],
    "ፕሮስቴት": ["prostate", "hyperplasia of prostate", "prostatic"],
    "የአባላዘር": ["sexually transmitted", "syphilis", "gonorrhoea", "gonorrhea", "chlamydia"],
    "ቂጥኝ": ["syphilis", "treponemal"],
    "ጨብጥ": ["gonorrhoea", "gonorrhea", "neisseria"],
    "ክላሚዲያ": ["chlamydia", "chlamydial"],
    "ፕሪ-ኤክላምፕሲያ": ["pre-eclampsia", "preeclampsia", "gestational hypertension", "pregnancy"],
    "ፕሪኤክላምፕሲያ": ["pre-eclampsia", "preeclampsia", "gestational hypertension", "pregnancy"],
    "የወሊድ": ["postpartum", "puerperium", "haemorrhage", "bleeding", "childbirth", "pregnancy"],
    "ጆሮ ማጅራት ገትር": ["mumps", "parotitis", "parotid", "salivary"],
    "ጆሮ ደግፍ": ["mumps", "parotitis", "parotid", "salivary"],
    "ትክትክ": ["whooping cough", "pertussis", "bordetella", "cough"],
    "ጉድፍ": ["chickenpox", "varicella", "rash", "vesicular"],
    "የልጅነት ልምሻ": ["poliomyelitis", "polio", "paralysis", "neurological"],
    "ፖሊዮ": ["poliomyelitis", "polio", "paralysis"],
    "የህጻናት ቢጫ ወባ": ["neonatal jaundice", "jaundice", "icterus", "bilirubin", "neonatal"],
    "ቢሊሩቢን": ["bilirubin", "jaundice", "icterus"],
    "ዴንጊ": ["dengue", "mosquito", "arbovirus", "haemorrhagic"],
    "ቢጫ ወባ": ["yellow fever", "mosquito", "flavivirus", "jaundice"],
    "ቁንጭር": ["leishmaniasis", "sandfly", "leishmania"],
    "ሊሽመኒያሲስ": ["leishmaniasis", "sandfly", "leishmania"],
    "ብሩሴሎሲስ": ["brucellosis", "brucella", "zoonotic"],
    "አንትራክስ": ["anthrax", "bacillus anthracis", "zoonotic"],
    "ቁርባ": ["anthrax", "bacillus anthracis", "skin", "ulcer"],
    "ቢልሃርዚያ": ["schistosomiasis", "bilharziasis", "schistosoma", "trematode"],
    "የዝሆኔ በሽታ": ["lymphatic filariasis", "filariasis", "elephantiasis", "lymphoedema"],
    "ዝሆኔ": ["filariasis", "elephantiasis", "lymphatic", "oedema"],
    "የወንዝ ዓይነ ስውርነት": ["onchocerciasis", "onchocerca", "blackfly", "blindness"],
    "የመኝታ በሽታ": ["trypanosomiasis", "african trypanosomiasis", "tsetse", "sleeping sickness"],
    "ቺኩንጉንያ": ["chikungunya", "alphavirus", "mosquito", "arthralgia"],
    "ፖዶኮኒዮሲስ": ["podoconiosis", "mossy foot", "lymphoedema", "foot", "swelling"],
    "የዓይን መድረቅ": ["dry eye", "keratoconjunctivitis sicca", "tear", "lacrimal"],
    "አስቲግማቲዝም": ["astigmatism", "refractive", "cornea", "vision"],
    "ቲኒተስ": ["tinnitus", "ringing in ear", "ear noise", "auditory"],
    "የጆሮ መጮህ": ["tinnitus", "ear noise", "auditory", "ear"],
    "ሜኒየርስ": ["meniere", "ménière", "endolymphatic", "vertigo", "tinnitus"],
    "የአፍ ፈንገስ": ["oral candidiasis", "candidiasis of mouth", "thrush", "candida", "oral"],
    "ኦቲዝም": ["autism", "autism spectrum", "asd", "neurodevelopmental"],
    "ኤዲኤችዲ": ["adhd", "attention-deficit", "hyperactivity", "attention deficit"],
    "ኦብሰሲቭ": ["obsessive-compulsive", "ocd", "obsessive", "compulsive"],
    "የአመጋገብ መዛባት": ["eating disorder", "anorexia nervosa", "bulimia nervosa", "anorexia", "bulimia"],
    "ፎቢያ": ["phobia", "phobic", "anxiety", "fear"],
    "ኢንተርስቲሻል": ["interstitial cystitis", "bladder pain syndrome", "cystitis", "bladder"],
    "የኩላሊት ሲስት": ["polycystic kidney", "kidney cyst", "renal cyst", "kidney"],
    "ቫሪኮሴል": ["varicocele", "scrotal", "spermatic", "testicular", "vein"],
    "ሲስቲክ ፋይብሮሲስ": ["cystic fibrosis", "mucoviscidosis", "lung", "pancreas"],
    "ማስኩላር ዲስትሮፊ": ["muscular dystrophy", "dystrophy", "muscle", "hereditary"],
    "ማርፋን": ["marfan syndrome", "marfan", "connective tissue", "fibrillin"],
    "አልቢኒዝም": ["albinism", "oculocutaneous albinism", "melanin", "hypopigmentation"],
    "ሰፕሲስ": ["sepsis", "septicaemia", "septicemia", "infection"],
    "የደም መመረዝ": ["sepsis", "septicaemia", "bacteraemia", "poisoning"],
    "ትሮምቦሳይቶፔኒያ": ["thrombocytopenia", "platelets", "platelet", "bleeding"],
    "ሳርኮይዶሲስ": ["sarcoidosis", "granuloma", "lung", "lymph node"],
    "መልቲፕል ስክሌሮሲስ": ["multiple sclerosis", "demyelinating", "nervous"],
    "ቤልስ ፓልሲ": ["bell palsy", "bell's palsy", "facial nerve", "facial"],
    "ሴሬብራል ፓልሲ": ["cerebral palsy", "palsy", "spastic", "brain"],
    "ናርኮሌፕሲ": ["narcolepsy", "sleep", "somnolence"],
    "ኩሺንግ": ["cushing syndrome", "cushing's syndrome", "cortisol", "hypercortisolism"],
    "አዲሰንስ": ["addison disease", "addison's disease", "adrenal insufficiency", "adrenal"],
    "አክሮሜጋሊ": ["acromegaly", "growth hormone", "pituitary"],
    "ሆርሞን": ["endocrine", "hormone", "cortisol", "adrenal", "thyroid", "pituitary"],
    "ቫሪኮስ ቬይን": ["varicose veins", "varicose", "vein", "venous"],
    "አኒዩሪዝም": ["aneurysm", "arterial", "aorta", "vascular"],
    "ፔሪካርዳይተስ": ["pericarditis", "pericardium", "heart", "chest"],
    "ሪህ": ["gout", "uric acid", "arthritis", "joint"],
    "ፋይብሮማያልጂያ": ["fibromyalgia", "myalgia", "muscle", "chronic pain"],
    "ካርፓል ታነል": ["carpal tunnel syndrome", "carpal tunnel", "median nerve", "wrist"],
    "ስኮሊዎሲስ": ["scoliosis", "spine", "spinal curvature", "back"],
    "ሲሊኮሲስ": ["silicosis", "silica", "pneumoconiosis", "lung"],
    "ሃይፖተርሚያ": ["hypothermia", "cold", "temperature"],
    "የከፍታ ህመም": ["altitude sickness", "high altitude", "hypoxia", "mountain"],
    "የእንቅልፍ ማጣት": ["insomnia", "sleep"],
    "ትንፋሽ መቆራረጥ": ["sleep apnoea", "sleep apnea", "apnoea", "apnea", "breathing"],
    "የእንቅልፍ መዛባት": ["sleep disorder", "insomnia", "apnoea", "apnea", "narcolepsy"],
    "የእንቅስቃሴ ህመም": ["motion sickness", "kinetosis", "nausea", "vertigo"],
    "የሙቀት መመታት": ["heatstroke", "heat stroke", "hyperthermia", "heat"],
    "ሙቀት": ["heatstroke", "heat", "hyperthermia", "fever"],
    "መውለቅ": ["dislocation", "luxation", "subluxation", "joint"],
    "ስብራት": ["fracture", "bone", "trauma", "injury"],
    "መቀንጨር": ["stunting", "malnutrition", "growth retardation", "child"],
    "መክሳት": ["wasting", "malnutrition", "emaciation", "weight loss"],
    "ደም": ["blood", "thrombosis", "anaemia", "anemia", "haemorrhage", "sepsis", "thrombocytopenia"],
    "ደም መርጋት": ["thrombosis", "deep vein thrombosis", "venous thrombosis", "embolism"],
    "ታላሴሚያ": ["thalassaemia", "thalassemia", "haemoglobin", "anaemia"],
    "ሊምፍ": ["lymphoma", "lymph", "lymphatic", "node", "filariasis", "sarcoidosis"],
    "ሊምፎማ": ["lymphoma", "hodgkin", "non-hodgkin", "lymph"],
    "ትንኝ": ["mosquito", "malaria", "dengue", "yellow fever", "filariasis", "chikungunya"],
    "ዝንብ": ["sandfly", "fly", "leishmaniasis", "blackfly", "tsetse"],
    "እንስሳት": ["zoonotic", "rabies", "brucellosis", "anthrax"],
    "ሕፃን": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ህፃን": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ህጻን": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ሕፃናት": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ህፃናት": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ህጻናት": ["infant", "paediatric", "pediatric", "neonatal", "child"],
    "ጨቅላ": ["neonate", "neonatal", "infant", "perinatal"],
    "ሳል": ["cough", "tussis", "respiratory", "pertussis"],
    "ደረቅ ሳል": ["cough", "tussis", "respiratory", "pleurisy", "pericarditis"],
    "ያስለኛል": ["cough", "tussis", "respiratory", "bronchitis", "asthma", "pneumonia"],
    "ይሰማኛል": ["pain", "tightness", "breathing", "symptom", "disorder"],
    "ወጥቶ": ["swelling", "tightness", "oedema", "chest", "respiratory"],
    "ደረቴ": ["chest", "respiratory", "breathing", "bronchitis", "asthma", "pneumonia", "heart"],
    "ደረት": ["chest", "respiratory", "breathing", "bronchitis", "asthma", "pneumonia", "heart"],
    "ትኩሳት": ["fever", "pyrexia", "febrile", "dengue", "yellow fever", "chikungunya", "sepsis", "typhus", "typhoid", "malaria"],
    "ሕመም": ["pain", "ache", "disorder"],
    "ህመም": ["pain", "ache", "disorder"],
    "ያመኛል": ["pain", "ache", "myalgia", "arthralgia", "headache"],
    "ተቅማጥ": ["diarrhoea", "diarrhea", "stool", "cholera"],
    "ማስታወክ": ["vomiting", "vomit", "emesis"],
    "ማቅለሽለሽ": ["nausea", "motion sickness", "altitude"],
    "ራስ ምታት": ["headache", "cephalgia", "migraine", "dengue", "altitude"],
    "ራሴን": ["headache", "migraine", "dizziness", "vertigo", "stress", "anxiety"],
    "ድካም": ["fatigue", "weakness", "malaise", "fibromyalgia", "addison"],
    "ማዞር": ["vertigo", "dizziness", "motion sickness", "vestibular", "altitude", "meniere"],
    "ሽፍታ": ["rash", "eruption", "zoster", "skin", "chickenpox", "dengue", "scabies"],
    "ማሳከክ": ["pruritus", "itching", "eczema", "skin", "haemorrhoids", "scabies", "onchocerciasis"],
    "ማበጥ": ["oedema", "edema", "swelling", "mumps", "cushing", "varicose", "gout", "hernia", "filariasis", "varicocele", "podoconiosis"],
    "መድማት": ["haemorrhage", "bleeding", "haemorrhoids", "thrombocytopenia", "postpartum"],
    "ትንፋሽ": ["breathing", "dyspnoea", "breath", "respiratory", "altitude"],
}

SYMPTOM_AMHARIC_MAP = {
    "cough": "ደረቅ ወይም ተደጋጋሚ ሳል",
    "tussis": "ሳል",
    "pertussis": "ከባድ እና ተከታታይ ሳል",
    "fever": "ትኩሳት",
    "pyrexia": "ትኩሳት",
    "pain": "ውጋት ወይም ሕመም",
    "ache": "ሕመም",
    "dyspnoea": "የትንፋሽ ማጠር",
    "breathing": "የአተነፋፈስ ችግር",
    "vomiting": "ማስታወክ",
    "nausea": "ማቅለሽለሽ",
    "diarrhoea": "ተቅማጥ",
    "diarrhea": "ተቅማጥ",
    "constipation": "ድርቀት",
    "dizziness": "ማዞር",
    "vertigo": "ማዞር ወይም ሚዛን የመሳት ስሜት",
    "fatigue": "ድካም",
    "weakness": "ድክመት ወይም የሰውነት መላሸቅ",
    "rash": "የቆዳ ሽፍታ",
    "pruritus": "ማሳከክ",
    "itching": "ማሳከክ",
    "swelling": "ማበጥ ወይም እብጠት",
    "oedema": "ማበጥ ወይም እብጠት",
    "edema": "ማበጥ ወይም እብጠት",
    "bleeding": "መድማት ወይም ደም መፍሰስ",
    "haemorrhage": "መድማት ወይም ደም መፍሰስ",
    "headache": "ራስ ምታት",
    "stiffness": "መደርቀቅ ወይም የእንቅስቃሴ መቸገር",
    "myalgia": "የጡንቻ ወይም የመገጣጠሚያ ሕመም",
    "arthralgia": "የመገጣጠሚያ ሕመም",
    "anaemia": "የደም ማነስ",
    "anemia": "የደም ማነስ",
}

DISEASE_AMHARIC_MAP = {
    "hiv": "ኤች አይ ቪ / ኤድስ",
    "nasopharyngitis": "ጉንፋን",
    "common cold": "ጉንፋን",
    "influenza": "ኢንፍሉዌንዛ / ጉንፋን",
    "covid": "ኮቪድ-19",
    "hepatitis": "ሄፓታይተስ / የጉበት በሽታ",
    "tuberculosis": "ሳንባ ነቀርሳ (ቲቢ)",
    "cholera": "ኮሌራ",
    "typhoid": "ታይፎይድ",
    "typhus": "ታይፈስ",
    "pneumonia": "የሳምባ ምች / የመተንፈሻ አካል ኢንፌክሽን",
    "ari": "የላይኛውና የታችኛው የመተንፈሻ አካል ኢንፌክሽን",
    "meningitis": "የማጅራት ገትር በሽታ",
    "malaria": "ወባ",
    "diarrhoea": "የተቅማጥ በሽታ",
    "diarrhea": "የተቅማጥ በሽታ",
    "amoebiasis": "አሜባ",
    "giardiasis": "ጃርዲያ",
    "ascariasis": "ወስፋት",
    "hookworm": "መንጠቆ ትል",
    "helminthiasis": "የአንጀት ጥገኛ ትላትሎች",
    "dermatophytosis": "የቆዳ ፈንገስ (ጭርት)",
    "mycosis": "የፈንገስ ህመም",
    "dengue": "ዴንጊ ትኩሳት",
    "yellow fever": "ቢጫ ወባ",
    "schistosomiasis": "ቢልሃርዚያ",
    "filariasis": "የዝሆኔ በሽታ",
    "chikungunya": "ቺኩንጉንያ",
    "hypertension": "የደም ግፊት",
    "cardiovascular": "የልብና የደም ስር ህመም",
    "heart failure": "የልብ ድካም",
    "arrhythmia": "የልብ ምት መዛባት",
    "stroke": "ስትሮክ",
    "diabetes": "የስኳር ህመም",
    "thyroid": "የታይሮይድ / የእንቅርት ህመም",
    "goitre": "እንቅርት",
    "goiter": "እንቅርት",
    "obesity": "ከመጠን ያለፈ ውፍረት",
    "cancer": "ካንሰር",
    "neoplasm": "የካንሰር / የዕጢ ሁኔታ",
    "leukaemia": "የደም ካንሰር",
    "leukemia": "የደም ካንሰር",
    "asthma": "አስም",
    "copd": "ሥር የሰደደ የሳንባ መታፈን",
    "bronchitis": "ብሮንካይተስ",
    "pericarditis": "የልብ ሽፋን መቆጣት",
    "gastritis": "የጨጓራ ህመም (ጋስትራይተስ)",
    "dyspepsia": "የምግብ አለመፈጨት / የጨጓራ ህመም",
    "ulcer": "የጨጓራ ቁስለት",
    "cholelithiasis": "የሐሞት ጠጠር",
    "appendicitis": "የትርፍ አንጀት እብጠት",
    "haemorrhoids": "ኪንታሮት",
    "hemorrhoids": "ኪንታሮት",
    "hernia": "ሄርኒያ",
    "pancreatitis": "የጣፊያ እብጠት",
    "kidney": "የኩላሊት ህመም",
    "renal": "የኩላሊት ህመም",
    "cystitis": "የሽንት ቧንቧ ኢንፌክሽን",
    "syphilis": "ቂጥኝ",
    "gonorrhoea": "ጨብጥ",
    "gonorrhea": "ጨብጥ",
    "chlamydia": "ክላሚዲያ",
    "epilepsy": "የሚጥል በሽታ",
    "migraine": "ማይግሬን (ከባድ ራስ ምታት)",
    "depression": "ድብርት",
    "anxiety": "የጭንቀት ህመም",
    "insomnia": "እንቅልፍ ማጣት",
    "eczema": "ኤክማ",
    "psoriasis": "ሶሪያሲስ",
    "acne": "ብጉር",
    "scabies": "እከክ",
    "sinusitis": "ሳይነስ",
    "tonsillitis": "ቶንሲል",
    "arthritis": "ቁርጥማት / የመገጣጠሚያ ህመም",
    "anaemia": "የደም ማነስ",
    "anemia": "የደም ማነስ",
    "malnutrition": "የንጥረ-ምግብ እጥረት",
    "allergy": "አለርጂ",
}

COMMON_TERMS = {
    "cough",
    "fever",
    "pain",
    "headache",
    "asthma",
    "bronchitis",
    "pneumonia",
    "malaria",
    "typhoid",
    "typhus",
    "gastritis",
    "dyspepsia",
    "ulcer",
    "hypertension",
    "diabetes",
    "anaemia",
    "arthritis",
    "infection",
    "influenza",
    "sinusitis",
    "depression",
    "anxiety",
    "epilepsy",
    "migraine",
    "allergy",
    "eczema",
    "psoriasis",
    "acne",
    "tonsillitis",
    "gout",
    "scabies",
    "abdominal",
    "joint",
    "arthralgia",
    "myalgia",
    "walking",
    "gait",
    "varicose",
    "stiffness",
    "leukaemia",
    "leukemia",
    "cancer",
    "blood",
    "syphilis",
    "gonorrhoea",
    "pericarditis",
}

RARE_TERMS = {
    "syndrome",
    "mers",
    "sars",
    "ebola",
    "marburg",
    "plague",
    "anthrax",
    "rabies",
    "leprosy",
    "prion",
    "congenital",
    "hereditary",
}

FILLER_WORDS = {
    "what",
    "is",
    "are",
    "the",
    "a",
    "an",
    "of",
    "for",
    "to",
    "in",
    "on",
    "about",
    "define",
    "meaning",
    "tell",
    "me",
    "show",
    "find",
    "this",
    "it",
    "do",
    "i",
    "have",
    "feel",
    "my",
    "ምንድን",
    "ነው",
    "ናቸው",
    "ስለ",
    "የ",
    "ወይም",
    "እና",
    "ምን",
    "ይሄ",
    "ይህ",
    "በጣም",
    "እኔን",
    "እኔ",
    "የዚህ",
    "የዚያ",
    "ምልክት",
    "ምልክቶች",
    "አለኝ",
    "ሊሆን",
    "ይችላል",
    "አለብኝ",
}

PREPARED_KB = []
for _entry in ICD11_KB:
    _name = str(_entry.get("name", "")).strip()
    _code = str(_entry.get("code", "")).strip()
    _chapter = str(_entry.get("chapter", "")).strip()
    _definition = str(_entry.get("definition", "")).strip()
    _synonyms = str(_entry.get("synonyms", "")).strip()
    _sheet = str(_entry.get("sheet", "")).strip()
    _extra = str(_entry.get("extra", "")).strip()
    PREPARED_KB.append(
        {
            "sheet": _sheet,
            "code": _code,
            "name": _name,
            "chapter": _chapter,
            "definition": _definition,
            "synonyms": _synonyms,
            "extra": _extra,
            "code_l": _code.lower(),
            "name_l": _name.lower(),
            "syn_l": _synonyms.lower(),
            "def_l": _definition.lower(),
            "chap_l": _chapter.lower(),
            "extra_l": _extra.lower(),
        }
    )


def clean_plain_text(text: str) -> str:
    return re.sub(r"[*`]+", "", text or "").strip()


def detect_language(text: str) -> str:
    return "am" if re.search(r"[\u1200-\u137f]", text or "") else "en"


def correct_english_typos(text: str) -> str:
    def _replace_token(match: re.Match) -> str:
        tok = match.group(0)
        low = tok.lower()
        if low in ENGLISH_TYPO_MAP:
            fixed = ENGLISH_TYPO_MAP[low]
            return fixed.capitalize() if tok[0].isupper() else fixed
        return tok

    return re.sub(r"[A-Za-z]+", _replace_token, text or "")


def normalize_query(query: str, lang: str) -> str:
    cleaned = clean_plain_text(query)
    return correct_english_typos(cleaned) if lang == "en" else cleaned


def _normalize_text(text: str) -> str:
    cleaned = re.sub(r"[^\w\s\u1200-\u137f]", "", (text or "").lower()).strip()
    return re.sub(r"\s+", " ", cleaned)


def get_greeting_response(query: str, lang: str):
    norm = _normalize_text(query)
    if norm in AMHARIC_GREETINGS:
        return GREETING_AM
    if norm in ENGLISH_GREETINGS:
        return GREETING_EN
    return None


def looks_like_typo_or_unclear(query: str, lang: str) -> bool:
    cleaned = clean_plain_text(query).strip()
    if len(cleaned) <= 1:
        return True
    tokens = re.findall(r"[a-z0-9\u1200-\u137f]+", cleaned.lower())
    if not tokens:
        return True
    for tok in tokens:
        if len(tok) >= 4 and len(set(tok)) == 1:
            return True
    return False


def build_clarification_message(query: str, lang: str) -> str:
    clean_q = clean_plain_text(query)
    if lang == "en":
        return (
            f"I didn't quite catch what you meant by '{clean_q}'. "
            "Could you describe your symptoms or health question a bit more clearly?"
        )
    return (
        f"'{clean_q}' የሚለው በትክክል አልገባኝም። "
        "እባክዎ የሚሰማዎትን ምልክት ወይም የጤና ጥያቄ ትንሽ ግልጽ አድርገው ይንገሩኝ።"
    )


def is_identity_query(q_lower: str) -> bool:
    am_patterns = [
        "አንተ ማነህ",
        "አንቺ ማን ነሽ",
        "ማነህ",
        "ማን ነህ",
        "ማን ነሽ",
        "ስምህ ማነው",
        "ማን ፈጠረህ",
        "ማን ሰራህ",
        "ምስራቅ ጮራ",
    ]
    en_patterns = [
        "who are you",
        "what is your name",
        "who created you",
        "who made you",
        "who built you",
    ]
    return any(p in q_lower for p in am_patterns + en_patterns)


def is_hospital_info_query(q_lower: str) -> bool:
    hospital_keys = [
        "ሆስፒታል",
        "ምስራቅ ዕዝ",
        "ምስራቅ እዝ",
        "ደረጃ 3",
        "ደረጃ ሶስት",
        "hospital",
        "east command",
        "level 3",
    ]
    return any(k in q_lower for k in hospital_keys)


def find_direct_disease_guide(query: str):
    q_l = (query or "").lower()
    if "ቂጥኝ" in q_l or "syphilis" in q_l:
        return DIRECT_DISEASE_GUIDES.get("syphilis")
    if "ጨብጥ" in q_l or "gonorrhoea" in q_l or "gonorrhea" in q_l:
        return DIRECT_DISEASE_GUIDES.get("gonorrhoea")
    if "ወባ" in q_l or "malaria" in q_l:
        return DIRECT_DISEASE_GUIDES.get("malaria")
    if "ታይፎይድ" in q_l or "typhoid" in q_l:
        return DIRECT_DISEASE_GUIDES.get("typhoid")
    return None


def translate_disease_title(
    name: str, code: str = "", include_code: bool = False, lang: str = "am"
) -> str:
    n_l = name.strip().lower()
    if lang == "en":
        base_title = name.strip() or "Health Condition"
        return f"{base_title} (Code: {code})" if (include_code and code) else base_title
    base_title = "የጤና ሁኔታ"
    for key, am_title in DISEASE_AMHARIC_MAP.items():
        if key in n_l:
            base_title = am_title
            break
    return f"{base_title} (ኮድ: {code})" if (include_code and code) else base_title


def detect_intent(q_lower: str) -> str:
    if any(k in q_lower for k in ["ኮድ", "code", "icd-11", "icd11"]):
        return "code"
    if any(k in q_lower for k in ["መንስኤ", "ምክንያት", "cause", "causes", "why"]):
        return "cause"
    if any(
        k in q_lower
        for k in [
            "መፍትሄ",
            "ምን ማድረግ",
            "ምን ላድርግ",
            "ምርመራ",
            "solution",
            "what to do",
            "what should i do",
        ]
    ):
        return "action"
    if any(
        k in q_lower
        for k in [
            "ምልክት",
            "ምልክቶች",
            "ሳል",
            "ደረቅ ሳል",
            "ያስለኛል",
            "ትኩሳት",
            "ራስ ምታት",
            "ያመኛል",
            "ይቆርጠኛል",
            "ያቆርጠኛል",
            "ይሰማኛል",
            "ውጋት",
            "ልቤን",
            "ወጥቶ",
            "ደረቴ",
            "አለኝ",
            "አለብኝ",
            "symptom",
            "symptoms",
        ]
    ):
        return "symptom"
    return "info"


def _extract_user_history(history: list) -> list:
    user_prev = []
    if isinstance(history, list):
        for item in history[-8:]:
            if isinstance(item, dict):
                sender = str(item.get("sender", "")).strip().lower()
                txt = str(item.get("text", "")).strip()
                if sender == "user" and txt:
                    user_prev.append(txt)
    return user_prev


def build_contextual_search_query(raw_query: str, history: list) -> str:
    user_prev = _extract_user_history(history)
    if not user_prev:
        return raw_query
    prior_items = user_prev[:-1] if user_prev[-1] == raw_query else user_prev
    if not prior_items:
        return raw_query
    return f"{' '.join(prior_items[-3:])} {raw_query}".strip()


def extract_terms(query: str):
    q_lower = (query or "").strip().lower()
    terms = []
    for am_key, en_list in AMHARIC_KB_BRIDGE.items():
        if am_key in q_lower:
            for item in en_list:
                for part in item.lower().split():
                    if len(part) >= 2 and part not in terms:
                        terms.append(part)
    for tok in re.findall(r"[a-z0-9\u1200-\u137f]+", q_lower):
        if tok not in FILLER_WORDS and len(tok) >= 2 and tok not in terms:
            terms.append(tok)
    return q_lower, terms


def search_all_kb(query: str, lang: str = "am"):
    q_lower, terms = extract_terms(query)
    if not terms:
        return [], []
    scored = []
    for item in PREPARED_KB:
        score = 0
        if q_lower == item["code_l"]:
            score += 120
        elif q_lower in item["code_l"] and len(q_lower) >= 2:
            score += 90
        for t in terms:
            if t == item["code_l"]:
                score += 80
            elif f" {t} " in f" {item['name_l']} ":
                score += 50
            elif t in item["name_l"]:
                score += 32
            elif t in item["syn_l"]:
                score += 22
            elif f" {t} " in f" {item['def_l']} ":
                score += 14
            elif t in item["def_l"]:
                score += 8
            elif t in item["chap_l"] or t in item["extra_l"]:
                score += 4
        if score > 0:
            if any(c in item["name_l"] for c in COMMON_TERMS):
                score += 18
            if any(r in item["name_l"] for r in RARE_TERMS):
                score -= 12
            scored.append((score, item))
    scored.sort(key=lambda x: x[0], reverse=True)
    unique_rows = []
    seen_titles = set()
    for _, row in scored:
        title_key = translate_disease_title(
            row["name"], row["code"], include_code=False, lang=lang
        ).lower()
        if title_key not in seen_titles:
            seen_titles.add(title_key)
            unique_rows.append(row)
        if len(unique_rows) >= 15:
            break
    return unique_rows, terms


def _collect_symptoms_am(matches: list, q_l: str) -> list:
    found = []
    for am_kw, am_label in [
        ("ልቤን", "በልብ ወይም በደረት አካባቢ ውጋት"),
        ("ውጋት", "ውጋት ወይም ሕመም"),
        ("ደረቅ ሳል", "ደረቅ ሳል"),
        ("ሳል", "ሳል"),
        ("ያስለኛል", "ኃይለኛ ወይም ተደጋጋሚ ሳል"),
        ("ትንፋሽ", "የትንፋሽ ማጠር"),
        ("ትኩሳት", "ትኩሳት"),
        ("ራስ ምታት", "ራስ ምታት"),
        ("ማዞር", "ማዞር"),
        ("ድካም", "ድካም ወይም የሰውነት መላሸቅ"),
        ("ሆድ", "የሆድ ሕመም ወይም ቁርጠት"),
        ("ተቅማጥ", "ተቅማጥ"),
        ("ማስታወክ", "ማስታወክ"),
    ]:
        if am_kw in q_l and am_label not in found:
            found.append(am_label)
    for m in matches[:4]:
        blob = f"{m.get('name', '')} {m.get('synonyms', '')} {m.get('definition', '')}".lower()
        for en_kw, am_label in SYMPTOM_AMHARIC_MAP.items():
            if en_kw in blob and am_label not in found:
                found.append(am_label)
            if len(found) >= 6:
                break
        if len(found) >= 6:
            break
    return found[:6]


def _collect_symptoms_en(matches: list, q_l: str) -> list:
    found = []
    for m in matches[:4]:
        blob = f"{m.get('name', '')} {m.get('synonyms', '')} {m.get('definition', '')}".lower()
        for kw in (
            "fever",
            "headache",
            "cough",
            "shortness of breath",
            "vomiting",
            "nausea",
            "diarrhoea",
            "dizziness",
            "fatigue",
            "weakness",
            "rash",
            "pain",
        ):
            if kw in blob and kw not in found:
                found.append(kw)
    return found[:6]


def _build_conversational_amharic_guidance(
    clean_q: str, comb_l: str, history: list, matches: list, titles_am: list, syms_am: list
) -> str:
    q_norm = _normalize_text(clean_q)
    user_prev = _extract_user_history(history)
    prev_comb = " ".join(user_prev[:-1] if user_prev and user_prev[-1] == clean_q else user_prev).lower()
    full_ctx = f"{prev_comb} {comb_l}".strip()

    is_yes = q_norm in {"አዎ", "አዎን", "አለ", "አለኝ", "ይጨምራል", "awo", "yes"}
    is_no = q_norm in {"የለም", "የለኝም", "አይጨምርም", "yelem", "no"}
    worse_breathing = any(k in full_ctx for k in ["ትንፋሽ", "ትኩሳት", "breathing", "fever"]) and is_yes
    worse_on_breath = any(k in full_ctx for k in ["ስትተነፍስ", "ስትተነፍሱ", "መተንፈስ", "ውጋት", "ልቤን"]) and is_yes
    no_help_or_transport = any(k in prev_comb for k in ["ሆስፒታል", "መጓጓዣ", "የሚረዳዎት", "ትንፋሽ", "ትኩሳት"]) and is_no

    has_heart_or_stab = any(k in full_ctx for k in ["ልቤን", "ልብ", "ውጋት", "ደረቴ", "ደረት"])
    has_dry_cough = any(k in full_ctx for k in ["ደረቅ ሳል", "ሳል", "ያስለኛል", "cough"])
    has_breath_change = any(k in full_ctx for k in ["ስትተነፍሱ", "ስትተነፍስ", "ትንፋሽ", "breathing"])

    if no_help_or_transport:
        meaning = (
            "የትንፋሽ ማጠር ወይም ትኩሳት አብሮት ያለ የልብ/የደረት ውጋትና ደረቅ ሳል በሚኖርበት ወቅት የሚረዳ ሰው ወይም መጓጓዣ ማጣት "
            "የሕክምና ዕርዳታ ለማግኘት ተጨማሪ ጥንቃቄ የሚያስፈልገው ሁኔታ ነው።"
        )
        symptoms = "የትንፋሽ ማጠር፣ ትኩሳት፣ ስትተነፍሱ የሚጨምር የልብ/የደረት ውጋት፣ ደረቅ ሳል ወይም ድካም።"
        causes = "የሳንባ ወይም የልብ/የሳንባ ሽፋን መቆጣት ወይም ኢንፌክሽን ጋር የተያያዘ ሁኔታ ሊሆን ይችላል።"
        treatment = (
            "በአቅራቢያዎ ያለ ጎረቤት፣ ጓደኛ ወይም የቤተሰብ አባል በአስቸኳይ እንዲያግዝዎት መጠየቅ ወይም ባጃጅ/ታክሲ በፍጥነት መጥራት ይመከራል። "
            "ብቻዎን ወደ ረጅም ርቀት አይራመዱ፤ ራስዎን ሳያደክሙ ይቀመጡ ወይም ትንሽ ከፍ ብለው ይደገፉ፤ የድንገተኛ ሕክምና እርዳታ ወይም የቅርብ ሆስፒታል ያሳውቁ። "
            "አሁን ላይ የትንፋሽ ማጠሩ ወይም ውጋቱ እየባሰ ከሄደ በአቅራቢያዎ ያለን ማንኛውንም ሰው ወዲያውኑ ያሳውቁ።"
        )
        return (
            f"ምንነት:\n{meaning}\n\n"
            f"ምልክቶች:\n{symptoms}\n\n"
            f"መንስኤዎች:\n{causes}\n\n"
            f"ሕክምና:\n{treatment}"
        )

    if worse_breathing:
        meaning = (
            "የትንፋሽ ማጠር እና/ወይም ትኩሳት ከደረቅ ሳል እና ስትተነፍሱ ከሚጨምር የልብ/የደረት ውጋት ጋር ሲገናኙ "
            "ሳንባን፣ የሳንባ ወይም የልብ ሽፋንን ወይም ሌላ የመተንፈሻ/የልብ ሁኔታን ሊያመለክቱ የሚችሉ አጣዳፊ ምልክቶች ናቸው።"
        )
        symptoms = "የትንፋሽ ማጠር፣ ትኩሳት፣ ስትተነፍሱ ወይም ስትስሉ የሚጨምር የልብ/የደረት ውጋት፣ ደረቅ ሳል፣ ድካም ወይም ማዞር።"
        causes = (
            "የሳንባ ኢንፌክሽን (እንደ ሳምባ ምች)፣ የሳንባ ሽፋን ወይም የልብ ሽፋን መቆጣት፣ ወይም ሌላ አጣዳፊ የመተንፈሻና የልብ ሁኔታ ሊሆን ይችላል"
            + (f" (ከ{titles_am[0]} ጋር ሊያያዝ ይችላል)" if titles_am else "")
            + "።"
        )
        treatment = (
            "አሁኑኑ ወደ ሆስፒታል በመቅረብ በሐኪም መመርመር ያስፈልጋል። እስከሚደርሱ ድረስ ራስዎን ሳያደክሙ ማረፍ፣ "
            "ትንሽ ከፍ ብሎ መቀመጥ፣ እና ሕመሙ ወይም የትንፋሽ ማጠሩ እየባሰ ከሄደ አስቸኳይ የሕክምና ዕርዳታ ማግኘት አለብዎት። "
            "አሁን ላይ ወደ ሆስፒታል ለመሄድ የሚረዳዎት ሰው ወይም መጓጓዣ አለዎት?"
        )
        return (
            f"ምንነት:\n{meaning}\n\n"
            f"ምልክቶች:\n{symptoms}\n\n"
            f"መንስኤዎች:\n{causes}\n\n"
            f"ሕክምና:\n{treatment}"
        )

    if worse_on_breath or has_breath_change:
        meaning = (
            "ስትተነፍሱ ውጋቱ የሚጨምር ከሆነ ይህ በተለይ ከሳንባ/ከመተንፈሻ አካላት ሽፋን፣ ከልብ ሽፋን መቆጣት "
            "ወይም ከደረት ግድግዳ ጡንቻ/ጨጓራ ጋር የተያያዘ ሊሆን ይችላል።"
        )
        symptoms = "በጥልቅ ስትተነፍሱ ወይም ስትስሉ በልብ/በደረት አካባቢ ውጋት መባባስ፣ ደረቅ ሳል፣ የትንፋሽ ማጠር ወይም በተወሰነ አቀማመጥ ሕመም መቀየር።"
        causes = (
            "የመተንፈሻ አካላት ኢንፌክሽን፣ የሳንባ ወይም የልብ ሽፋን መቆጣት፣ የጡንቻ መወጠር ወይም ከጨጓራ አሲድ ጋር የተያያዘ ሁኔታ ሊሆን ይችላል"
            + (f" (ከ{titles_am[0]} ጋር ሊያያዝ ይችላል)" if titles_am else "")
            + "።"
        )
        treatment = (
            "የሕክምና ምርመራ ማድረግና በቂ እረፍት መውሰድ ያስፈልጋል። የትንፋሽ ማጠር ካለዎት፣ ውጋቱ ከባድ ከሆነ ወይም ወደ ክንድ/ትከሻ/ጀርባ የሚሰራጭ ከሆነ "
            "ሳይዘገዩ ወዲያውኑ ወደ ሆስፒታል መቅረብ አለብዎት። አሁን ላይ የትንፋሽ ማጠር ወይም ትኩሳት አብሮ ይሰማዎታል?"
        )
        return (
            f"ምንነት:\n{meaning}\n\n"
            f"ምልክቶች:\n{symptoms}\n\n"
            f"መንስኤዎች:\n{causes}\n\n"
            f"ሕክምና:\n{treatment}"
        )

    if has_heart_or_stab and has_dry_cough:
        meaning = (
            "በልብ ወይም በደረት አካባቢ የሚሰማ ውጋት እና ደረቅ ሳል ከመተንፈሻ አካላት (እንደ ሳንባ፣ ብሮንካይተስ ወይም የአየር መተላለፊያ መቆጣት)፣ "
            "ከልብ/ከልብ ሽፋን ወይም ከጨጓራ/ከምግብ ቧንቧ (እንደ አሲድ መመለስ) ጋር ተያይዞ ሊከሰት የሚችል ጥምር ምልክት ነው።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "የልብ/የደረት አካባቢ ውጋት ወይም ሕመም፣ ደረቅ ሳል፣ የትንፋሽ ማጠር ወይም በጥልቅ ስትተነፍሱ/ስትስሉ ውጋቱ መጨመር፣ ድካም።"
        )
        causes = (
            "የቫይረስ ወይም የባክቴሪያ ኢንፌክሽን፣ የአየር መተላለፊያ ቱቦ ወይም የሳንባ/የልብ ሽፋን መቆጣት፣ የጨጓራ አሲድ ወደ ላይ መመለስ፣ የጡንቻ መወጠር "
            "ወይም ከልብና ከደም ሥር ጋር የተያያዙ ሁኔታዎች ምክንያት ሊሆን ይችላል"
            + (f" (ከ{titles_am[0]} ጋር ሊያያዝ ይችላል)" if titles_am else "")
            + "።"
        )
        treatment = (
            "በጤና ተቋም በመቅረብ የሕክምና ምርመራ ማድረግ፣ በቂ እረፍት መውሰድና ያለ ሐኪም ትዕዛዝ መድኃኒት አለመውሰድ ይመከራል። "
            "ውጋቱ ከባድ ከሆነ፣ ወደ ትከሻ/ክንድ/መንጋጋ/ጀርባ የሚሰራጭ ከሆነ፣ የትንፋሽ ማጠር፣ ቀዝቃዛ ላብ ወይም ማዞር አብሮት ካለ ወዲያውኑ ወደ ሆስፒታል መቅረብ አለብዎት። "
            "ውጋቱ ስትተነፍሱ ወይም ስትስሉ ይጨምራል፣ ወይስ ሲያርፉ ይሻላችኋል?"
        )
        return (
            f"ምንነት:\n{meaning}\n\n"
            f"ምልክቶች:\n{symptoms}\n\n"
            f"መንስኤዎች:\n{causes}\n\n"
            f"ሕክምና:\n{treatment}"
        )

    return None


def _build_tailored_amharic_profile(clean_q: str, comb_l: str, titles_am: list, syms_am: list):
    has_head = any(k in comb_l for k in ["ራስ ምታት", "ራሴን", "headache", "migraine"])
    has_cough = any(k in comb_l for k in ["ሳል", "ደረቅ ሳል", "ያስለኛል", "cough", "tussis", "pertussis"])
    has_resp = any(
        k in comb_l
        for k in [
            "ትንፋሽ",
            "ደረቴ",
            "ደረት",
            "ልቤን",
            "ውጋት",
            "ወጥቶ",
            "ሳምባ",
            "ብሮንካይተስ",
            "አስም",
            "ጉሮሮ",
            "ሳይነስ",
            "pneumonia",
            "asthma",
            "bronchitis",
            "sinusitis",
        ]
    )
    has_fever = any(k in comb_l for k in ["ትኩሳት", "ብርድ", "fever", "malaria", "typhoid", "typhus"])
    has_gi = any(
        k in comb_l
        for k in [
            "ሆድ",
            "ሆዴን",
            "ይቆርጠኛል",
            "ያቆርጠኛል",
            "ተቅማጥ",
            "ማስታወክ",
            "ማቅለሽለሽ",
            "ጨጓራ",
            "gastritis",
            "ulcer",
            "diarrhoea",
        ]
    )
    has_msk = any(
        k in comb_l
        for k in ["መገጣጠሚያ", "አጥንት", "ጀርባ", "እግር", "ስራመድ", "ጡንቻ", "ቁርጥማት", "arthritis", "joint", "back"]
    )
    has_skin = any(k in comb_l for k in ["ቆዳ", "ሽፍታ", "ማሳከክ", "እከክ", "ፈንገስ", "skin", "rash", "eczema", "scabies"])

    if (has_head or has_cough or has_resp) and has_gi:
        meaning = (
            "የመተንፈሻ አካላት ወይም የራስ ምታት/የሳል ምልክት ከሆድ ሕመም ወይም ቁርጠት ጋር በአንድ ላይ ሲታይ የቫይረስ ወይም የባክቴሪያ ኢንፌክሽን፣ "
            "የምግብ አለመስማማት/መበከል ወይም ተያያዥ የኢንፌክሽን ሁኔታ ሊሆን ይችላል።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "ራስ ምታት፣ ሳል፣ የሆድ ሕመም ወይም ቁርጠት፣ ማቅለሽለሽ/ማስታወክ፣ ትኩሳት እና ድካም።"
        )
        causes = (
            "የቫይረስ ወይም የባክቴሪያ ኢንፌክሽን፣ የተበከለ ምግብ/ውሃ፣ የጨጓራ/የአንጀት መቆጣት ወይም ከመድኃኒት/ከድካም ጋር የተያያዘ ሁኔታ ሊያስከትለው ይችላል"
            + (f" (ከ{titles_am[0]} ጋር ሊያያዝ ይችላል)" if titles_am else "")
            + "።"
        )
        treatment = (
            "ውሃና ፈሳሽ በመደበኛነት መውሰድ፣ ቀለል ያሉ ምግቦችን መመገብ፣ ማረፍ፣ የሰውነት ሙቀትን መከታተል፤ ምልክቶቹ ከቀጠሉ ወይም ትኩሳት ካለ መመርመር። "
            "ከባድ የሆድ ሕመም፣ የማያቋርጥ ትውከት/ተቅማጥ፣ የትንፋሽ ማጠር ወይም ከፍተኛ ትኩሳት ካለ ወዲያውኑ ወደ ሆስፒታል መቅረብ።"
        )
        return meaning, symptoms, causes, treatment

    if has_cough or has_resp:
        meaning = (
            "በደረት ወይም በልብ አካባቢ የመወጠር፣ የውጋት ወይም የመጨናነቅ ስሜት እና ሳል ሲሰማዎት የመተንፈሻ አካላት ኢንፌክሽን (እንደ ብሮንካይተስ፣ የሳምባ ምች፣ ጉንፋን ወይም ኢንፍሉዌንዛ)፣ "
            "የሳንባ ወይም የልብ ሽፋን መቆጣት፣ አስም ወይም ከደረት/ከሳምባ/ከልብ ጋር የተያያዘ ሁኔታ ምልክት ሊሆን ይችላል።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "ኃይለኛ ወይም ደረቅ ሳል፣ በደረት ወይም በልብ አካባቢ የውጋት ወይም የመወጠር ስሜት፣ የትንፋሽ ማጠር፣ ትኩሳት እና ድካም።"
        )
        causes = (
            "በቫይረስ ወይም በባክቴሪያ የሚከሰቱ የመተንፈሻ አካላት ኢንፌክሽኖች፣ የሳንባ/የልብ ሽፋን መቆጣት፣ አስም ወይም የአየር ቱቦ መጥበብ፣ ጭስ/አቧራ/ቀዝቃዛ አየር ወይም ሌሎች የሳምባ/የልብ ሁኔታዎች ሊያስከትሉት ይችላሉ"
            + (f" (ከ{titles_am[0]} ጋር ሊያያዝ ይችላል)" if titles_am else "")
            + "።"
        )
        treatment = (
            "ማረፍ፣ በቂ ውሃና ሞቅ ያሉ ፈሳሾችን መውሰድ፣ ጭስና አቧራ ማስወገድ፣ የሰውነት ሙቀትን መከታተል፤ ምልክቱ ከቀጠለ የሕክምና ምርመራ ማድረግ። "
            "የትንፋሽ ማጠር ከባድ ከሆነ፣ ውጋቱ ከባድ ወይም ስትተነፍሱ የሚጨምር ከሆነ፣ ወደ ክንድ/ትከሻ/ጀርባ የሚሰራጭ ከሆነ ወይም ከፍተኛ ትኩሳት ከታየ ሳይዘገዩ ወዲያውኑ ወደ ሆስፒታል መቅረብ።"
        )
        return meaning, symptoms, causes, treatment

    if has_head:
        meaning = (
            "ራስ ምታት ወይም የራስ ሕመም ሲሰማዎት ከድካም፣ ከውሃ/እንቅልፍ እጥረት፣ ከጭንቀት፣ ከሳይነስ ወይም ከኢንፌክሽን ጋር የተያያዘ ምልክት ሊሆን ይችላል።"
        )
        symptoms = "፣ ".join(syms_am) if syms_am else "ራስ ምታት፣ ድካም፣ ማዞር፣ ለብርሃን ወይም ለድምጽ ስሜታዊ መሆን ወይም ትኩሳት።"
        causes = (
            f"ከ{'፣ '.join(titles_am[:2])}፣ ከድካም/ውጥረት፣ ከውሃ/እንቅልፍ እጥረት ወይም ከኢንፌክሽን ጋር ሊያያዝ ይችላል።"
            if titles_am
            else "ከድካም፣ ከውጥረት፣ ከውሃ እጥረት፣ ከሳይነስ ወይም ከኢንፌክሽን ጋር ሊያያዝ ይችላል።"
        )
        treatment = (
            "በጸጥታና በቂ ብርሃን በሌለው ቦታ ማረፍ፣ ውሃ መጠጣት፤ ራስ ምታቱ ከባድ ከሆነ፣ ከትኩሳት/ከማስታወክ/ከማየት ችግር ጋር ከመጣ ወይም ካልተሻለ ወደ ሆስፒታል መቅረብ።"
        )
        return meaning, symptoms, causes, treatment

    if has_fever:
        meaning = (
            "ትኩሳት ሲሰማዎት ሰውነት በቫይረስ፣ በባክቴሪያ ወይም በጥገኛ ተውሳክ ኢንፌክሽን ላይ የሚያሳየው ምላሽ ሊሆን ይችላል።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "ትኩሳት፣ ብርድ ብርድ ማለት፣ መንቀጥቀጥ፣ ራስ ምታት፣ የሰውነት/የጡንቻ ሕመም እና ድካም።"
        )
        causes = (
            f"ከ{'፣ '.join(titles_am[:2])} ወይም ከኢንፌክሽን (እንደ ጉንፋን፣ ወባ፣ ታይፎይድ፣ ታይፈስ ወይም የመተንፈሻ/የሽንት ኢንፌክሽን) ጋር ሊያያዝ ይችላል።"
            if titles_am
            else "በቫይረስ፣ በባክቴሪያ ወይም በተላላፊ ኢንፌክሽኖች ምክንያት ሊከሰት ይችላል።"
        )
        treatment = (
            "ፈሳሽና እረፍት መውሰድ፣ የሰውነት ሙቀትን መከታተል፣ ያለ ሐኪም ትዕዛዝ መድኃኒት አለመውሰድ፤ "
            "ትኩሳቱ ከፍተኛ ከሆነ፣ ከ48–72 ሰዓት ከቆየ ወይም የአደጋ ምልክት ካለ ወደ ሆስፒታል መሄድ።"
        )
        return meaning, symptoms, causes, treatment

    if has_gi:
        meaning = (
            "የሆድ ሕመም፣ ቁርጠት ወይም የምግብ መፈጨት ችግር ሲሰማዎት ከጨጓራ፣ ከአንጀት፣ ከምግብ አለመስማማት ወይም ከኢንፌክሽን ጋር የተያያዘ ምልክት ሊሆን ይችላል።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "የሆድ ሕመም ወይም ቁርጠት፣ ማቅለሽለሽ፣ ማስታወክ፣ ተቅማጥ፣ የሆድ መነፋት ወይም የምግብ ፍላጎት ማጣት።"
        )
        causes = (
            f"ከ{'፣ '.join(titles_am[:2])}፣ ከጨጓራ መቆጣት፣ ከምግብ አለመስማማት/መበከል ወይም ከአንጀት ኢንፌክሽን ጋር ሊያያዝ ይችላል።"
            if titles_am
            else "ከጨጓራ ችግር፣ ከተበከለ ምግብ/ውሃ፣ ከኢንፌክሽን ወይም ከምግብ መፈጨት ችግር ጋር ሊያያዝ ይችላል።"
        )
        treatment = (
            "ውሃ ወይም ፈሳሽ በትንሽ በትንሹ መውሰድ፣ ቀለል ያሉ ምግቦችን መመገብ፣ ቅባት/ቅመም መቀነስ፤ "
            "ከባድ ሕመም፣ የማያቋርጥ ትውከት/ተቅማጥ፣ ደም ወይም ትኩሳት ካለ ወዲያውኑ ወደ ሆስፒታል መቅረብ።"
        )
        return meaning, symptoms, causes, treatment

    if has_msk:
        meaning = (
            "የመገጣጠሚያ፣ የጡንቻ፣ የጀርባ ወይም የእግር ሕመምና መደርቀቅ ሲሰማዎት ከድካም፣ ከመወጠር፣ ከቁርጥማት ወይም ከአጥንት/ነርቭ ጫና ጋር የተያያዘ ሁኔታ ሊሆን ይችላል።"
        )
        symptoms = (
            "፣ ".join(syms_am)
            if syms_am
            else "የመገጣጠሚያ ወይም የጡንቻ ሕመም፣ መደርቀቅ፣ በእንቅስቃሴ ወቅት ሕመም መጨመር ወይም ማበጥ።"
        )
        causes = (
            f"ከ{'፣ '.join(titles_am[:2])}፣ ከድካም/ከመወጠር፣ ከቁርጥማት/መገጣጠሚያ መቆጣት ወይም ከአጥንት/ነርቭ ጫና ጋር ሊያያዝ ይችላል።"
            if titles_am
            else "ከጡንቻ መወጠር፣ ከመገጣጠሚያ እብጠት፣ ከድካም ወይም ከአጥንት/ጀርባ ችግር ጋር ሊያያዝ ይችላል።"
        )
        treatment = (
            "የተጎዳውን ክፍል ማሳረፍ፣ ሕመሙን የሚያባብሱ እንቅስቃሴዎችን መቀነስ፤ "
            "ሕመሙ ከቀጠለ፣ ካበጠ፣ መራመድ ካስቸገረ ወይም የመደንዘዝ/የመስነፍ ስሜት ካለ የሕክምና ምርመራ ማድረግ።"
        )
        return meaning, symptoms, causes, treatment

    if has_skin:
        meaning = (
            "የቆዳ ሽፍታ፣ ማሳከክ ወይም የቆዳ ለውጥ ሲታይ ከአለርጂ፣ ከፈንገስ/ባክቴሪያ ኢንፌክሽን ወይም ከቆዳ መቆጣት ጋር የተያያዘ ሁኔታ ሊሆን ይችላል።"
        )
        symptoms = "፣ ".join(syms_am) if syms_am else "የቆዳ ሽፍታ፣ ማሳከክ፣ መቅላት፣ ድርቀት ወይም የቆዳ ለውጥ።"
        causes = (
            f"ከ{'፣ '.join(titles_am[:2])}፣ ከአለርጂ፣ ከፈንገስ/ባክቴሪያ ወይም ከቆዳ መቆጣት ጋር ሊያያዝ ይችላል።"
            if titles_am
            else "ከአለርጂ፣ ከኢንፌክሽን ወይም ከቆዳ መቆጣት ጋር ሊያያዝ ይችላል።"
        )
        treatment = (
            "ቆዳን ንጹሕና ደረቅ ማድረግ፣ ላለማሳከክ መሞከር፣ ንጽህናቸው ያልተረጋገጡ ቅባቶችን ያለ ሐኪም አለመቀባት፤ "
            "ሽፍታው ከተስፋፋ፣ ከተላከከ ወይም ትኩሳት ካለው ሐኪም ማማከር።"
        )
        return meaning, symptoms, causes, treatment

    return None


def build_patient_guidance(
    raw_query: str,
    effective_query: str,
    intent: str,
    matches: list,
    lang: str = "am",
    history: list = None,
) -> str:
    direct = find_direct_disease_guide(effective_query) or find_direct_disease_guide(raw_query)
    if direct:
        if lang == "en":
            return clean_plain_text(
                f"Meaning ({direct['name_en']}):\n{direct['meaning_en']}\n\n"
                f"Symptoms:\n{direct['symptoms_en']}\n\n"
                f"Causes:\n{direct['causes_en']}\n\n"
                f"Treatment:\n{direct['treatment_en']}"
            )
        return clean_plain_text(
            f"ምንነት ({direct['name_am']}):\n{direct['meaning_am']}\n\n"
            f"ምልክቶች:\n{direct['symptoms_am']}\n\n"
            f"መንስኤዎች:\n{direct['causes_am']}\n\n"
            f"ሕክምና:\n{direct['treatment_am']}"
        )

    clean_q = clean_plain_text(raw_query)
    q_l = clean_q.lower()
    comb_l = f"{q_l} {(effective_query or '').lower()}"
    top = matches[0] if matches else None
    definition_en = (top.get("definition") or "").strip() if top else ""
    title_am = (
        translate_disease_title(top.get("name", ""), include_code=False, lang="am")
        if top
        else clean_q
    )
    title_en = clean_plain_text(top.get("name", "")) if top else clean_q

    titles_am = []
    for m in matches[:4]:
        t = translate_disease_title(m.get("name", ""), include_code=False, lang="am")
        if t and t != "የጤና ሁኔታ" and t not in titles_am:
            titles_am.append(t)

    titles_en = [clean_plain_text(m.get("name", "")) for m in matches[:3] if m.get("name")]
    syms_am = _collect_symptoms_am(matches, comb_l)
    syms_en = _collect_symptoms_en(matches, comb_l)

    if lang == "en":
        meaning_txt = (
            definition_en
            if definition_en
            else f"{title_en} is a medical/health condition or symptom presentation related to '{clean_q}'."
        )
        symptoms_txt = (
            ", ".join(syms_en)
            if syms_en
            else "Varies by individual and condition severity (such as fever, pain, fatigue, or organ-specific signs)."
        )
        causes_txt = (
            f"May be associated with {', '.join(titles_en)}, infection, inflammation, lifestyle/environmental factors, or underlying conditions."
            if titles_en
            else "May be associated with infection, inflammation, lifestyle/environmental factors, or underlying health conditions."
        )
        treatment_txt = (
            "Proper clinical evaluation by a physician, targeted medical treatment as prescribed, adequate rest/hydration, and prompt hospital care for severe or worsening signs."
        )
        return clean_plain_text(
            f"Meaning:\n{meaning_txt}\n\n"
            f"Symptoms:\n{symptoms_txt}\n\n"
            f"Causes:\n{causes_txt}\n\n"
            f"Treatment:\n{treatment_txt}"
        )

    conversational = _build_conversational_amharic_guidance(
        clean_q=clean_q,
        comb_l=comb_l,
        history=history or [],
        matches=matches,
        titles_am=titles_am,
        syms_am=syms_am,
    )
    if conversational:
        return clean_plain_text(conversational)

    tailored = _build_tailored_amharic_profile(clean_q, comb_l, titles_am, syms_am)
    if tailored:
        meaning_txt, symptoms_txt, causes_txt, treatment_txt = tailored
        return clean_plain_text(
            f"ምንነት:\n{meaning_txt}\n\n"
            f"ምልክቶች:\n{symptoms_txt}\n\n"
            f"መንስኤዎች:\n{causes_txt}\n\n"
            f"ሕክምና:\n{treatment_txt}"
        )

    is_first_person_symptom = any(
        w in comb_l for w in ["ያመኛል", "ይሰማኛል", "ያስለኛል", "ይቆርጠኛል", "ያቆርጠኛል", "አለኝ", "አለብኝ"]
    )
    if is_first_person_symptom:
        meaning_txt = (
            "የተጠቀሰው ምልክት ከኢንፌክሽን፣ ከድካም፣ ከእብጠት ወይም ከተያያዘ የጤና ሁኔታ ጋር ተያይዞ ሊከሰት የሚችል የጤና ምልክት ነው።"
        )
    else:
        meaning_txt = (
            f"{title_am} በሕክምና ምርመራና ክትትል ሊታይ የሚገባ የጤና ሁኔታ ወይም ተያያዥ ምልክት ነው።"
            if (title_am and title_am != "የጤና ሁኔታ")
            else f"'{clean_q}' በሕክምና ምርመራና ክትትል ሊታይ የሚገባ የጤና ሁኔታ ወይም ምልክት ነው።"
        )

    symptoms_txt = (
        "፣ ".join(syms_am)
        if syms_am
        else "እንደ ሁኔታው አይነትና ክብደት ሊለያዩ ይችላሉ (ለምሳሌ ትኩሳት፣ ሕመም፣ ድካም ወይም ከተጎዳው አካል ጋር የተያያዘ ለውጥ)።"
    )
    causes_txt = (
        f"ከ{'፣ '.join(titles_am)}፣ ከኢንፌክሽን፣ ከእብጠት፣ ከአመጋገብ/አኗኗር ወይም ከሌሎች የጤና ሁኔታዎች ጋር ሊያያዝ ይችላል።"
        if titles_am
        else "በኢንፌክሽን፣ በእብጠት፣ በአመጋገብ/አኗኗር ወይም በሌሎች የጤና ሁኔታዎች ምክንያት ሊከሰት ይችላል።"
    )
    treatment_txt = (
        "በሐኪም ምርመራ መሰረት የሚሰጥ ተገቢ ሕክምና፣ በቂ እረፍትና ፈሳሽ መውሰድ፣ እንዲሁም ምልክቶች ሲባባሱ ወይም ከባድ ሲሆኑ ወደ ሆስፒታል መቅረብ።"
    )

    return clean_plain_text(
        f"ምንነት:\n{meaning_txt}\n\n"
        f"ምልክቶች:\n{symptoms_txt}\n\n"
        f"መንስኤዎች:\n{causes_txt}\n\n"
        f"ሕክምና:\n{treatment_txt}"
    )


@app.route("/", methods=["GET"])
def read_root():
    return jsonify(
        {
            "status": "online",
            "system": "Misrak Chora AI - Clinical Decision Support System",
            "hospital": "ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል (East Command Level 3 Hospital)",
            "creator": "አስር አለቃ ስዩም ቦጋለ (Corporal Seyoum Bogale)",
            "loaded_conditions": len(PREPARED_KB),
        }
    )


@app.route("/api/hospital-info", methods=["GET"])
def get_hospital_info():
    return jsonify(
        {
            "hospital_am": "ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል",
            "hospital_en": "East Command Level 3 Hospital",
            "system_am": "የምስራቅ ጮራ AI",
            "system_en": "Misrak Chora AI",
            "creator_am": "አስር አለቃ ስዩም ቦጋለ (የአይ ሲቲ ሙያተኛ - ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል)",
            "creator_en": "Corporal Seyoum Bogale (ICT Specialist, East Command Level 3 Hospital)",
            "info_am": HOSPITAL_INFO_AM,
            "info_en": HOSPITAL_INFO_EN,
        }
    )


@app.route("/api/ask", methods=["POST"])
def ask_medical_ai():
    try:
        data = request.get_json(silent=True) or {}
        user_id = str(data.get("user_id", "default"))
        raw_query = str(data.get("question", "")).strip()
        history = data.get("history")
        if not isinstance(history, list):
            history = []

        if not raw_query:
            return (
                jsonify(
                    {
                        "answer": "እባክዎ የጤና ጥያቄዎን ወይም የሚሰማዎትን ምልክት ያስገቡ። / Please enter your question."
                    }
                ),
                400,
            )

        lang = detect_language(raw_query)

        greeting_reply = get_greeting_response(raw_query, lang)

        if greeting_reply:
            return jsonify({
                "answer": clean_plain_text(greeting_reply),
                "matches": []
            })

        query = normalize_query(raw_query, lang)

        triage = get_triage_response(query)

        if triage:
            return jsonify({
                "answer": triage,
                "matches": []
            })

        q_lower = query.lower()

        if is_identity_query(q_lower):
            return jsonify(
                {"answer": clean_plain_text(IDENTITY_AM if lang == "am" else IDENTITY_EN), "matches": []}
            )

        if is_hospital_info_query(q_lower):
            return jsonify(
                {
                    "answer": clean_plain_text(HOSPITAL_INFO_AM if lang == "am" else HOSPITAL_INFO_EN),
                    "matches": [],
                }
            )

        contextual_query = build_contextual_search_query(query, history)
        intent = detect_intent(q_lower)
        matches, _ = search_all_kb(contextual_query, lang=lang)
        if not matches and contextual_query != query:
            matches, _ = search_all_kb(query, lang=lang)

        if not matches and looks_like_typo_or_unclear(query, lang):
            return jsonify({"answer": build_clarification_message(raw_query, lang), "matches": []})

        if intent == "code":
            if not matches:
                return jsonify(
                    {"answer": clean_plain_text("ኮድ አልተገኘም።" if lang == "am" else "Code not found."), "matches": []}
                )
            code_only = (matches[0].get("code") or "").strip()
            return jsonify(
                {
                    "answer": clean_plain_text(
                        code_only or ("ኮድ አልተገኘም።" if lang == "am" else "Code not found.")
                    ),
                    "matches": matches[:10],
                }
            )

        return jsonify(
            {
                "answer": build_patient_guidance(
                    raw_query=query,
                    effective_query=contextual_query,
                    intent=intent,
                    matches=matches,
                    lang=lang,
                    history=history,
                ),
                "matches": matches[:5],
            }
        )
    except Exception as e:
        tb = traceback.format_exc()
        print(tb)
        return jsonify({
            "answer": f"Error: {str(e)}\n\n{tb}",
            "matches": []
        }), 200


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=False)