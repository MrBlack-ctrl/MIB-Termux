#!/bin/bash

# =============================================================================
# Termux Python Development Manager
# Zentrales Verwaltungsmenü für Python-Entwicklung in Termux
# Author: Mr.Black
# Version: 1.0
# =============================================================================

# Farbdefinitionen für ANSI-Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Standardverzeichnis für Python-Skripte
PYTHON_DIR="/sdcard/py"

# Mapping für Module mit unterschiedlichen Pip-Namen
declare -A MODULE_MAPPING=(
    ["cv2"]="opencv-python"
    ["PIL"]="Pillow"
    ["Pillow"]="Pillow"
    ["sklearn"]="scikit-learn"
    ["cv"]="opencv-python"
    ["tensorflow"]="tensorflow"
    ["torch"]="torch"
    ["tf"]="tensorflow"
    ["np"]="numpy"
    ["pd"]="pandas"
    ["plt"]="matplotlib"
    ["sns"]="seaborn"
)

# =============================================================================
# Hilfsfunktionen
# =============================================================================

# Funktion zur Anzeige von Header-Informationen
show_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}           MIB-Termux v1.0${NC}${CYAN}           ║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════╣${NC}"
    
    # Akkustand anzeigen
    if command -v termux-battery-status &> /dev/null; then
        BATTERY_INFO=$(termux-battery-status 2>/dev/null | grep -o '"percentage":[^,]*' | cut -d':' -f2 | tr -d '"' 2>/dev/null)
        if [ ! -z "$BATTERY_INFO" ]; then
            echo -e "${CYAN}║${GREEN} Akku: ${BATTERY_INFO}%${NC}${CYAN}                                              ║${NC}"
        else
            echo -e "${CYAN}║${GRAY} Akku: Nicht verfügbar${NC}${CYAN}                                      ║${NC}"
        fi
    else
        echo -e "${CYAN}║${GRAY} Akku: termux-battery-status nicht installiert${NC}${CYAN}               ║${NC}"
    fi
    
    # Python-Version anzeigen
    if command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1)
        echo -e "${CYAN}║${GREEN} Python: $PYTHON_VERSION${NC}${CYAN}                                   ║${NC}"
    else
        echo -e "${CYAN}║${RED} Python: Nicht installiert${NC}${CYAN}                                ║${NC}"
    fi
    
    # Arbeitsverzeichnis anzeigen
    echo -e "${CYAN}║${BLUE} Arbeitsverzeichnis: $PYTHON_DIR${NC}${CYAN}                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════╝${NC}"
    echo ""
}

# Funktion zur Überprüfung und Installation von Paketen
check_and_install_package() {
    local package=$1
    local description=$2
    
    echo -e "${YELLOW}Prüfe $description...${NC}"
    
    if ! pkg list-installed | grep -q "^$package/"; then
        echo -e "${RED}$description nicht gefunden. Installiere...${NC}"
        pkg update -y && pkg install -y $package
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$description erfolgreich installiert.${NC}"
        else
            echo -e "${RED}Fehler bei der Installation von $description.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}$description ist bereits installiert.${NC}"
    fi
    return 0
}

# Funktion zum Setup der Umgebung
setup_environment() {
    echo -e "${BLUE}=== Umgebungseinrichtung ===${NC}"
    
    # Python und pip überprüfen/installieren
    check_and_install_package "python" "Python"
    check_and_install_package "clang" "Clang (für einige Python-Pakete)"
    check_and_install_package "libffi" "libffi"
    check_and_install_package "openssl" "OpenSSL"
    check_and_install_package "libjpeg-turbo" "libjpeg-turbo"
    check_and_install_package "zlib" "zlib"
    
    # termux-setup-storage durchführen
    if [ ! -d "/sdcard" ]; then
        echo -e "${YELLOW}Führe termux-setup-storage durch...${NC}"
        echo -e "${CYAN}Hinweis: Bitte erlaube den Speicherzugriff in der Popup-Meldung${NC}"
        termux-setup-storage
        
        # Warte kurz und prüfe erneut
        sleep 2
        if [ -d "/sdcard" ]; then
            echo -e "${GREEN}Speicherzugriff erfolgreich eingerichtet.${NC}"
        else
            echo -e "${RED}Fehler: /sdcard ist nicht verfügbar.${NC}"
            echo -e "${YELLOW}Bitte führe 'termux-setup-storage' manuell aus und erlaube den Zugriff.${NC}"
            echo -e "${YELLOW}Alternativ: Verwende ein anderes Verzeichnis (z.B. ~/py)${NC}"
            read -p "Alternatives Verzeichnis verwenden? (y/n): " use_alt
            if [[ "$use_alt" =~ ^[Yy]$ ]]; then
                PYTHON_DIR="$HOME/py"
                echo -e "${CYAN}Verwende alternatives Verzeichnis: $PYTHON_DIR${NC}"
            fi
        fi
    else
        echo -e "${GREEN}Speicherzugriff bereits eingerichtet.${NC}"
    fi
    
    # Python-Verzeichnis erstellen
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${YELLOW}Erstelle Python-Verzeichnis: $PYTHON_DIR${NC}"
        mkdir -p "$PYTHON_DIR"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Python-Verzeichnis erstellt.${NC}"
        else
            echo -e "${RED}Fehler beim Erstellen des Verzeichnisses.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}Python-Verzeichnis existiert bereits.${NC}"
    fi
    
    # Auto-Update durchführen
    echo -e "${YELLOW}Führe Auto-Update durch...${NC}"
    pkg update -y
    if command -v pip &> /dev/null; then
        pip install --upgrade pip 2>&1 | grep -v "WARNING"
        echo -e "${GREEN}pip aktualisiert.${NC}"
    else
        echo -e "${RED}pip nicht gefunden. Installiere Python erneut.${NC}"
    fi
    
    echo -e "${GREEN}Umgebungseinrichtung abgeschlossen.${NC}"
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Scannen von Python-Importen (optimiert)
scan_python_imports() {
    local file=$1
    
    # Validierung
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Verwende grep für schnelleres Scannen
    grep -E "^[[:space:]]*(import|from)[[:space:]]+" "$file" 2>/dev/null | \
        sed 's/#.*//' | \
        sed -n 's/^[[:space:]]*import[[:space:]]\+\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p; s/^[[:space:]]*from[[:space:]]\+\([a-zA-Z_][a-zA-Z0-9_]*\)[[:space:]]\+import.*/\1/p' | \
        sort -u
}

# Funktion zur Überprüfung und Installation von Python-Modulen
install_python_modules() {
    local file=$1
    
    # Validierung
    if [ ! -f "$file" ]; then
        echo -e "${RED}Fehler: Datei nicht gefunden: $file${NC}"
        return 1
    fi
    
    local script_name=$(basename "$file" .py)
    local cache_file="$PYTHON_DIR/.module_cache_${script_name}.txt"
    
    # Prüfe ob Cache existiert und aktueller als das Skript ist
    if [ -f "$cache_file" ] && [ "$cache_file" -nt "$file" ]; then
        echo -e "${GREEN}✓ Modul-Cache gefunden für $script_name.py - überspringe Scan${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Scanne Import-Module in $(basename "$file")...${NC}"
    
    local modules=($(scan_python_imports "$file"))
    
    if [ ${#modules[@]} -eq 0 ]; then
        echo -e "${GREEN}Keine Import-Module gefunden.${NC}"
        # Erstelle leeren Cache
        touch "$cache_file"
        return 0
    fi
    
    echo -e "${BLUE}=== Überprüfung der Python-Module (${#modules[@]} gefunden) ===${NC}"
    
    local installed_count=0
    local failed_count=0
    local new_modules=()
    
    for module in "${modules[@]}"; do
        # Standardbibliotheks-Module überspringen
        case "$module" in
            os|sys|time|datetime|math|random|json|csv|re|collections|itertools|functools|operator|pathlib|urllib|http|socket|threading|multiprocessing|subprocess|shutil|tempfile|glob|fnmatch|pickle|sqlite3|unittest|argparse|configparser|logging|email|xml|html|decimal|fractions|statistics|typing|dataclasses|enum|contextlib|io|string|struct|copy|weakref|gc|inspect|dis|importlib|pkgutil|warnings|traceback|types|builtins|__future__|abc|asyncio|base64|binascii|bisect|calendar|cmath|codecs|concurrent|crypt|ctypes|curses|dbm|difflib|distutils|errno|faulthandler|fcntl|filecmp|fileinput|formatter|getopt|getpass|gettext|grp|gzip|hashlib|heapq|hmac|imaplib|imp|ipaddress|keyword|linecache|locale|lzma|mailbox|mailcap|marshal|mimetypes|mmap|modulefinder|netrc|nis|nntplib|numbers|optparse|parser|pdb|pipes|platform|plistlib|poplib|posix|posixpath|pprint|profile|pstats|pty|pwd|py_compile|pyclbr|pydoc|queue|quopri|readline|reprlib|resource|rlcompleter|runpy|sched|secrets|select|selectors|shelve|signal|site|smtpd|smtplib|sndhdr|spwd|ssl|stat|stringprep|sunau|symbol|symtable|sysconfig|syslog|tabnanny|tarfile|telnetlib|termios|test|textwrap|this|token|tokenize|trace|tty|turtle|turtledemo|unicodedata|uu|uuid|venv|wave|webbrowser|wsgiref|xdrlib|zipapp|zipfile|zipimport|zlib)
                echo -e "${GRAY}• Überspringe Standardbibliothek: $module${NC}"
                continue
                ;;
        esac
        
        # Pip-Namen ermitteln
        pip_name="${MODULE_MAPPING[$module]:-$module}"
        
        # Überprüfen ob Modul installiert ist
        if python -c "import $module" 2>/dev/null; then
            echo -e "${GREEN}✓ $module ist bereits installiert${NC}"
            ((installed_count++))
        else
            echo -e "${YELLOW}→ Installiere $pip_name (für Import: $module)${NC}"
            
            # Versuche Installation mit Fehlerbehandlung
            if pip install "$pip_name" --quiet --disable-pip-version-check 2>&1 | grep -q "Successfully installed"; then
                echo -e "${GREEN}✓ $pip_name erfolgreich installiert${NC}"
                ((installed_count++))
                new_modules+=("$pip_name")
            else
                echo -e "${RED}✗ Fehler bei der Installation von $pip_name${NC}"
                ((failed_count++))
            fi
        fi
        
        # Kurze Pause um nicht zu viele Anfragen gleichzeitig zu senden
        sleep 0.1
    done
    
    # Erstelle Cache-Datei mit erfolgreich installierten Modulen
    if [ ${#new_modules[@]} -gt 0 ] || [ $installed_count -gt 0 ]; then
        printf '%s\n' "${new_modules[@]}" > "$cache_file"
        echo -e "${CYAN}✓ Cache erstellt für zukünftige Starts${NC}"
    else
        touch "$cache_file"
    fi
    
    echo -e "${CYAN}=== Modul-Installation abgeschlossen ===${NC}"
    echo -e "${GREEN}Erfolgreich: $installed_count Module${NC}"
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}Fehlgeschlagen: $failed_count Module${NC}"
        echo -e "${YELLOW}Hinweis: Manche Module benötigen zusätzliche Systemabhängigkeiten${NC}"
    fi
    
    return 0
}

# Funktion zum Löschen von Modul-Cache
clear_module_cache() {
    local script_name="$1"
    local cache_file="$PYTHON_DIR/.module_cache_${script_name}.txt"
    
    if [ -f "$cache_file" ]; then
        rm -f "$cache_file"
        echo -e "${YELLOW}Modul-Cache für $script_name.py gelöscht${NC}"
    fi
}

# Funktion zum Anzeigen der Python-Skripte
show_python_scripts() {
    echo -e "${BLUE}=== Verfügbare Python-Skripte ===${NC}"
    
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${RED}Verzeichnis $PYTHON_DIR existiert nicht.${NC}"
        return 1
    fi
    
    # Python-Dateien finden und nummerieren
    local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo -e "${YELLOW}Keine Python-Skripte in $PYTHON_DIR gefunden.${NC}"
        return 1
    fi
    
    echo -e "${WHITE}Nummer | Skriptname${NC}"
    echo -e "${GRAY}───────┼────────────────────────────────────────${NC}"
    
    for i in "${!scripts[@]}"; do
        script_name=$(basename "${scripts[$i]}")
        printf "${CYAN}%-6d │ ${WHITE}%s${NC}\n" $((i+1)) "$script_name"
    done
    
    echo ""
    return 0
}

# Funktion zum Ausführen eines Python-Skripts
execute_script() {
    show_python_scripts
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${YELLOW}Gib die Nummer des Skripts ein, das du ausführen möchtest (0 für Abbruch):${NC}"
    read -p "> " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    fi
    
    # Eingabe-Validierung
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
    local index=$((choice-1))
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#scripts[@]}" ]; then
        local selected_script="${scripts[$index]}"
        local script_name=$(basename "$selected_script")
        echo -e "${BLUE}Führe aus: $script_name${NC}"
        
        # Prüfe ob requirements.txt für dieses Skript existiert
        local req_file="$PYTHON_DIR/requirements_${script_name%.py}.txt"
        if [ -f "$req_file" ]; then
            echo -e "${YELLOW}Requirements.txt gefunden für $script_name${NC}"
            echo -e "${CYAN}Möchtest du die Abhängigkeiten installieren? (y/n)${NC}"
            read -p "> " install_req
            if [[ "$install_req" =~ ^[Yy]$ ]]; then
                install_requirements "$req_file"
            fi
        fi
        
        # Skript ausführen
        echo -e "${CYAN}=== Starte Skript: $script_name ===${NC}"
        cd "$PYTHON_DIR"
        
        python "$script_name"
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}✓ Skript erfolgreich ausgeführt${NC}"
        else
            echo -e "${RED}✗ Skript mit Exit-Code $exit_code beendet${NC}"
            echo -e "${YELLOW}Hinweis: Möglicherweise fehlende Module${NC}"
            echo -e "${CYAN}Tipp: Nutze Option 9 (Requirements.txt Generator) oder Option 10 (Requirements installieren)${NC}"
        fi
        
        echo -e "${CYAN}======================${NC}"
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Bearbeiten eines Python-Skripts
edit_script() {
    show_python_scripts
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${YELLOW}Gib die Nummer des Skripts ein, das du bearbeiten möchtest (0 für Abbruch):${NC}"
    read -p "> " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    fi
    
    # Eingabe-Validierung
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
    local index=$((choice-1))
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#scripts[@]}" ]; then
        local selected_script="${scripts[$index]}"
        local script_name=$(basename "$selected_script" .py)
        echo -e "${BLUE}Öffne zum Bearbeiten: $(basename "$selected_script")${NC}"
        
        # Backup erstellen
        local backup_file="${selected_script}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$selected_script" "$backup_file"
        echo -e "${GREEN}✓ Backup erstellt: $(basename "$backup_file")${NC}"
        
        # nano installieren falls nicht vorhanden
        if ! command -v nano &> /dev/null; then
            echo -e "${YELLOW}Installiere nano...${NC}"
            pkg install -y nano
        fi
        
        nano "$selected_script"
        
        # Nach dem Bearbeiten: Cache löschen damit Module neu gescannt werden
        clear_module_cache "$script_name"
        echo -e "${CYAN}Modul-Cache wurde gelöscht. Module werden beim nächsten Start neu gescannt.${NC}"
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Erstellen eines neuen Python-Skripts
create_script() {
    echo -e "${YELLOW}Gib den Namen für das neue Python-Skript ein (ohne .py Erweiterung):${NC}"
    read -p "> " script_name
    
    # Validierung
    if [ -z "$script_name" ]; then
        echo -e "${RED}Leerer Name ist nicht erlaubt.${NC}"
        return 1
    fi
    
    # Entferne ungültige Zeichen
    script_name=$(echo "$script_name" | tr -cd '[:alnum:]_-')
    
    if [ -z "$script_name" ]; then
        echo -e "${RED}Ungültiger Name. Verwende nur Buchstaben, Zahlen, _ und -${NC}"
        return 1
    fi
    
    local script_path="$PYTHON_DIR/${script_name}.py"
    
    if [ -f "$script_path" ]; then
        echo -e "${RED}Skript $script_name.py existiert bereits.${NC}"
        echo -e "${YELLOW}Möchtest du es trotzdem öffnen? (y/n)${NC}"
        read -p "> " open_existing
        if [[ "$open_existing" =~ ^[Yy]$ ]]; then
            nano "$script_path"
        fi
        return 1
    fi
    
    # nano installieren falls nicht vorhanden
    if ! command -v nano &> /dev/null; then
        echo -e "${YELLOW}Installiere nano...${NC}"
        pkg install -y nano
    fi
    
    # Vorlage erstellen
    cat > "$script_path" << EOF
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Beschreibung des Skripts
Autor: Dein Name
Datum: $(date +%d.%m.%Y)
"""

def main():
    """Hauptfunktion des Skripts"""
    print("Hallo Welt!")

if __name__ == "__main__":
    main()
EOF

    echo -e "${GREEN}Skript $script_name.py wurde erstellt.${NC}"
    echo -e "${BLUE}Öffne zum Bearbeiten...${NC}"
    nano "$script_path"
}

# Funktion zum Löschen von pycache
clean_pycache() {
    echo -e "${BLUE}=== Lösche __pycache__ Verzeichnisse ===${NC}"
    
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${RED}Verzeichnis $PYTHON_DIR existiert nicht.${NC}"
        return 1
    fi
    
    local cache_dirs=$(find "$PYTHON_DIR" -name "__pycache__" -type d 2>/dev/null)
    
    if [ -z "$cache_dirs" ]; then
        echo -e "${GREEN}Keine __pycache__ Verzeichnisse gefunden.${NC}"
    else
        echo "$cache_dirs" | while read -r dir; do
            echo -e "${YELLOW}Lösche: $dir${NC}"
            rm -rf "$dir"
        done
        echo -e "${GREEN}Alle __pycache__ Verzeichnisse wurden gelöscht.${NC}"
    fi
    
    # .pyc Dateien löschen
    local pyc_files=$(find "$PYTHON_DIR" -name "*.pyc" -type f 2>/dev/null)
    if [ ! -z "$pyc_files" ]; then
        echo "$pyc_files" | while read -r file; do
            echo -e "${YELLOW}Lösche: $file${NC}"
            rm -f "$file"
        done
    fi
    
    # Alte Backups bereinigen (älter als 7 Tage)
    echo -e "${CYAN}Prüfe auf alte Backup-Dateien...${NC}"
    local old_backups=$(find "$PYTHON_DIR" -name "*.backup.*" -type f -mtime +7 2>/dev/null)
    if [ ! -z "$old_backups" ]; then
        local backup_count=$(echo "$old_backups" | wc -l)
        echo -e "${YELLOW}Gefunden: $backup_count alte Backup-Dateien (älter als 7 Tage)${NC}"
        echo -e "${YELLOW}Möchtest du diese löschen? (y/n)${NC}"
        read -p "> " delete_backups
        if [[ "$delete_backups" =~ ^[Yy]$ ]]; then
            echo "$old_backups" | while read -r file; do
                echo -e "${YELLOW}Lösche: $(basename "$file")${NC}"
                rm -f "$file"
            done
            echo -e "${GREEN}Alte Backups wurden gelöscht.${NC}"
        fi
    else
        echo -e "${GREEN}Keine alten Backup-Dateien gefunden.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Installieren von requirements.txt
install_requirements() {
    local req_file="$1"
    
    if [ ! -f "$req_file" ]; then
        echo -e "${RED}Requirements-Datei nicht gefunden: $req_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Installiere Pakete aus $req_file...${NC}"
    
    while IFS= read -r line; do
        # Überspringe Kommentare und leere Zeilen
        if [[ "$line" =~ ^[[:space:]]*# ]] || [ -z "$line" ]; then
            continue
        fi
        
        # Entferne Versionsspezifikationen (>=, ==, etc.)
        package=$(echo "$line" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'!' -f1 | tr -d ' ')
        
        if [ ! -z "$package" ]; then
            echo -e "${YELLOW}Installiere $package...${NC}"
            pip install "$line" 2>/dev/null || {
                echo -e "${RED}Fehler bei der Installation von $package${NC}"
            }
        fi
    done < "$req_file"
    
    echo -e "${GREEN}Installation aus requirements.txt abgeschlossen.${NC}"
}

# Funktion zum Öffnen der Shell
open_shell() {
    echo -e "${BLUE}Öffne Shell im Verzeichnis: $PYTHON_DIR${NC}"
    cd "$PYTHON_DIR"
    echo -e "${GREEN}Du bist jetzt in der Shell. Verwende 'exit' um zum Menü zurückzukehren.${NC}"
    bash
}

# Funktion für Git-Integration
git_manager() {
    echo -e "${BLUE}=== Git Manager ===${NC}"
    
    # Prüfen ob Git installiert ist
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git ist nicht installiert. Installiere...${NC}"
        pkg update -y && pkg install -y git
        if [ $? -ne 0 ]; then
            echo -e "${RED}Git-Installation fehlgeschlagen.${NC}"
            return 1
        fi
        echo -e "${GREEN}Git erfolgreich installiert.${NC}"
    fi
    
    while true; do
        echo -e "${BOLD}${WHITE}Git Manager Optionen:${NC}"
        echo -e "${CYAN}1.${NC} Repository initialisieren"
        echo -e "${CYAN}2.${NC} Status anzeigen"
        echo -e "${CYAN}3.${NC} Änderungen hinzufügen (add all)"
        echo -e "${CYAN}4.${NC} Commit erstellen"
        echo -e "${CYAN}5.${NC} Remote hinzufügen"
        echo -e "${CYAN}6.${NC} Push zu Remote"
        echo -e "${CYAN}7.${NC} Pull von Remote"
        echo -e "${CYAN}8.${NC} Branch wechseln/erstellen"
        echo -e "${CYAN}9.${NC} Log anzeigen"
        echo -e "${CYAN}0.${NC} Zurück zum Hauptmenü"
        echo ""
        echo -e "${YELLOW}Wähle eine Option:${NC}"
        read -p "> " git_choice
        
        case $git_choice in
            1)
                echo -e "${YELLOW}Repository initialisieren? (y/n):${NC}"
                read -p "> " init_confirm
                if [[ "$init_confirm" =~ ^[Yy]$ ]]; then
                    cd "$PYTHON_DIR"
                    git init
                    echo -e "${GREEN}Repository initialisiert.${NC}"
                fi
                ;;
            2)
                cd "$PYTHON_DIR"
                git status
                ;;
            3)
                cd "$PYTHON_DIR"
                git add .
                echo -e "${GREEN}Alle Änderungen hinzugefügt.${NC}"
                ;;
            4)
                cd "$PYTHON_DIR"
                echo -e "${YELLOW}Commit-Nachricht eingeben:${NC}"
                read -p "> " commit_msg
                if [ ! -z "$commit_msg" ]; then
                    git commit -m "$commit_msg"
                else
                    git commit -m "Update $(date +%Y-%m-%d_%H:%M:%S)"
                fi
                ;;
            5)
                echo -e "${YELLOW}Remote-URL eingeben (z.B. https://github.com/user/repo.git):${NC}"
                read -p "> " remote_url
                if [ ! -z "$remote_url" ]; then
                    cd "$PYTHON_DIR"
                    git remote add origin "$remote_url"
                    echo -e "${GREEN}Remote hinzugefügt.${NC}"
                fi
                ;;
            6)
                cd "$PYTHON_DIR"
                echo -e "${YELLOW}Branch zum Pushen (default: main):${NC}"
                read -p "> " push_branch
                push_branch=${push_branch:-main}
                git push origin "$push_branch"
                ;;
            7)
                cd "$PYTHON_DIR"
                echo -e "${YELLOW}Branch zum Pullen (default: main):${NC}"
                read -p "> " pull_branch
                pull_branch=${pull_branch:-main}
                git pull origin "$pull_branch"
                ;;
            8)
                echo -e "${YELLOW}Branch-Name eingeben (leer für neuen Branch):${NC}"
                read -p "> " branch_name
                if [ ! -z "$branch_name" ]; then
                    cd "$PYTHON_DIR"
                    git checkout "$branch_name" 2>/dev/null || git checkout -b "$branch_name"
                    echo -e "${GREEN}Branch gewechselt/erstellt: $branch_name${NC}"
                fi
                ;;
            9)
                cd "$PYTHON_DIR"
                echo -e "${YELLOW}Anzahl der Commits (default: 10):${NC}"
                read -p "> " log_count
                log_count=${log_count:-10}
                git log --oneline -n "$log_count"
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl.${NC}"
                ;;
        esac
        
        if [ "$git_choice" != "0" ]; then
            echo ""
            read -p "Drücke Enter um fortzufahren..."
        fi
    done
}

# Funktion für Requirements.txt Generator
generate_requirements() {
    echo -e "${BLUE}=== Requirements.txt Generator ===${NC}"
    
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${RED}Verzeichnis $PYTHON_DIR existiert nicht.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Wähle eine Option:${NC}"
    echo -e "${CYAN}1.${NC} Requirements aus allen Python-Dateien generieren"
    echo -e "${CYAN}2.${NC} Requirements aus spezifischer Datei generieren"
    echo -e "${CYAN}3.${NC} Installierte Pakete auflisten (pip freeze)"
    echo -e "${CYAN}0.${NC} Zurück zum Hauptmenü"
    read -p "> " req_choice
    
    # Eingabe-Validierung
    if ! [[ "$req_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    case $req_choice in
        1)
            echo -e "${YELLOW}Scanne alle Python-Dateien...${NC}"
            local all_modules=()
            local py_files=($(find "$PYTHON_DIR" -name "*.py" -type f))
            local total_files=${#py_files[@]}
            local current_file=0
            
            echo -e "${BLUE}Verarbeite $total_files Dateien...${NC}"
            
            for file in "${py_files[@]}"; do
                ((current_file++))
                echo -ne "\r${CYAN}Datei $current_file/$total_files: $(basename "$file")${NC}"
                
                # Schnelles Scannen mit grep statt vollständiger Funktion
                local file_modules=($(grep -h "^import\|^from.*import" "$file" 2>/dev/null | \
                    sed 's/from[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
                    sed 's/import[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
                    sed 's/ as .*//' | \
                    sort -u))
                
                all_modules+=("${file_modules[@]}")
            done
            echo ""
            
            # Duplikate entfernen und sortieren
            local unique_modules=($(printf '%s\n' "${all_modules[@]}" | sort -u))
            
            if [ ${#unique_modules[@]} -eq 0 ]; then
                echo -e "${YELLOW}Keine Module gefunden.${NC}"
                return 0
            fi
            
            echo -e "${GREEN}Gefundene Module: ${#unique_modules[@]}${NC}"
            local requirements_file="$PYTHON_DIR/requirements.txt"
            > "$requirements_file"
            
            # Schnelle Filterung mit Array
            local std_libs=(os sys time datetime math random json csv re collections itertools functools operator pathlib urllib http socket threading multiprocessing subprocess shutil tempfile glob fnmatch pickle sqlite3 unittest argparse configparser logging email xml html decimal fractions statistics typing dataclasses enum contextlib io string struct copy weakref gc inspect dis importlib pkgutil warnings traceback types builtins __future__)
            
            for module in "${unique_modules[@]}"; do
                # Schnelle Prüfung ob in Standardbibliothek
                local is_std=0
                for std in "${std_libs[@]}"; do
                    if [ "$module" = "$std" ]; then
                        is_std=1
                        break
                    fi
                done
                
                if [ $is_std -eq 0 ]; then
                    local pip_name="${MODULE_MAPPING[$module]:-$module}"
                    echo "$pip_name" >> "$requirements_file"
                    echo -e "${GREEN}+ $pip_name${NC}"
                fi
            done
            
            echo -e "${GREEN}Requirements.txt wurde erstellt: $requirements_file${NC}"
            ;;
        2)
            show_python_scripts
            if [ $? -ne 0 ]; then
                return 1
            fi
            
            echo -e "${YELLOW}Gib die Nummer der Datei ein (0 für Abbruch):${NC}"
            read -p "> " index
            if [ "$index" -eq 0 ] 2>/dev/null; then
                echo -e "${GRAY}Abgebrochen.${NC}"
                return 0
            fi
            
            local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
            local selected_index=$((index-1))
            
            if [ "$selected_index" -ge 0 ] && [ "$selected_index" -lt "${#scripts[@]}" ]; then
                local selected_file="${scripts[$selected_index]}"
                echo -e "${BLUE}Scanne $(basename "$selected_file")...${NC}"
                
                # Schnelles Scannen mit grep
                local modules=($(grep -h "^import\|^from.*import" "$selected_file" 2>/dev/null | \
                    sed 's/from[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
                    sed 's/import[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
                    sed 's/ as .*//' | \
                    sort -u))
                
                if [ ${#modules[@]} -eq 0 ]; then
                    echo -e "${YELLOW}Keine Module gefunden.${NC}"
                    return 0
                fi
                
                local requirements_file="$PYTHON_DIR/requirements_$(basename "$selected_file" .py).txt"
                > "$requirements_file"
                
                # Schnelle Filterung mit Array
                local std_libs=(os sys time datetime math random json csv re collections itertools functools operator pathlib urllib http socket threading multiprocessing subprocess shutil tempfile glob fnmatch pickle sqlite3 unittest argparse configparser logging email xml html decimal fractions statistics typing dataclasses enum contextlib io string struct copy weakref gc inspect dis importlib pkgutil warnings traceback types builtins __future__)
                
                for module in "${modules[@]}"; do
                    # Schnelle Prüfung ob in Standardbibliothek
                    local is_std=0
                    for std in "${std_libs[@]}"; do
                        if [ "$module" = "$std" ]; then
                            is_std=1
                            break
                        fi
                    done
                    
                    if [ $is_std -eq 0 ]; then
                        local pip_name="${MODULE_MAPPING[$module]:-$module}"
                        echo "$pip_name" >> "$requirements_file"
                        echo -e "${GREEN}+ $pip_name${NC}"
                    fi
                done
                
                echo -e "${GREEN}Requirements erstellt: $requirements_file${NC}"
            else
                echo -e "${RED}Ungültige Auswahl.${NC}"
            fi
            ;;
        3)
            echo -e "${BLUE}=== Installierte Pakete (pip freeze) ===${NC}"
            if command -v pip &> /dev/null; then
                pip freeze
                echo -e "${GREEN}Möchtest du dies in requirements.txt speichern? (y/n)${NC}"
                read -p "> " save_choice
                if [[ "$save_choice" =~ ^[Yy]$ ]]; then
                    pip freeze > "$PYTHON_DIR/requirements_freeze.txt"
                    echo -e "${GREEN}Gespeichert als: $PYTHON_DIR/requirements_freeze.txt${NC}"
                fi
            else
                echo -e "${RED}pip ist nicht installiert.${NC}"
            fi
            ;;
        0)
            return 0
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion für Package-Manager
package_manager() {
    echo -e "${BLUE}=== Package Manager ===${NC}"
    
    while true; do
        echo -e "${BOLD}${WHITE}Package Manager Optionen:${NC}"
        echo -e "${CYAN}1.${NC} Installierte Python-Pakete auflisten"
        echo -e "${CYAN}2.${NC} Python-Paket installieren (pip)"
        echo -e "${CYAN}3.${NC} Python-Paket deinstallieren (pip)"
        echo -e "${CYAN}4.${NC} Python-Paket-Informationen anzeigen"
        echo -e "${CYAN}5.${NC} Veraltete Python-Pakete auflisten"
        echo -e "${CYAN}6.${NC} Alle Python-Pakete aktualisieren"
        echo -e "${CYAN}7.${NC} Termux-Paket installieren (pkg)"
        echo -e "${CYAN}8.${NC} Python-Modul direkt installieren (Modulname)"
        echo -e "${CYAN}0.${NC} Zurück zum Hauptmenü"
        echo ""
        echo -e "${YELLOW}Wähle eine Option:${NC}"
        read -p "> " pkg_choice
        
        # Eingabe-Validierung
        if ! [[ "$pkg_choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
            read -p "Drücke Enter um fortzufahren..."
            continue
        fi
        
        case $pkg_choice in
            1)
                echo -e "${BLUE}=== Installierte Python-Pakete ===${NC}"
                if command -v pip &> /dev/null; then
                    pip list
                else
                    echo -e "${RED}pip ist nicht installiert.${NC}"
                fi
                ;;
            2)
                echo -e "${YELLOW}Gib den Python-Paketnamen ein (z.B. requests, numpy):${NC}"
                read -p "> " install_pkg
                if [ -z "$install_pkg" ]; then
                    echo -e "${RED}Kein Paketname eingegeben.${NC}"
                else
                    echo -e "${BLUE}Installiere $install_pkg...${NC}"
                    pip install "$install_pkg"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ $install_pkg erfolgreich installiert${NC}"
                    else
                        echo -e "${RED}✗ Fehler bei der Installation von $install_pkg${NC}"
                    fi
                fi
                ;;
            3)
                echo -e "${YELLOW}Gib den Python-Paketnamen zum Deinstallieren ein:${NC}"
                read -p "> " uninstall_pkg
                if [ -z "$uninstall_pkg" ]; then
                    echo -e "${RED}Kein Paketname eingegeben.${NC}"
                else
                    echo -e "${BLUE}Deinstalliere $uninstall_pkg...${NC}"
                    pip uninstall -y "$uninstall_pkg"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ $uninstall_pkg erfolgreich deinstalliert${NC}"
                    else
                        echo -e "${RED}✗ Fehler bei der Deinstallation von $uninstall_pkg${NC}"
                    fi
                fi
                ;;
            4)
                echo -e "${YELLOW}Gib den Python-Paketnamen für Informationen ein:${NC}"
                read -p "> " info_pkg
                if [ -z "$info_pkg" ]; then
                    echo -e "${RED}Kein Paketname eingegeben.${NC}"
                else
                    echo -e "${BLUE}=== Informationen zu $info_pkg ===${NC}"
                    pip show "$info_pkg"
                fi
                ;;
            5)
                echo -e "${BLUE}=== Veraltete Python-Pakete ===${NC}"
                pip list --outdated
                ;;
            6)
                echo -e "${YELLOW}Alle Python-Pakete aktualisieren? Dies kann dauern (y/n):${NC}"
                read -p "> " update_all
                if [[ "$update_all" =~ ^[Yy]$ ]]; then
                    echo -e "${BLUE}Aktualisiere alle Pakete...${NC}"
                    local outdated_packages=$(pip list --outdated --format=freeze | grep -v '^-e' | cut -d = -f 1)
                    if [ ! -z "$outdated_packages" ]; then
                        echo "$outdated_packages" | while read -r package; do
                            if [ ! -z "$package" ]; then
                                echo -e "${YELLOW}Aktualisiere $package...${NC}"
                                pip install -U "$package"
                            fi
                        done
                        echo -e "${GREEN}✓ Alle Pakete aktualisiert${NC}"
                    else
                        echo -e "${GREEN}Alle Pakete sind aktuell.${NC}"
                    fi
                fi
                ;;
            7)
                echo -e "${YELLOW}Gib den Termux-Paketnamen ein (z.B. git, nano, clang):${NC}"
                read -p "> " pkg_name
                if [ -z "$pkg_name" ]; then
                    echo -e "${RED}Kein Paketname eingegeben.${NC}"
                else
                    echo -e "${BLUE}Installiere Termux-Paket: $pkg_name...${NC}"
                    pkg install -y "$pkg_name"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ $pkg_name erfolgreich installiert${NC}"
                    else
                        echo -e "${RED}✗ Fehler bei der Installation von $pkg_name${NC}"
                    fi
                fi
                ;;
            8)
                echo -e "${YELLOW}Gib den Python-Modulnamen ein (z.B. cv2, PIL, sklearn):${NC}"
                read -p "> " module_name
                if [ -z "$module_name" ]; then
                    echo -e "${RED}Kein Modulname eingegeben.${NC}"
                else
                    # Prüfe ob Modul bereits installiert ist
                    if python -c "import $module_name" 2>/dev/null; then
                        echo -e "${GREEN}✓ Modul $module_name ist bereits installiert${NC}"
                    else
                        # Verwende Mapping falls vorhanden
                        local pip_name="${MODULE_MAPPING[$module_name]:-$module_name}"
                        echo -e "${BLUE}Installiere $pip_name (für Modul: $module_name)...${NC}"
                        pip install "$pip_name"
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}✓ $pip_name erfolgreich installiert${NC}"
                            # Verifiziere Installation
                            if python -c "import $module_name" 2>/dev/null; then
                                echo -e "${GREEN}✓ Modul $module_name kann jetzt importiert werden${NC}"
                            else
                                echo -e "${YELLOW}⚠ Paket installiert, aber Modul $module_name kann nicht importiert werden${NC}"
                            fi
                        else
                            echo -e "${RED}✗ Fehler bei der Installation von $pip_name${NC}"
                        fi
                    fi
                fi
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl.${NC}"
                ;;
        esac
        
        if [ "$pkg_choice" != "0" ]; then
            echo ""
            read -p "Drücke Enter um fortzufahren..."
        fi
    done
}

# Funktion für Performance-Monitoring
performance_monitor() {
    echo -e "${BLUE}=== Performance Monitor ===${NC}"
    
    show_python_scripts
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${YELLOW}Gib die Nummer des Skripts ein für Performance-Analyse (0 für Abbruch):${NC}"
    read -p "> " perf_choice
    
    if [ "$perf_choice" -eq 0 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    fi
    
    # Eingabe-Validierung
    if ! [[ "$perf_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
    local index=$((perf_choice-1))
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#scripts[@]}" ]; then
        local selected_script="${scripts[$index]}"
        echo -e "${BLUE}Performance-Analyse für: $(basename "$selected_script")${NC}"
        
        echo -e "${CYAN}=== Performance-Messung ===${NC}"
        echo -e "${YELLOW}Starte Zeitmessung...${NC}"
        
        # Zeitmessung mit time
        cd "$PYTHON_DIR"
        
        # Erstelle ein temporäres Skript für detaillierte Analyse
        local temp_script="/tmp/perf_analysis_$$.py"
        cat > "$temp_script" << EOF
import time
import tracemalloc
import sys
import os

# Starte Speicher-Tracking
tracemalloc.start()
start_time = time.time()

try:
    # Führe das eigentliche Skript aus
    exec(open('$selected_script').read())
except Exception as e:
    print(f"Fehler bei der Ausführung: {e}")
    sys.exit(1)

# Ende der Messung
end_time = time.time()
current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()

print("\n" + "="*50)
print("=== PERFORMANCE-ANALYSE ===")
print(f"Laufzeit: {end_time - start_time:.4f} Sekunden")
print(f"Speichernutzung: {current / 1024 / 1024:.2f} MB (Peak: {peak / 1024 / 1024:.2f} MB)")
print("="*50)
EOF
        
        python "$temp_script"
        rm -f "$temp_script"
        
        echo -e "${CYAN}=== System-Informationen ===${NC}"
        
        # CPU-Info (falls verfügbar)
        if [ -f /proc/cpuinfo ]; then
            local cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
            echo -e "${GREEN}CPU-Kerne: $cpu_cores${NC}"
        fi
        
        # Speicher-Info
        if command -v free &> /dev/null; then
            echo -e "${GREEN}System-Speicher:${NC}"
            free -h
        fi
        
        # Python-Version und Info
        echo -e "${GREEN}Python-Info:${NC}"
        python --version
        python -c "import sys; print(f'Implementation: {sys.implementation.name}'); print(f'Pfad: {sys.executable}')"
        
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Installieren von requirements.txt
install_requirements_menu() {
    echo -e "${BLUE}=== Requirements.txt installieren ===${NC}"
    
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${RED}Verzeichnis $PYTHON_DIR existiert nicht.${NC}"
        return 1
    fi
    
    # Suche nach requirements.txt Dateien
    local req_files=($(find "$PYTHON_DIR" -name "requirements*.txt" -type f 2>/dev/null))
    
    if [ ${#req_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Keine requirements.txt Dateien gefunden.${NC}"
        echo -e "${CYAN}Möchtest du eine requirements.txt Datei erstellen? (y/n)${NC}"
        read -p "> " create_req
        if [[ "$create_req" =~ ^[Yy]$ ]]; then
            generate_requirements
        fi
        return 0
    fi
    
    echo -e "${WHITE}Gefundene requirements.txt Dateien:${NC}"
    echo -e "${GRAY}Nummer | Dateiname${NC}"
    echo -e "${GRAY}───────┼────────────────────────────────────────${NC}"
    
    for i in "${!req_files[@]}"; do
        local filename=$(basename "${req_files[$i]}")
        printf "${CYAN}%-6d │ ${WHITE}%s${NC}\n" $((i+1)) "$filename"
    done
    
    echo ""
    echo -e "${YELLOW}Gib die Nummer der requirements.txt Datei ein (0 für Abbruch):${NC}"
    read -p "> " req_choice
    
    if [ "$req_choice" -eq 0 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    fi
    
    # Eingabe-Validierung
    if ! [[ "$req_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    local index=$((req_choice-1))
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#req_files[@]}" ]; then
        local selected_req="${req_files[$index]}"
        echo -e "${BLUE}Installiere aus: $(basename "$selected_req")${NC}"
        
        # Zeige Inhalt der Datei
        echo -e "${CYAN}=== Inhalt der requirements.txt ===${NC}"
        cat "$selected_req"
        echo -e "${CYAN}================================${NC}"
        
        echo -e "${YELLOW}Möchtest du diese Pakete installieren? (y/n)${NC}"
        read -p "> " confirm_install
        
        if [[ "$confirm_install" =~ ^[Yy]$ ]]; then
            install_requirements "$selected_req"
        else
            echo -e "${GRAY}Installation abgebrochen.${NC}"
        fi
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Löschen von Modul-Cache
clear_module_cache_menu() {
    echo -e "${BLUE}=== Modul-Cache löschen ===${NC}"
    
    if [ ! -d "$PYTHON_DIR" ]; then
        echo -e "${RED}Verzeichnis $PYTHON_DIR existiert nicht.${NC}"
        return 1
    fi
    
    # Suche nach Cache-Dateien
    local cache_files=($(find "$PYTHON_DIR" -name ".module_cache_*.txt" -type f 2>/dev/null))
    
    if [ ${#cache_files[@]} -eq 0 ]; then
        echo -e "${GREEN}Keine Modul-Cache Dateien gefunden.${NC}"
        return 0
    fi
    
    echo -e "${WHITE}Gefundene Cache-Dateien:${NC}"
    echo -e "${GRAY}Nummer | Cache-Datei${NC}"
    echo -e "${GRAY}───────┼────────────────────────────────────────${NC}"
    
    for i in "${!cache_files[@]}"; do
        local filename=$(basename "${cache_files[$i]}")
        printf "${CYAN}%-6d │ ${WHITE}%s${NC}\n" $((i+1)) "$filename"
    done
    
    echo ""
    echo -e "${YELLOW}Optionen:${NC}"
    echo -e "${CYAN}1-${#cache_files[@]}.${NC} Spezifischen Cache löschen"
    echo -e "${CYAN}0.${NC} Alle Cache-Dateien löschen"
    echo -e "${CYAN}99.${NC} Zurück zum Hauptmenü"
    echo ""
    echo -e "${YELLOW}Wähle eine Option:${NC}"
    read -p "> " cache_choice
    
    # Eingabe-Validierung
    if ! [[ "$cache_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    if [ "$cache_choice" -eq 0 ] 2>/dev/null; then
        echo -e "${YELLOW}Lösche alle Cache-Dateien...${NC}"
        for cache_file in "${cache_files[@]}"; do
            rm -f "$cache_file"
            echo -e "${GREEN}✓ $(basename "$cache_file") gelöscht${NC}"
        done
        echo -e "${GREEN}Alle Modul-Cache Dateien wurden gelöscht.${NC}"
    elif [ "$cache_choice" -eq 99 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    elif [ "$cache_choice" -ge 1 ] && [ "$cache_choice" -le ${#cache_files[@]} ]; then
        local index=$((cache_choice-1))
        local selected_cache="${cache_files[$index]}"
        rm -f "$selected_cache"
        echo -e "${GREEN}✓ $(basename "$selected_cache") gelöscht${NC}"
        echo -e "${YELLOW}Beim nächsten Ausführen wird das Skript neu gescannt.${NC}"
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Funktion zum Installieren von Modulen für ein spezifisches Skript
install_modules_for_script() {
    echo -e "${BLUE}=== Module für Skript installieren ===${NC}"
    
    show_python_scripts
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${YELLOW}Gib die Nummer des Skripts ein (0 für Abbruch):${NC}"
    read -p "> " script_choice
    
    if [ "$script_choice" -eq 0 ] 2>/dev/null; then
        echo -e "${GRAY}Abgebrochen.${NC}"
        return 0
    fi
    
    # Eingabe-Validierung
    if ! [[ "$script_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
        read -p "Drücke Enter um fortzufahren..."
        return 1
    fi
    
    local scripts=($(find "$PYTHON_DIR" -name "*.py" -type f | sort))
    local index=$((script_choice-1))
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#scripts[@]}" ]; then
        local selected_script="${scripts[$index]}"
        local script_name=$(basename "$selected_script")
        echo -e "${BLUE}Installiere Module für: $script_name${NC}"
        
        # Modul-Installation durchführen
        install_python_modules "$selected_script"
        
        echo -e "${GREEN}Modul-Installation für $script_name abgeschlossen.${NC}"
        echo -e "${CYAN}Jetzt kannst du das Skript mit Option 1 ausführen.${NC}"
    else
        echo -e "${RED}Ungültige Auswahl.${NC}"
    fi
    
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Hauptmenü anzeigen
show_main_menu() {
    echo -e "${BOLD}${WHITE}=== Hauptmenü ===${NC}"
    echo -e "${CYAN}1.${NC} Python-Skript ausführen"
    echo -e "${CYAN}2.${NC} Python-Skript bearbeiten"
    echo -e "${CYAN}3.${NC} Neues Python-Skript erstellen"
    echo -e "${CYAN}4.${NC} Modul-Cache löschen"
    echo -e "${CYAN}5.${NC} Module für Skript installieren"
    echo -e "${CYAN}6.${NC} __pycache__ löschen"
    echo -e "${CYAN}7.${NC} Shell öffnen"
    echo -e "${CYAN}8.${NC} Git Manager"
    echo -e "${CYAN}9.${NC} Requirements.txt Generator"
    echo -e "${CYAN}10.${NC} Requirements.txt installieren"
    echo -e "${CYAN}11.${NC} Package Manager"
    echo -e "${CYAN}12.${NC} Performance Monitor"
    echo -e "${CYAN}13.${NC} Umgebung neu einrichten"
    echo -e "${CYAN}0.${NC} Beenden"
    echo ""
    echo -e "${YELLOW}Wähle eine Option:${NC}"
}

# =============================================================================
# Hauptprogramm
# =============================================================================

main() {
    # Prüfen ob dies der erste Lauf ist
    if [ ! -f "$HOME/.termux_python_setup_done" ]; then
        setup_environment
        touch "$HOME/.termux_python_setup_done"
    fi
    
    while true; do
        show_header
        show_main_menu
        read -p "> " choice
        
        # Eingabe-Validierung
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Ungültige Eingabe. Bitte eine Zahl eingeben.${NC}"
            sleep 2
            continue
        fi
        
        case $choice in
            1)
                execute_script
                ;;
            2)
                edit_script
                ;;
            3)
                create_script
                ;;
            4)
                clear_module_cache_menu
                ;;
            5)
                install_modules_for_script
                ;;
            6)
                clean_pycache
                ;;
            7)
                open_shell
                ;;
            8)
                git_manager
                ;;
            9)
                generate_requirements
                ;;
            10)
                install_requirements_menu
                ;;
            11)
                package_manager
                ;;
            12)
                performance_monitor
                ;;
            13)
                setup_environment
                ;;
            0)
                echo -e "${GREEN}Auf Wiedersehen!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl. Bitte versuche es erneut.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Skript starten
main "$@"
