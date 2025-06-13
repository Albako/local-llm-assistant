from pydantic import BaseSettings

class Settings(BaseSettings):
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    ollama_host: str = "localhost"
    ollama_port: int = 11434

    class Config:
        env_file = ".env"
