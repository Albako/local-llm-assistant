# dodaję historię czatu
def query_ollama_with_history(messages: list, model: str = "llama3"):
    url = f"http://{settings.ollama_host}:{settings.ollama_port}/api/chat"
    payload = {
        "model": model,
        "messages": messages,
        "stream": False
    }
    response = requests.post(url, json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()
    return data.get("message", {}).get("content", "")
