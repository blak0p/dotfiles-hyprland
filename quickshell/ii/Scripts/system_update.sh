#!/usr/bin/env bash
# system_update.sh — Multi-distro package updater and manager for Quickshell/Minflair

ACTION="${1:-update}"
shift || true

find_brew() {
    local brew_path

    brew_path="$(command -v brew 2>/dev/null || true)"
    if [ -n "$brew_path" ] && [ -x "$brew_path" ]; then
        printf '%s\n' "$brew_path"
        return 0
    fi

    for brew_path in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_path" ]; then
            printf '%s\n' "$brew_path"
            return 0
        fi
    done

    return 1
}

if [ "$ACTION" = "update" ]; then
    system_manager_found=0
    system_status=0

    if command -v cachy-update &>/dev/null; then
        system_manager_found=1
        echo "Running CachyOS update..."
        cachy-update
        system_status=$?
    elif command -v yay &>/dev/null; then
        system_manager_found=1
        echo "Running yay system update..."
        yay -Syu
        system_status=$?
    elif command -v paru &>/dev/null; then
        system_manager_found=1
        echo "Running paru system update..."
        paru -Syu
        system_status=$?
    elif command -v pacman &>/dev/null; then
        system_manager_found=1
        echo "Running pacman system update..."
        sudo pacman -Syu
        system_status=$?
    elif command -v dnf &>/dev/null; then
        system_manager_found=1
        echo "Running dnf system update..."
        sudo dnf upgrade
        system_status=$?
    elif command -v apt &>/dev/null; then
        system_manager_found=1
        echo "Running apt system update..."
        sudo apt update && sudo apt upgrade
        system_status=$?
    elif command -v zypper &>/dev/null; then
        system_manager_found=1
        echo "Running zypper system update..."
        sudo zypper update
        system_status=$?
    else
        echo "No supported system package manager found; skipping CachyOS update."
    fi

    brew_path="$(find_brew || true)"
    brew_manager_found=0
    brew_status=0
    if [ -n "$brew_path" ]; then
        brew_manager_found=1
        echo "Running Homebrew update..."
        "$brew_path" update
        brew_update_status=$?

        echo "Running Homebrew upgrade..."
        "$brew_path" upgrade
        brew_upgrade_status=$?

        echo "Running Homebrew cleanup..."
        "$brew_path" cleanup
        brew_cleanup_status=$?

        if [ "$brew_update_status" -ne 0 ] || [ "$brew_upgrade_status" -ne 0 ] || [ "$brew_cleanup_status" -ne 0 ]; then
            brew_status=1
        fi
    else
        echo "Homebrew not found; skipping Homebrew updates."
    fi

    if [ "$system_manager_found" -eq 0 ] && [ "$brew_manager_found" -eq 0 ]; then
        echo "No supported package manager found on this system!"
        exit 1
    fi

    if [ "$system_status" -ne 0 ] || [ "$brew_status" -ne 0 ]; then
        echo "One or more package updates failed."
        exit 1
    fi

    echo "Package updates completed."
    exit 0
fi

if command -v cachy-update &>/dev/null && [ "$ACTION" = "update" ]; then
    cachy-update
elif command -v yay &>/dev/null; then
    case "$ACTION" in
        update) yay -Syu ;;
        install) yay -S --needed "$@" ;;
        remove) yay -Rns "$@" ;;
    esac
elif command -v paru &>/dev/null; then
    case "$ACTION" in
        update) paru -Syu ;;
        install) paru -S --needed "$@" ;;
        remove) paru -Rns "$@" ;;
    esac
elif command -v pacman &>/dev/null; then
    case "$ACTION" in
        update) sudo pacman -Syu ;;
        install) sudo pacman -S --needed "$@" ;;
        remove) sudo pacman -Rns "$@" ;;
    esac
elif command -v dnf &>/dev/null; then
    case "$ACTION" in
        update) sudo dnf upgrade ;;
        install) sudo dnf install "$@" ;;
        remove) sudo dnf remove "$@" ;;
    esac
elif command -v apt &>/dev/null; then
    case "$ACTION" in
        update) sudo apt update && sudo apt upgrade ;;
        install) sudo apt install "$@" ;;
        remove) sudo apt remove "$@" ;;
    esac
elif command -v zypper &>/dev/null; then
    case "$ACTION" in
        update) sudo zypper update ;;
        install) sudo zypper install "$@" ;;
        remove) sudo zypper remove "$@" ;;
    esac
else
    echo "No supported package manager found on this system!"
    exit 1
fi
