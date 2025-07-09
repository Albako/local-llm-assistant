# Lokalny Asystent AI oparty o Ollama i Open WebUI

Ten projekt pozwala na uruchomienie w pełni funkcjonalnego, lokalnego asystenta AI za pomocą jednego skryptu. System automatycznie wykrywa dostępny sprzęt (NVIDIA, AMD, Intel GPU lub CPU) i konfiguruje środowisko w kontenerach Docker, aby zapewnić maksymalną wydajność.

## Architektura
System składa się z dwóch głównych kontenerów zarządzanych przez Docker Compose:
1.  **`ollama`**: Backend AI serwujący modele językowe.
2.  **`open-webui`**: Nowoczesny, graficzny interfejs użytkownika do interakcji z modelami.

## Wymagania Wstępne
Przed uruchomieniem upewnij się, że masz zainstalowane:
- **Git**
- **Docker** i **Docker Compose**
- **Dla Windows:** Docker Desktop ze skonfigurowaną i działającą integracją z **WSL 2**.
- **Dla akceleracji GPU:**
    - **NVIDIA:** Aktualne sterowniki i NVIDIA Container Toolkit i NVIDIA CUDA.
    - **AMD:** Aktualne sterowniki z obsługą ROCm.
    - **Intel:** Aktualne sterowniki i biblioteki oneAPI/Level Zero.

## Instalacja i Konfiguracja
1.  **Sklonuj repozytorium:**
    ```bash
    git clone https://github.com/Projektautomatyzacja/Projekt.git
    cd Projekt
    ```

2.  **Skonfiguruj modele AI (plik `.env`)**
    Został stworzony plik `.env.example`. Skrypt startowy automatycznie utworzy z niego plik `.env` przy pierwszym uruchomieniu. Możesz edytować plik `.env`, aby zdefiniować, które modele Ollama mają zostać pobrane. Modele oddzielaj przecinkami.
    
    *Przykład zawartości pliku `backend/.env`:*
    ```
    OLLAMA_MODELS=llama3.2:3b,gemma:4b,deepseer-r1:7b,dolphincoder:7b
    ```
    Listę dostępnych modeli znajdziesz na `https://ollama.com/library`.

3.  **Nadaj uprawnienia skryptom (Tylko Linux)**
    Po sklonowaniu repozytorium, nadaj uprawnienia do uruchamiania wszystkim skryptom za pomocą naszej przygotowanej komendy:
    ```bash
    ./fix-permissions.sh
    ```
    *(Ta komenda wykonuje `chmod +x` na wszystkich plikach `.sh` w projekcie. By skrypt zadziałał należy wpisać:
    ```bash
    chmod +x *.sh
    ```
    w głownym folderze programu).*

## Uruchomienie Projektu

Wszystkie komendy należy uruchamiać z **głównego folderu projektu (`Projekt/`)**.

#### Na Linuksie
Użyj skryptu `launch.sh`, który znajduje się w folderze `backend`.

* **Automatyczne wykrywanie GPU:**
    ```bash
    ./backend/launch.sh -d
    ```
* **Przebudowanie obrazów Docker (jeśli wprowadziłeś zmiany w kodzie):**
    ```bash
    ./backend/launch.sh --build -d
    ```
* **Wymuszenie konkretnego trybu:**
    ```bash
    ./backend/launch.sh --nvidia -d
    ./backend/launch.sh --amd -d
    ./backend/launch.sh --intel -d
    ./backend/launch.sh --cpu -d
    ```

#### Na Windows
Użyj skryptu `start.bat`, który znajduje się w folderze `backend`. Uruchom go z terminala PowerShell lub cmd.

* **Automatyczne wykrywanie GPU:**
    ```dos
    .\backend\start.bat -d
    ```
* **Wymuszenie konkretnego trybu:**
    ```dos
    .\backend\start.bat --nvidia -d
    .\backend\start.bat --cpu -d
    ```
    
## Wyłączanie Projektu

#### Wyłączenie bez usuwania kontenerów (nie usuwa użytkowników i historii czatów)
    
    docker compose down
    
    
#### Wyłączanie wraz z usunięciem kontenerów (usuwa użytkowników i historię czatów)
    
    docker compose down -v

#### Zatrzymanie pracy calego projektu, bez konieczności pobierania modeli od nowa przy ponownym uruchomieniu

    docker compose stop
    
    

## Dostęp do Aplikacji

* **Interfejs Graficzny (Open WebUI):** Otwórz przeglądarkę i wejdź na `http://localhost:3000`. Aby skorzystać na innym urządzeniu w sieci lokalnej, należy wejść na `http://<ip hosta>:3000`
* **API serwera Ollama:** Jest dostępne pod adresem `http://localhost:11434` (do użytku programistycznego).

## Dodatkowe Skrypty

W projekcie znajdują się dodatkowe skrypty pomocnicze:

* **`fix-permissions.sh`**: Nadaje uprawnienia do uruchamiania wszystkim skryptom `.sh`. Użyj go raz po sklonowaniu repozytorium na Linuksie/macOS.
* **`test_wydajnosci.sh`**: Uruchamia test wydajności, symulując długą rozmowę i mierząc czas odpowiedzi. Wymaga zainstalowanego `jq`.

## Rozwiązywanie Problemów (Troubleshooting)

1.  **Błąd `permission denied` przy uruchamianiu `.sh`:** Uruchom skrypt `./fix-permissions.sh`.
2.  **Błąd `address already in use`:** Oznacza, że port `3000` lub `11434` jest zajęty. Sprawdź, czy nie masz uruchomionej innej instancji projektu lub natywnej aplikacji Ollama.
3.  **Problem z GPU:** Jeśli `docker-compose` nie widzi GPU, użyj flagi `--docker-run` w skrypcie `launch.sh`, aby użyć obejścia opartego na `docker run`. Przykład: `./backend/launch.sh --nvidia --docker-run -d`.

## Wymagania systemowe

#### Minimalne
- OS: Linux typu Mint XFCE Edition
- CPU: Jakikolwiek z obsługą instrukcji AVX2
- RAM: 8GB (testy wykazały, że jest mozliwe odpalenie calego projektu na 4GB, jednakże wtedy jest jedynie możliwy do użycia mały model mniejszy lub równy 1b przy wspieranym GPU)
- GPU: Nie jest wymagane, jednakże wystarczy jakiekolwiek, które wspiera sterowniki Nvidia CUDA/AMD ROCm najlepiej z 2GB VRAM lub więcej

#### Rekomendowane
- OS: Windows 10/11 lub nowszy z WSL2 / Linux (jakikolwiek na którym zadziałają wymagane sterowniki i programy)
- CPU: x86 z obsługą instrukcji AVX2. W trybie CPU im więcej rdzeni i im szybsze taktowanie tym lepiej.
- RAM: 32GB DDR5
- GPU: Im więcej VRAM tym lepiej, byle by wspierały NVIDIA CUDA/ AMD ROCm