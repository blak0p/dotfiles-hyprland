#!/usr/bin/env bash
# dotfiles-hyprland installer — symlinks hypr waybar quickshell fuzzel gtk-3.0 gtk-4.0 xsettingsd systemd btop cava to ~/.config/.
# Run standalone (clone this repo + ./install.sh) or via the umbrella.
set -eEuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
export DOTFILES_DIR="${DOTFILES_DIR:-$REPO_ROOT}"

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}ℹ${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1"; }

deploy_symlink() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up $dst → $BACKUP_DIR/"
        mkdir -p "$BACKUP_DIR/$(dirname "${dst#$HOME/}")"
        mv "$dst" "$BACKUP_DIR/$(dirname "${dst#$HOME/}")/"
    fi
    if [ -L "$dst" ]; then
        local current
        current="$(readlink "$dst")"
        if [ "$current" = "$src" ]; then
            return 0  # Already correct — idempotent
        fi
        rm -f "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    ok "Symlink: $dst → $src"
}

deploy_configs() {
    local entries=(hypr waybar quickshell fuzzel gtk-3.0 gtk-4.0 xsettingsd systemd btop cava)
    for name in "${entries[@]}"; do
        if [ -e "$REPO_ROOT/$name" ]; then
            deploy_symlink "$REPO_ROOT/$name" "$HOME/.config/$name"
        else
            warn "Source not found, skipping: $REPO_ROOT/$name"
        fi
    done
}

main() {
    info "Deploying dotfiles-hyprland configs from $REPO_ROOT"
    deploy_configs
    # DOTFILES_SHELL_SPECIFIC_BLOCK
    ok "dotfiles-hyprland deploy complete"
}

main