# Termux Python Development Manager

Ein zentrales Verwaltungsmenü für Python-Entwicklung in Termux mit automatischem Setup, Git-Integration und intelligentem Modul-Management.

## 🚀 Schnellinstallation (One-Click)

### Methode 1: Automatische Installation von GitHub
```bash
# Installation mit einem Befehl
curl -fsSL https://raw.githubusercontent.com/MrBlack-ctrl/MIB-Termux/main/install.sh | bash

# Oder mit wget
wget -qO- https://raw.githubusercontent.com/MrBlack-ctrl/MIB-Termux/main/install.sh | bash
```

Nach der Installation:
1. **Termux neu starten** oder `source ~/.bashrc` ausführen
2. Das Menü startet automatisch bei jedem Termux-Start
3. Oder manuell starten mit `pydev`

### Methode 2: Manuelles Klonen
```bash
git clone https://github.com/MrBlack-ctrl/MIB-Termux.git
cd MIB-Termux
chmod +x install.sh
./install.sh
```

## 📋 Funktionen

### 🚀 Automatisches Setup
- Prüft und installiert automatisch Python, pip und Git
- Richtet termux-setup-storage ein
- Führt Auto-Update für Systempakete und pip durch
- Installiert notwendige Build-Abhängigkeiten

### � Git-Integration
- Repository initialisieren und verwalten
- Commit, Push, Pull Funktionen
- Branch-Management
- Status-Übersicht und Log-Anzeige

### �📁 Dateiverwaltung
- Arbeitet standardmäßig im Verzeichnis `/sdcard/py/`
- Zeigt alle `.py` Dateien in einer nummerierten Liste an
- Einfache Navigation durch die Skripte

### 🧠 Intelligenter Auto-Installer
- Scannt Python-Skripte vor der Ausführung nach Import-Statements
- Installiert fehlende Module automatisch via pip
- Intelligentes Mapping für Module mit unterschiedlichen Pip-Namen:
  - `cv2` → `opencv-python`
  - `PIL` → `Pillow`
  - `sklearn` → `scikit-learn`
  - und viele mehr...

### 📦 Requirements.txt Generator
- Automatische Generierung aus allen Python-Dateien
- Requirements aus spezifischen Dateien erstellen
- Installierte Pakete exportieren (pip freeze)

### 🛠️ Package Manager
- Installierte Pakete auflisten und verwalten
- Pakete suchen, installieren, deinstallieren
- Veraltete Pakete aktualisieren
- Detaillierte Paket-Informationen anzeigen

### 📊 Performance Monitor
- Laufzeitmessung von Python-Skripten
- Speichernutzung analysieren
- System-Informationen anzeigen
- Detaillierte Performance-Berichte

### 🎨 Ansprechende Benutzeroberfläche
- ASCII-Menü mit ANSI-Farben
- Header mit Akkustand und Python-Version
- Intuitive Menüführung

## �️ Verzeichnisstruktur

```
MIB-Termux/
├── start.sh              # Hauptskript
├── install.sh            # Installationsskript
├── README.md             # Dokumentation
├── .gitignore            # Git-Ignore-Regeln
└── /sdcard/py/           # Arbeitsverzeichnis für Python-Skripte
    ├── script1.py
    ├── script2.py
    ├── projekt/
    │   ├── main.py
    │   └── utils.py
    └── __pycache__/       # wird automatisch bereinigt
```

## 🎮 Hauptmenü

```
=== Hauptmenü ===
1. Python-Skript ausführen
2. Python-Skript bearbeiten
3. Neues Python-Skript erstellen
4. __pycache__ löschen
5. Shell öffnen
6. Git Manager
7. Requirements.txt Generator
8. Package Manager
9. Performance Monitor
10. Umgebung neu einrichten
0. Beenden
```

## 🔧 Manuelles Setup (falls erforderlich)

### 1. Skript herunterladen
```bash
git clone https://github.com/MrBlack-ctrl/MIB-Termux.git
cd MIB-Termux
```

### 2. Ausführbar machen
```bash
chmod +x start.sh
chmod +x install.sh
```

### 3. Installation ausführen
```bash
./install.sh
```

### 4. Manuelles Testen
```bash
./start.sh
```

## 🔄 Autostart Konfiguration

Das Installationsskript richtet automatisch den Autostart ein. Falls du es manuell konfigurieren möchtest:

### In .bashrc eintragen
```bash
echo 'cd ~/MIB-Termux && ./start.sh' >> ~/.bashrc
```

### Als Alias
```bash
echo 'alias pydev="cd ~/MIB-Termux && ./start.sh"' >> ~/.bashrc
```

## 🐙 Git-Integration

### Repository initialisieren
1. Menüpunkt "Git Manager" wählen
2. "Repository initialisieren" auswählen
3. Remote-URL hinzufügen (z.B. dein GitHub-Repository)

### Workflow
1. Änderungen an Skripten vornehmen
2. Git Manager → "Änderungen hinzufügen"
3. Git Manager → "Commit erstellen"
4. Git Manager → "Push zu Remote"

## 📚 Unterstützte Module

Das Skript erkennt automatisch die meisten Python-Module und installiert sie bei Bedarf. Besonders intelligente Zuordnungen:

| Import-Name | Pip-Paket |
|-------------|-----------|
| cv2 | opencv-python |
| PIL | Pillow |
| sklearn | scikit-learn |
| tensorflow | tensorflow |
| torch | torch |
| pandas | pandas |
| numpy | numpy |
| matplotlib | matplotlib |
| seaborn | seaborn |

Standardbibliotheks-Module werden automatisch übersprungen.

## ⌨️ Tastenkürzel

### Im nano-Editor
- `Ctrl + O`: Speichern
- `Ctrl + X`: Beenden
- `Ctrl + W`: Suchen
- `Ctrl + K`: Zeile ausschneiden
- `Ctrl + U`: Zeile einfügen

### Im Menü
- `0`: Zurück/Beenden
- `Enter`: Bestätigen
- `Pfeiltasten`: Navigation (in Editoren)

## 🛠️ Fehlerbehebung

### Berechtigungen
```bash
chmod +x start.sh
chmod +x install.sh
```

### Speicherzugriff
```bash
termux-setup-storage
```

### Git nicht gefunden
```bash
pkg update && pkg install git
```

### Module nicht gefunden
```bash
pip install modulname
```

### Autostart deaktivieren
```bash
# .bashrc bearbeiten
nano ~/.bashrc
# Diese Zeilen entfernen:
# cd ~/MIB-Termux && ./start.sh
```

## 🔄 Updates

### Automatisches Update
```bash
cd ~/MIB-Termux
git pull origin main
```

### Neuinstallation
```bash
rm -rf ~/MIB-Termux
curl -fsSL https://raw.githubusercontent.com/MrBlack-ctrl/MIB-Termux/main/install.sh | bash
```

## 🤝 Mitwirken

1. Repository forken
2. Feature-Branch erstellen: `git checkout -b feature/neue-funktion`
3. Änderungen committen: `git commit -am 'Neue Funktion'`
4. Pushen: `git push origin feature/neue-funktion`
5. Pull Request erstellen

## 📄 Lizenz

Dieses Skript ist freie Software unter der MIT-Lizenz und kann beliebig angepasst und weitergegeben werden.

## 🔗 Nützliche Links

- [Termux Wiki](https://wiki.termux.com/)
- [Python Dokumentation](https://docs.python.org/3/)
- [Git Dokumentation](https://git-scm.com/doc)

---

**Viel Spaß mit der Python-Entwicklung in Termux!** 🐍📱🚀
