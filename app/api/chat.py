from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, List
from app.services.ollama_service import query_ollama_with_history

router = APIRouter(prefix="/api")

# Pamięć historii: klucz = session_id, wartość = lista wiadomości
chat_histories: Dict[str, List[Dict[str, str]]] = {}

class ChatRequest(BaseModel):
    session_id: str
    prompt: str
    model: str = "llama3"

class ChatResponse(BaseModel):
    response: str

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    sid = request.session_id
    prompt = request.prompt
    model = request.model

    # 1) jeśli nowa sesja, utwórz listę
    if sid not in chat_histories:
        chat_histories[sid] = []

    # 2) dodaj pytanie użytkownika
    chat_histories[sid].append({"role": "user", "content": prompt})

    try:
        # 3) wyślij całą historię do Ollamy
        reply = query_ollama_with_history(chat_histories[sid], model)
        # 4) zapisz odpowiedź w historii
        chat_histories[sid].append({"role": "assistant", "content": reply})
        return {"response": reply}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd modelu: {e}")
