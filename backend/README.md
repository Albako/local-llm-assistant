# Część projektu poświęcona Backend-owi AI (ollama)

Do testów proszę pamiętać, żeby wybrać model/modele, które są mniejsze (GB) niż ilość pamięci VRAM GPU/RAM CPU.
Im mniejszy model, tym więcej błędów będzie popełniał.
Im większy model, tym wolniej będzie działał.

### Program wymaga uruchomienia w systemie Linux, lub w systemie Windows przez WSL

Program jest w stanie sam wykryć GPU NVIDIA/AMD/INTEL. W przypadku braku posiadania GPU NVIDIA/AMD/INTEL program sam się uruchomi w trybie CPU.
1. Linux:
 - Automatyczne wykrywanie:

	```bash
 	./launch.sh --build -d
  	```
 - Wymuszenie trybu CPU:
	
   	```bash
    ./launch.sh --cpu --build -d
	```

 - Wymuszenie trybu NVIDIA:

	```bash
 	./launch.sh --nvidia --build -d
 	```
 - Wymuszenie trybu AMD:

	```bash
 	./launch.sh --amd --build -d
 	```

 - Wymuszenie trybu INTEL:

	```bash
 	./launch.sh --intel --build -d
 	```
2. Windows:
 - Automatyczne wykrywanie GPU (NVIDIA):
   ```DOS
   .\start.bat
   ```

 - Wymuszenie określonego trybu GPU:
   ```DOS
   .\start.bat --nvidia
   .\start.bat --amd
   .\start.bat --intel
   .\start.bat --cpu
   ```

 - Tryb lokalny (bez Docker):
   ```DOS
   .\start.bat --local
   ```

**Uwaga**: Na Windows `start.bat` teraz obsługuje automatyczne wykrywanie NVIDIA GPU oraz wymuszanie trybów GPU. Wymaga zainstalowanych sterowników i Docker Desktop z GPU support.

Pozostałą część systemu należy obsługiwać w oknie terminala z włączoną dystrybucją WSL2.

**Dla pełnej kontroli w WSL2 (opcjonalnie):**
```bash
# W WSL2 terminal (navigate to project directory):
cd /mnt/c/Users/[TwojaNazwaUzytkownika]/Downloads/Projekt-openwebui-merge-with-main-backend/Projekt-openwebui-merge-with-main-backend/backend

# Automatyczne wykrywanie GPU:
./launch.sh

# Wymuszenie określonego trybu:
./launch.sh --nvidia
./launch.sh --amd  
./launch.sh --intel
./launch.sh --cpu

# Tryb lokalny (bez Docker):
./launch.sh --local
``` 
### Disclaimer
Żeby wszystko poprawnie działało, należy poprawnie skonfigurować dystrybucję Linux w WSL2.

## Wybór modelu/modeli
Wybrać można którykolwiek model spośród biblioteki ollama https://ollama.com/search . Testowane modele to:
1. llama3.2 - popularny model stworzony przez firmę Meta (dawniej Facebook). Testowany był w dwóch wariantach:
  - llama3.2 (3b) 2.0GB - Na podstawie tego modelu został stworzony asystent-projektu, który ma za zadanie specjalizować się w tematyce związanej z tym projektem.
  - llama3.2:1b 1.3GB
2. gemma3 - popularny model stworzony przez firmę Google na podwalinach flagowego modelu Gemini. Testowany był w jednym wariancie:
  - gemma3:4b 3.3GB
3. dolphincoder - model oparty na StarCoder2 7b oraz 15b. Został stworzony z myślą o pisaniu kodu. Testowany był w jednym wariancie:
  - dolphincoder:7b 4.2GB
4. deepseek-r1 - popularny chiński model stworzony by konkurował z modelami od OpenAI. Testowany był w trzech wariantach:
  - deepseek-r1:7b 4.7GB
  - deepseek-r1:14b 9.0GB
  - deepseek-r1:70b 43GB

## Wymagania
- Docker i Docker Compose
- **Na Windows**: 
  - Docker Desktop z GPU support (dla NVIDIA: włącz "Use WSL 2 based engine" + "Enable GPU support")
  - WSL2 integration (Settings -> Resources -> WSL integration)
  - `Enable integration with my default WSL distro` zaznaczone
- **Dla GPU support**:
  - NVIDIA: NVIDIA Container Toolkit + CUDA drivers  
  - AMD: ROCm drivers (eksperymentalne na Windows)
  - Intel: Intel GPU drivers (eksperymentalne na Windows)
  
**Uwaga**: `start.bat` teraz obsługuje automatyczne wykrywanie NVIDIA GPU na Windows. Dla AMD/Intel może być potrzebne WSL2.


## Konfiguracja modeli
By program pobrał modele, należy stworzyć plik `.env` w głównej ścieżce ze zmienną `OLLAMA_MODELS`. Jeśli plik nie zostanie stworzony ręcznie, program sam stworzy wymagany plik na podstawie .env.example:

	
	OLLAMA_MODELS=<tu należy zdefiniować które modele zostaną ściągnięcie. Proszę o oddzielanie modeli przecinkami `,`>
	
 Przykład poprawnie zdefiniowanej zmiennej:
 
 	
  	OLLAMA_MODELS=llama3.2,gemma3:4b,dolphincoder:7b
   	


Aby pobrać nowe modele, należy zrestartować serwis komendą:

	
	docker compose down
	
### Uruchomienie
Aby uruchomić serwis, należy użyć odpowiedniego skryptu:

**Linux/WSL2:**
```bash
# Podstawowe uruchomienie z automatycznym wykrywaniem GPU:
./launch.sh

# Uruchomienie z budowaniem kontenera od nowa:
./launch.sh --build

# Uruchomienie w trybie lokalnym (bez Docker):
./launch.sh --local
```

**Windows (rozszerzone możliwości):**
```dos
# Automatyczne wykrywanie GPU:
.\start.bat

# Wymuszenie określonego trybu:
.\start.bat --nvidia    # Wymusza NVIDIA GPU
.\start.bat --amd       # Wymusza AMD GPU  
.\start.bat --intel     # Wymusza Intel GPU
.\start.bat --cpu       # Wymusza CPU

# Tryb lokalny:
.\start.bat --local
```

**Uwaga**: `ui_start.sh` jest używany wewnętrznie przez Docker i nie powinien być uruchamiany bezpośrednio przez użytkownika.


Sprawdzenie czy `ollama` skończyła przygotowywać model/modele:

	docker compose logs -f ollama

## Troubleshooting
W przypadku gdy linux nie będzie chciał uruchomić naszego programu, należy zweryfikować na czym polega błąd. Najczęstszymi problemami są:

1. **Błędnie skonfigurowany Docker w przypadku WSL**
2. **Brak uprawnień dla plików .sh**
   
   Rozwiązanie:
   ```bash
   chmod +x *.sh
   ```
   
   Lub użyj skryptu naprawczego:
   ```bash
   ./fix-permissions.sh
   ```

3. **Problemy z plikiem .env**
   - Upewnij się, że plik .env istnieje w katalogu głównym
   - Sprawdź, czy nie zawiera błędnych znaków lub pustych linii
   - Użyj pliku .env.example jako szablonu

4. **Problemy z portami**
   - Sprawdź, czy porty 8080 i 11434 nie są zajęte
   - Zmień porty w pliku .env jeśli potrzeba	
 

### Testowanie

1. Sprawdzenie listy pobranych modeli:

		docker compose exec ollama ollama list

2. Po uruchomieniu i pobraniu modeli, można przetestować API za pomocą `curl`:

	
		curl http://localhost:11434/api/generate -d '{
		"model": "asystent-projektu",
		"prompt": "Czym jest konteneryzacja w kontekscie Dockera?",
		"stream": false
		}'

3. Skrypt testujący wydajność zapamiętywania kontekstu:

		./test_wydajnosci.sh

Jeśli z biegiem testu czas trwania (ms) rosną, to oznacza, że podel poprawnie "zapamiętuje" historie rozmowy.
By test poprawnie działał, należy mieć zainstalowane narzędzie jq.

Instalacja jq:
1. Ubuntu/Debian

		sudo apt install jq

2. Fedora

		sudo dnf install jq

3. Arch

		sudo pacman -S jq
