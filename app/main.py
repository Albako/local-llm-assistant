from fastapi import FastAPI
from app.api.chat import router as chat_router

app = FastAPI(
    title="My Local ChatGPT API",
    description="API do wysyłania zapytań do lokalnego modelu Ollama",
    version="0.1.0",
)

@app.get("/", tags=["Health"])
async def health_check():
    return {"status": "ok"}

# Dołączamy router z chat.py pod prefiksem /api
app.include_router(chat_router, prefix="/api", tags=["Chat"])
