# dotfiles-hyprland

Hyprland desktop environment config: `hypr/`, `waybar/`, `quickshell/`, `fuzzel/`, `gtk-3.0/`, `gtk-4.0/`, `xsettingsd/`, `systemd/`, `btop/`, `cava/`, plus the `wallfliper/` wallpaper daemon.

Part of the [dotfiles umbrella](https://github.com/blak0p/dotfiles).

## Table of contents

- [What gets deployed](#what-gets-deployed)
- [Install](#install)
- [Update](#update)
- [Uninstall / rollback](#uninstall--rollback)
- [Keybindings (cheat sheet)](#keybindings-cheat-sheet)
- [Customize](#customize)
- [Troubleshooting](#troubleshooting)
- [Dependencies](#dependencies)

---

## What gets deployed

The installer creates symlinks from `~/.config/<name>` → top-level dirs in this repo.

| Symlink | What it configures |
|---|---|
| `~/.config/hypr` | Hyprland WM — keybinds, monitors, animations, rules, hyprland.lua, hypridle, hyprlock |
| `~/.config/waybar` | Status bar (alternative to Quickshell) |
| `~/.config/quickshell` | Quickshell bar/shell — uses `ii` config, includes wallpaperSelector |
| `~/.config/fuzzel` | App launcher (dmenu-style) |
| `~/.config/gtk-3.0` | GTK 3 theme config |
| `~/.config/gtk-4.0` | GTK 4 theme config |
| `~/.config/xsettingsd` | X settings daemon (cursor, theme) |
| `~/.config/systemd` | User systemd units (if any) |
| `~/.config/btop` | System monitor TUI |
| `~/.config/cava` | Audio visualizer |

Plus, the wallfliper daemon lives at `~/.config/hypr/wallfliper/` (nested under the `hypr` symlink, since the keybind calls it from there).

## Install

### As part of the umbrella (recommended)

```bash
git clone --recurse-submodules https://github.com/blak0p/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --hyprland
```

Or for the full setup including shell/editor configs:

```bash
./install.sh --all
```

### Standalone (without the umbrella)

```bash
git clone https://github.com/blak0p/dotfiles-hyprland.git
cd dotfiles-hyprland
./install.sh
```

### Install system dependencies first

The `install.sh` only creates symlinks — it does NOT install packages. Use the bundled `install-deps.sh` for that:

```bash
bash deps/install-deps.sh
```

It auto-detects your package manager (`pacman`, `dnf`, or `apt`) and installs the right list. See [Dependencies](#dependencies).

## Update

```bash
cd ~/dotfiles/dotfiles-hyprland
git pull
./install.sh   # idempotent — no-op for unchanged files
```

If running as part of the umbrella:

```bash
cd ~/dotfiles
git submodule update --remote --merge dotfiles-hyprland
```

## Uninstall / rollback

The installer backs up any existing real file before replacing it with a symlink. Backups go to:

```
~/.dotfiles-backup-YYYYMMDD-HHMMSS/<original-path>
```

To uninstall:

```bash
# Remove all the symlinks
for s in hypr waybar quickshell fuzzel gtk-3.0 gtk-4.0 xsettingsd systemd btop cava; do
    rm -f ~/.config/$s
done

# Restore from the latest backup (if you kept it)
ls -td ~/.dotfiles-backup-* | head -1
BACKUP=$(ls -td ~/.dotfiles-backup-* | head -1)
cp -a "$BACKUP"/.config/. ~/.config/
```

## Keybindings (cheat sheet)

The full keybind list lives in `hypr/hyprland/keybinds.lua` and `hypr/custom/keybinds.lua`. The custom one (overrides the end-4 defaults) has these highlights:

| Combo | Action |
|---|---|
| `SUPER + Return` | Open terminal (kitty) |
| `SUPER + Space` | Open app launcher (fuzzel) |
| `SUPER + C` | Close window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + H` / `SUPER + L` | Focus left / right monitor |
| `SUPER + left/right` | Move window to left/right monitor |
| `SUPER + J` / `SUPER + K` | Cycle windows next / prev |
| `SUPER + arrow keys` | Move window with arrows |
| `SUPER + SHIFT + up` | Move window up |
| `SUPER + Tab` | Toggle overview (Quickshell) |
| `SUPER + V` | Toggle clipboard (Quickshell) |
| `SUPER + Period` | Toggle emoji picker |
| `SUPER + A` | Toggle left sidebar |
| `SUPER + N` | Toggle right sidebar |
| `SUPER + M` | Toggle media controls |
| `SUPER + G` | Toggle widget overlay |
| `SUPER + K` | Toggle on-screen keyboard |
| `SUPER + SHIFT + J` | Toggle bar |
| `SUPER + /` | Toggle cheatsheet |
| `SUPER + SHIFT + ALT + /` | Show welcome screen |
| `CTRL + SUPER + T` | Change wallpaper (wallfliper) |
| `CTRL + SUPER + SHIFT + T` | Random wallpaper (Quickshell selector) |
| `CTRL + SUPER + ALT + T` | Random wallpaper (alternative) |
| `CTRL + SUPER + D` | Toggle light/dark mode |
| `CTRL + SUPER + R` | Restart Quickshell (killall + restart) |
| `CTRL + SUPER + P` | Cycle panel family |
| `CTRL + SUPER + M` | Launch PrismLauncher (Minecraft) |
| `CTRL + SUPER + D` | Launch Discord |
| `CTRL + SUPER + C` | Launch ZapZap (WhatsApp) |
| `CTRL + SUPER + T` | Launch wallfliper wallpaper picker |
| `CTRL + ALT + Delete` | Toggle session menu (Quickshell) |

**Mnemonic**: `SUPER` = Windows key. `SHIFT` and `CTRL` are obvious. Most launcher-style bindings are `SUPER + letter`.

## Customize

The most common edits:

- **Add a keybind**: edit `hypr/custom/keybinds.lua`, then `hyprctl reload`
- **Change wallpaper**: `SUPER + CTRL + T` opens the wallfliper GUI. Or run the daemon directly: `python3 ~/.config/hypr/wallfliper/main.py`
- **Change monitor layout**: edit `hypr/hyprland/monitors.lua`, then `hyprctl reload`
- **Change Quickshell bar**: edit `quickshell/ii/`, then `SUPER + CTRL + R` to restart
- **Add a Hyprland animation rule**: edit `hypr/hyprland/animations.lua` (or wherever in `hypr/hyprland/`), then `hyprctl reload`

After ANY config edit, run:

```bash
hyprctl reload
```

For Quickshell, use the keybind (`CTRL + SUPER + R`) — it kills and restarts.

## Troubleshooting

### My monitor setup is wrong after `hyprctl reload`

Reload keeps the running session but applies new monitor config. If it gets confused:

```bash
hyprctl reload
# If still broken, log out and back in
```

### A symlink points to a deleted file

```bash
# Check the symlink target exists
ls -la ~/.config/hypr
# If it's broken, re-run the installer
cd ~/dotfiles/dotfiles-hyprland
./install.sh
```

### I edited a file but Hyprland doesn't pick it up

Some sub-configs are sourced once. After editing Lua:

```bash
hyprctl reload   # Hyprland proper
SUPER+CTRL+R     # Quickshell (uses killall + restart)
```

### wallfliper doesn't open

Check the keybind path resolves:

```bash
ls -la ~/.config/hypr/wallfliper/main.py
# If missing, the deploy is incomplete — re-run the installer
```

Check dependencies: `python3` must be on `$PATH` and the wallfliper venv (if used) must be set up. See `hypr/wallfliper/README.md`.

### Custom-layer keybinds fail

The end-4 keybinds work out of the box (this repo). Personal shortcuts like the audio toggle, Steam auto-picture, etc. live in a `custom/keybinds.lua` layer that this public repo does not ship — you need to provide your own `~/.config/hypr/custom/keybinds.lua` that wires those combos to scripts you control. See [Customize](#customize) for how the custom layer works.

### Quickshell bar disappeared

```bash
# Restart it
SUPER+CTRL+R
# Or manually
qs -p ~/.config/quickshell/ii/
```

## Dependencies

The repo only contains config files — no binaries. You need to install the packages listed in `deps/`:

- Arch: `deps/packages.txt` (`pacman -S --needed - < deps/packages.txt`)
- Fedora: `deps/packages.dnf.txt`
- Debian/Ubuntu: `deps/packages.apt.txt`

Or run the auto-detecting installer: `bash deps/install-deps.sh`

Notable packages:
- `hyprland`, `hyprlock`, `hypridle` — the WM stack
- `waybar` or `quickshell` — pick one or both
- `fuzzel` — app launcher
- `kitty` — terminal
- `xdg-desktop-portal-hyprland` — XDG portal integration
- `python3` — for wallfliper (also needs the Python deps in `hypr/wallfliper/requirements.txt`)

## Related

- Umbrella: https://github.com/blak0p/dotfiles
- Other sub-repos: `dotfiles-shell`, `dotfiles-editors`

## License

Personal config — use at your own risk. The `wallfliper/` subtree is forked from https://github.com/Roberth-Souza/wallfliper under its own license (see `hypr/wallfliper/LICENSE`).
