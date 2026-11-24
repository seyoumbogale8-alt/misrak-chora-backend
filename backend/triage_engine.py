from conversation_manager import *

TRIAGE_QUESTIONS = {

    "chest": [
        "የደረት ህመሙ መቼ ጀመረ?",
        "ስትተነፍሱ ይጨምራል?",
        "ትንፋሽ ማጠር አለ?",
        "ትኩሳት አለ?"
    ],

    "headache": [
        "ራስ ምታቱ መቼ ጀመረ?",
        "ትኩሳት አለ?",
        "ማዞር አለ?",
        "ማስታወክ አለ?"
    ],

    "abdomen": [
        "የሆድ ህመሙ የት ነው?",
        "ተቅማጥ አለ?",
        "ማስታወክ አለ?",
        "ትኩሳት አለ?"
    ],

    "cough": [
        "ሳሉ ደረቅ ነው ወይስ አክታ አለ?",
        "ትኩሳት አለ?",
        "ትንፋሽ ማጠር አለ?",
        "ስንት ቀን ሆኖታል?"
    ],

    "skin": [
        "ሽፍታው መቼ ጀመረ?",
        "ማሳከክ አለ?",
        "ትኩሳት አለ?",
        "ወደ ሌላ ቦታ ተስፋፍቷል?"
    ]
}


def detect_symptom_group(text):

    q = text.lower()

    if "ደረት" in q or "ደረቴ" in q:
        return "chest"

    if "ራስ" in q:
        return "headache"

    if "ሆድ" in q:
        return "abdomen"

    if "ሳል" in q:
        return "cough"

    if "ቆዳ" in q or "ሽፍታ" in q:
        return "skin"

    return None


def get_triage_response(query):

    group = detect_symptom_group(query)

    if not group:
        return None

    questions = TRIAGE_QUESTIONS[group]

    result = "እባክዎ እነዚህን ጥያቄዎች ይመልሱ።\n\n"

    for i, q in enumerate(questions, 1):
        result += f"{i}. {q}\n"

    return result
def next_question(user_id, question_list):

    session = get_session(user_id)

    if not session:
        return None

    step = session["step"]

    if step >= len(question_list):
        return None

    return question_list[step]