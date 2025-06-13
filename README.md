# Część projektu poświęcona Backend-owi AI (ollama)

# >>> W obecnym stanie rozwoju projekt powinien działać jedynie na GPU od firmy Nvidia. Przepraszamy za niedogodności. <<< #

Do testów proszę pamiętać, żeby wybrać model/modele, które są mniejsze (GB) niż ilość pamięci vram twojego GPU.
Im mniejszy model, tym więcej błędów będzie popełniał.

Do wyboru obecnie są trzy modele:
1. llama3.2 - popularny model stworzony przez firmę Meta (dawniej Facebook). Dostępny jest tu w dwóch wariantach:
	-> llama3.2 (3b) 2.0GB
	-> llama3.2:1b 1.3GB
2. gemma3 - popularny model stworzony przez firmę Google na podwalinach flagowego modelu Gemini. Dostępny jest tu w jednym wariancie:
	-> gemma3:4b 3.3GB
3. dolphincoder - model oparty na StarCoder2 7b oraz 15b. Został stworzony z myślą o pisaniu kodu. Dostępny jest tu w jednym wariancie:
	-> dolphincoder:7b 4.2GB

Po więcej informacji o modelach, lub też po informację o większej ilości modeli zapraszamy na: https://ollama.com/search

### Wymagania
- Docker i Docker Compose
- Poprawnie skonfigurowany NVIDIA Container Toolkit

## Uruchomienie
Aby uruchomić serwis, należy w głównym folderze projektu wykonać komendę:
	```bash
	docker compose up -d
	```

### Konfiguracja modeli
Można wybrać inne zdefiniowane modele, lub zostawić obecnie wybrane. Aby edytować należy w pliku `.env` zmienną `OLLAMA_MODELS`:
	```
	OLLAMA_MODELS=<tu należy zdefiniować które modele zostaną ściągnięcie. Proszę o oddzielanie modeli przecinkami `,`>
	```
Aby pobrać nowe modele, należy zrestartować serwis komendą:
	```bash
	docker compose down
	```

### Testowanie

Po uruchomieniu i pobraniu modeli, można przetestować API za pomocą `curl`:

	```bash
	curl http://localhost:11434/api/generate -d '{
		"model": "llama3.2",
		"prompt": "Przywitaj się i przedstaw."
		"stream": false
	}'
	```
