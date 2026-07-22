#!/usr/bin/env bash
# install-deps.sh — Install domain packages using the system package manager.
# Auto-detects: Arch (pacman), Fedora (dnf), or Debian/Ubuntu (apt).
# Usage: bash deps/install-deps.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_pm() {
    if command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v dnf >/dev/null 2>&1 || command -v dnf5 >/dev/null 2>&1; then echo "dnf"
    elif command -v apt >/dev/null 2>&1; then echo "apt"
    else echo "unknown"
    fi
}

PM="$(detect_pm)"
echo "Detected package manager: $PM"

case "$PM" in
    pacman)
        LIST="$SCRIPT_DIR/packages.txt"
        [ ! -f "$LIST" ] && { echo "ERR: $LIST not found"; exit 1; }
        sudo pacman -S --needed - < "$LIST"
        ;;
    dnf)
        LIST="$SCRIPT_DIR/packages.dnf.txt"
        [ ! -f "$LIST" ] && { echo "ERR: $LIST not found"; exit 1; }
        grep -vE '^\s*(#|$)' "$LIST" | xargs sudo dnf install -y
        ;;
    apt)
        LIST="$SCRIPT_DIR/packages.apt.txt"
        [ ! -f "$LIST" ] && { echo "ERR: $LIST not found"; exit 1; }
        sudo xargs -a "$LIST" apt install -y
        ;;
    *)
        echo "ERR: no supported package manager found (need pacman, dnf, or apt)"
        exit 1
        ;;
esac
