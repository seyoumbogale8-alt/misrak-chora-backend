SESSIONS = {}

def start_session(user_id, symptom):
    SESSIONS[user_id] = {
        "symptom": symptom,
        "step": 0,
        "answers": []
    }

def get_session(user_id):
    return SESSIONS.get(user_id)

def save_answer(user_id, answer):
    if user_id in SESSIONS:
        SESSIONS[user_id]["answers"].append(answer)
        SESSIONS[user_id]["step"] += 1

def end_session(user_id):
    if user_id in SESSIONS:
        del SESSIONS[user_id]