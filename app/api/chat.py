from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, List
from app.core.config import Settings
from app.services.ollama_service import query_ollama_with_history

router = APIRouter(prefix="/api")


chat_histories: Dict[str, List[Dict[str, str]]] = {}

class ChatRequest(BaseModel):
    session_id: str
    prompt: str

class ChatResponse(BaseModel):
    response: str

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        session_id = request.session_id
        prompt = request.prompt

        
        if session_id not in chat_histories:
            chat_histories[session_id] = []

        
        chat_histories[session_id].append({"role": "user", "content": prompt})

        
        result = query_ollama_with_history(chat_histories[session_id])

        
        chat_histories[session_id].append({"role": "assistant", "content": result})

        return {"response": result}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd modelu: {e}")
