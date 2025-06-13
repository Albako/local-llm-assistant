# Część projektu poświęcona Backend-owi AI (ollama)

Do testów proszę pamiętać, żeby wybrać model/modele, które są mniejsze (GB) niż ilość pamięci VRAM GPU/RAM CPU.
Im mniejszy model, tym więcej błędów będzie popełniał.
Im większy model, tym wolniej będzie działał.

### Program wymaga uruchomienia w systemie Linux, lub w systemie Windows przez WSL

Program jest w stanie sam wykryć GPU NVIDIA/AMD/INTEL. W przypadku braku posiadania GPU NVIDIA/AMD/INTEL program sam się uruchomi w trybie CPU.
 - Automatyczne wykrywanie:

	```bash
 	./start.sh -d --build
  	```
 - Wymuszenie trybu CPU:
	
   	```bash
    ./start.sh --cpu -d
    
 - Wymuszenie trybu NVIDIA:

	```bash
 	./start.sh --nvidia -d
 	```
 - Wymuszenie trybu AMD:

	```bash
 	./start.sh --amd -d
 	```

 - Wymuszenie trybu INTEL:

	```bash
 	./start.sh --intel -d
 	```

### Wybór modelu/modeli
Wybrać można którykolwiek model spośród biblioteki ollama https://ollama.com/search . Testowane modele to:
1. llama3.2 - popularny model stworzony przez firmę Meta (dawniej Facebook). Testowany był w dwóch wariantach:
  - llama3.2 (3b) 2.0GB
  - llama3.2:1b 1.3GB
2. gemma3 - popularny model stworzony przez firmę Google na podwalinach flagowego modelu Gemini. Testowany był w jednym wariancie:
  - gemma3:4b 3.3GB
3. dolphincoder - model oparty na StarCoder2 7b oraz 15b. Został stworzony z myślą o pisaniu kodu. Testowany był w jednym wariancie:
  - dolphincoder:7b 4.2GB
4. deepseek-r1 - popularny chiński model stworzony by konkurował z modelami od OpenAI. Testowany był w trzech wariantach:
  - deepseek-r1:7b 4.7GB
  - deepseek-r1:14b 9.0GB
  - deepseek-r1:70b 43GB

### Wymagania
- Docker i Docker Compose
- Poprawnie skonfigurowany NVIDIA Container Toolkit (w przypadku GPU NVIDIA)
- Sterowniki `CUDA NVIDIA`/`AMDGPU ROCm AMD`


### Konfiguracja modeli
By program pobrał modele, należy stworzyć plik `.env` w głównej ścieżce ze zmienną `OLLAMA_MODELS`:

	
	OLLAMA_MODELS=<tu należy zdefiniować które modele zostaną ściągnięcie. Proszę o oddzielanie modeli przecinkami `,`>
	
 Przykład poprawnie zdefiniowanej zmiennej:
 
 	
  	OLLAMA_MODELS=llama3.2,gemma3:4b,dolphincoder:7b
   	


Aby pobrać nowe modele, należy zrestartować serwis komendą:

	bash
	docker compose down
	
## Uruchomienie
Aby uruchomić serwis, należy w głównym folderze projektu wykonać komendę:

	bash
	./start.sh -d --build


 Sprawdzenie czy `ollama` skończyła przygotowywać model/modele:

 	bash
  	docker compose logs -f ollama-ai
	
 

### Testowanie

Po uruchomieniu i pobraniu modeli, można przetestować API za pomocą `curl`:

	bash
	curl http://localhost:11434/api/generate -d '{
		"model": "llama3.2",
		"prompt": "Przywitaj się i przedstaw.",
		"stream": false
	}'
287e827 (docs: Aktualizacja README i badanie API)
