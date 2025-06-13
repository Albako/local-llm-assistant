import requests
from app.core.config import Settings

settings = Settings()

def query_ollama(prompt: str, model: str = "llama3"):
    url = f"http://{settings.ollama_host}:{settings.ollama_port}/api/generate"
    payload = {
        "prompt": prompt,
        "stream": False,
        "model": model
    }
    response = requests.post(url, json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()
    return data.get("response", "")
