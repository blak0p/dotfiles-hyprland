# dotfiles-hyprland

Hyprland desktop stack: `hypr/`, `waybar/`, `quickshell/`, `fuzzel/`, `gtk-3.0/`, `gtk-4.0/`, `xsettingsd/`, `systemd/`, `btop/`, `cava/`.

Part of the [dotfiles umbrella](https://github.com/blak0p/dotfiles).

## Standalone install

```bash
git clone https://github.com/blak0p/dotfiles-hyprland.git
cd dotfiles-hyprland
./install.sh
```

The installer symlinks each top-level directory into `~/.config/`. Existing files are backed up with a `.bak.<timestamp>` suffix; existing symlinks pointing elsewhere are replaced atomically.

## What's deployed

- `hypr` → `~/.config/hypr` (Hyprland WM config: keybinds, monitors, rules, animations)
- `waybar` → `~/.config/waybar` (status bar)
- `quickshell` → `~/.config/quickshell` (shell + bar alternative)
- `fuzzel` → `~/.config/fuzzel` (app launcher)
- `gtk-3.0` / `gtk-4.0` → GTK theme config
- `xsettingsd` → X settings daemon
- `systemd` → user systemd units
- `btop` → system monitor
- `cava` → audio visualizer