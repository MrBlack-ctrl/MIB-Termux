#!/bin/bash

# =============================================================================
# Termux Python Development Manager - Auto Installer
# Automatische Installation und Einrichtung für Termux
# =============================================================================

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Repository-Informationen
REPO_URL="https://github.com/MrBlack-ctrl/MIB-Termux.git"
INSTALL_DIR="$HOME/MIB-Termux"
SCRIPT_NAME="start.sh"

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}${BOLD}     Termux Python Development Manager - Auto Installer     ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Funktion zur Statusanzeige
show_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Prüfen ob Git installiert ist
check_git() {
    show_status "Prüfe Git-Installation..."
    if ! command -v git &> /dev/null; then
        show_status "Git wird installiert..."
        pkg update -y && pkg install -y git
        if [ $? -eq 0 ]; then
            show_success "Git erfolgreich installiert"
        else
            show_error "Git-Installation fehlgeschlagen"
            exit 1
        fi
    else
        show_success "Git ist bereits installiert"
    fi
}

# Repository klonen oder aktualisieren
clone_or_update_repo() {
    show_status "Repository wird heruntergeladen..."
    
    if [ -d "$INSTALL_DIR" ]; then
        show_status "Repository existiert bereits, wird aktualisiert..."
        cd "$INSTALL_DIR"
        git pull origin main
        if [ $? -eq 0 ]; then
            show_success "Repository erfolgreich aktualisiert"
        else
            show_error "Repository-Aktualisierung fehlgeschlagen"
            exit 1
        fi
    else
        show_status "Klone Repository..."
        git clone "$REPO_URL" "$INSTALL_DIR"
        if [ $? -eq 0 ]; then
            show_success "Repository erfolgreich geklont"
        else
            show_error "Repository-Klonen fehlgeschlagen"
            exit 1
        fi
    fi
}

# Skript ausführbar machen
make_executable() {
    show_status "Mache Skript ausführbar..."
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    if [ $? -eq 0 ]; then
        show_success "Skript ist ausführbar"
    else
        show_error "Konnte Skript nicht ausführbar machen"
        exit 1
    fi
}

# Autostart einrichten
setup_autostart() {
    show_status "Richte Autostart ein..."
    
    # Prüfen ob bereits ein Eintrag existiert
    if grep -q "$INSTALL_DIR/$SCRIPT_NAME" "$HOME/.bashrc" 2>/dev/null; then
        show_warning "Autostart ist bereits eingerichtet"
        return 0
    fi
    
    # Backup von .bashrc erstellen
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        show_status "Backup von .bashrc erstellt"
    fi
    
    # Autostart-Eintrag hinzufügen
    cat >> "$HOME/.bashrc" << 'EOF'

# Termux Python Development Manager - Autostart
if [ -t 1 ] && [ "$TERM" != "dumb" ] && [ -f "$HOME/MIB-Termux/start.sh" ]; then
    cd "$HOME/MIB-Termux"
    ./start.sh
fi
EOF
    
    if [ $? -eq 0 ]; then
        show_success "Autostart erfolgreich eingerichtet"
    else
        show_error "Autostart-Einrichtung fehlgeschlagen"
        exit 1
    fi
}

# Symlink für einfachen Zugriff erstellen
create_symlink() {
    show_status "Erstelle Symlink für einfachen Zugriff..."
    
    # Symlink in /usr/local/bin (falls vorhanden) oder in $HOME/.local/bin
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "/usr/local/bin/pydev"
        show_success "Symlink erstellt: /usr/local/bin/pydev"
    elif [ -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$HOME/.local/bin/pydev"
        show_success "Symlink erstellt: $HOME/.local/bin/pydev"
        
        # Prüfen ob .local/bin im PATH ist
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            show_status "PATH um $HOME/.local/bin erweitert"
        fi
    else
        show_warning "Konnte keinen Symlink erstellen (keine Berechtigung)"
    fi
}

# Erster Start des Skripts
first_run() {
    show_status "Starte erstmalige Einrichtung..."
    cd "$INSTALL_DIR"
    ./start.sh --setup-only
}

# Installation abschließen
finish_installation() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                    Installation abgeschlossen!                 ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${GREEN}✓ Repository geklont/aktualisiert${NC}${CYAN}                              ║${NC}"
    echo -e "${CYAN}║${GREEN}✓ Skript ausführbar gemacht${NC}${CYAN}                                   ║${NC}"
    echo -e "${CYAN}║${GREEN}✓ Autostart eingerichtet${NC}${CYAN}                                       ║${NC}"
    echo -e "${CYAN}║${GREEN}✓ Symlink erstellt (pydev)${NC}${CYAN}                                    ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${WHITE}Nächste Schritte:${NC}${CYAN}                                            ║${NC}"
    echo -e "${CYAN}║${YELLOW}1. Termux neu starten oder 'source ~/.bashrc' ausführen${NC}${CYAN}       ║${NC}"
    echo -e "${CYAN}║${YELLOW}2. Das Menü startet automatisch${NC}${CYAN}                               ║${NC}"
    echo -e "${CYAN}║${YELLOW}3. Oder manuell starten mit 'pydev'${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Hauptinstallationsroutine
main() {
    show_status "Starte Installation..."
    
    # Git prüfen und installieren
    check_git
    
    # Repository klonen/aktualisieren
    clone_or_update_repo
    
    # Skript ausführbar machen
    make_executable
    
    # Autostart einrichten
    setup_autostart
    
    # Symlink erstellen
    create_symlink
    
    # Installation abschließen
    finish_installation
}

# Skript ausführen
main "$@"
