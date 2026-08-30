import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services
import qs.modules.common.models.hyprland

ColumnLayout {
    id: root

    spacing: 8

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        // ---- 1. Wi-Fi ----
        QuickToggleButton {
            icon: Network.wifiEnabled ? "wifi" : "wifi-off"
            label: "Wi-Fi"
            sublabel: Network.wifiEnabled ? (Network.networkName || "Conectado") : "Desactivado"
            toggled: Network.wifiEnabled
            onClicked: Network.toggleWifi()
        }

        // ---- 2. Bluetooth ----
        QuickToggleButton {
            icon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth-off"
            label: "Bluetooth"
            sublabel: BluetoothStatus.enabled
                ? (BluetoothStatus.activeDeviceCount > 0
                    ? BluetoothStatus.firstActiveDevice.name
                    : "Activado")
                : "Desactivado"
            toggled: BluetoothStatus.enabled
            onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            }
        }

        // ---- 3. Luz Nocturna ----
        QuickToggleButton {
            icon: Hyprsunset.active ? "moon-filled" : "moon"
            label: "Luz Nocturna"
            sublabel: Hyprsunset.active ? "Activado" : "Desactivado"
            toggled: Boolean(Hyprsunset.active ?? false)
            onClicked: Hyprsunset.toggle()
        }

        // ---- 4. Silencio / No Molestar ----
        QuickToggleButton {
            icon: Notifications.silent ? "bell-off" : "bell"
            label: "Silencio"
            sublabel: Notifications.silent ? "Silenciado" : "Activo"
            toggled: Notifications.silent
            onClicked: Notifications.silent = !Notifications.silent
        }

        // ---- 5. No Dormir (Keep Awake) ----
        QuickToggleButton {
            icon: Idle.inhibit ? "coffee-filled" : "coffee"
            label: "No dormir"
            sublabel: Idle.inhibit ? "Despierto" : "Automático"
            toggled: Idle.inhibit
            onClicked: Idle.toggleInhibit()
        }

        // ---- 6. Modo Juego ----
        QuickToggleButton {
            icon: "gamepad"
            label: "Modo juego"
            sublabel: gameToggle.value ? "Activado" : "Desactivado"
            toggled: !gameToggle.value
            onClicked: {
                if (gameToggle.value) {
                    gameModeSet(false);
                } else {
                    gameModeSet(true);
                }
            }
        }

        // ---- 7. Perfil de Energía ----
        QuickToggleButton {
            icon: {
                switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "energy-saver";
                    case PowerProfile.Performance: return "performance";
                    default: return "performance";
                }
            }
            label: "Energía"
            sublabel: {
                switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "Ahorro";
                    case PowerProfile.Performance: return "Máximo";
                    default: return "Balanceado";
                }
            }
            toggled: PowerProfiles.profile !== PowerProfile.Balanced
            onClicked: cyclePower()
        }

        // ---- 8. Modo Oscuro ----
        QuickToggleButton {
            icon: "sparkles"
            label: "Tema"
            sublabel: (typeof Appearance !== "undefined" && Appearance.m3colors.darkmode) ? "Oscuro" : "Claro"
            toggled: typeof Appearance !== "undefined" ? Appearance.m3colors.darkmode : true
            onClicked: {
                if (typeof Appearance !== "undefined" && Appearance.m3colors.darkmode) {
                    Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
                } else {
                    Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
                }
            }
        }

        // ---- 9. Captura Snip ----
        QuickToggleButton {
            icon: "picture"
            label: "Captura"
            sublabel: "Región"
            toggled: false
            onClicked: {
                AppState.activePopup = "";
                snipTimer.start();
            }
            Timer {
                id: snipTimer
                interval: 300
                repeat: false
                onTriggered: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"])
            }
        }

        // ---- 10. Color Picker ----
        QuickToggleButton {
            icon: "color-palette"
            label: "Color"
            sublabel: "Copiar hex"
            toggled: false
            onClicked: {
                AppState.activePopup = "";
                colorTimer.start();
            }
            Timer {
                id: colorTimer
                interval: 300
                repeat: false
                onTriggered: Quickshell.execDetached(["hyprpicker", "-a"])
            }
        }

        // ---- 11. EasyEffects ----
        QuickToggleButton {
            icon: "tune"
            label: "EasyEffects"
            sublabel: EasyEffects.active ? "Activo" : "Inactivo"
            toggled: EasyEffects.active
            visible: EasyEffects.available
            onClicked: EasyEffects.toggle()
        }

        // ---- 12. Cloudflare WARP ----
        QuickToggleButton {
            id: warpBtn
            icon: "rocket"
            label: "WARP 1.1.1.1"
            sublabel: toggled ? "Conectado" : "Desconectado"
            property bool toggled: false
            onClicked: {
                if (toggled) {
                    toggled = false;
                    Quickshell.execDetached(["warp-cli", "disconnect"]);
                } else {
                    toggled = true;
                    Quickshell.execDetached(["warp-cli", "connect"]);
                }
            }
            Process {
                id: warpStatusCheck
                running: true
                command: ["bash", "-c", "warp-cli status 2>/dev/null || echo 'none'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.includes("Connected")) {
                            warpBtn.toggled = true;
                        } else {
                            warpBtn.toggled = false;
                        }
                    }
                }
            }
        }
    }

    function cyclePower() {
        if (PowerProfiles.hasPerformanceProfile) {
            switch (PowerProfiles.profile) {
                case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break;
                case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break;
                default: PowerProfiles.profile = PowerProfile.PowerSaver; break;
            }
        } else {
            PowerProfiles.profile = PowerProfiles.profile === PowerProfile.Balanced
                ? PowerProfile.PowerSaver
                : PowerProfile.Balanced;
        }
    }

    function gameModeSet(active: bool): void {
        if (active) {
            HyprlandConfig.setMany({
                "animations:enabled": 0,
                "decoration:shadow:enabled": 0,
                "decoration:blur:enabled": 0,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "decoration:rounding": 0,
                "general:allow_tearing": 1
            });
        } else {
            HyprlandConfig.resetMany([
                "animations:enabled",
                "decoration:shadow:enabled",
                "decoration:blur:enabled",
                "general:gaps_in",
                "general:gaps_out",
                "general:border_size",
                "decoration:rounding",
                "general:allow_tearing"
            ]);
        }
    }

    HyprlandConfigOption {
        id: gameToggle
        key: "animations:enabled"
    }
}
