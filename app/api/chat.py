from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.config import Settings
from app.services.ollama_service import query_ollama

router = APIRouter(prefix="/api")

class ChatRequest(BaseModel):
    prompt: str

class ChatResponse(BaseModel):
    response: str

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        # Wywołujemy lokalny model przez serwis
        result = query_ollama(request.prompt)
        return {"response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd modelu: {e}")
