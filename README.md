# Część projektu poświęcona Backend-owi AI (ollama)

Do testów proszę pamiętać, żeby wybrać model/modele, które są mniejsze (GB) niż ilość pamięci VRAM GPU/RAM CPU.
Im mniejszy model, tym więcej błędów będzie popełniał.

### Program wymaga użycia systemu Linux (WSL lub pełny desktop)

Wybrać można którykolwiek model spośród biblioteki ollama https://ollama.com/search . Testowane modele to:
1. llama3.2 - popularny model stworzony przez firmę Meta (dawniej Facebook). Dostępny jest tu w dwóch wariantach:
- llama3.2 (3b) 2.0GB
- llama3.2:1b 1.3GB
2. gemma3 - popularny model stworzony przez firmę Google na podwalinach flagowego modelu Gemini. Dostępny jest tu w jednym wariancie:
- gemma3:4b 3.3GB
3. dolphincoder - model oparty na StarCoder2 7b oraz 15b. Został stworzony z myślą o pisaniu kodu. Dostępny jest tu w jednym wariancie:
- dolphincoder:7b 4.2GB

### Wymagania
- Docker i Docker Compose
- Poprawnie skonfigurowany NVIDIA Container Toolkit (w przypadku GPU NVIDIA)
- Sterowniki CUDA NVIDIA lub ROCm AMD

## Uruchomienie
Aby uruchomić serwis, należy w głównym folderze projektu wykonać komendę:

	```bash
	docker compose up -d
	```

### Konfiguracja modeli
By program pobrał modele, należy stworzyć plik `.env` w głównej ścieżce ze zmienną `OLLAMA_MODELS`:

	```
	OLLAMA_MODELS=<tu należy zdefiniować które modele zostaną ściągnięcie. Proszę o oddzielanie modeli przecinkami `,`>
	```
 Przykład poprawnie zdefiniowanej zmiennej:
 
 	```
  	OLLAMA_MODELS=llama3.2,llama3.2:1b,gemma3:4b,dolphincoder:7b
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
