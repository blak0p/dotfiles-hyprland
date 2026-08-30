pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.modules.common.models.hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services
import "Sections" as Sections

Item {
    id: root

    property string currentSubView: "home" // "home" | "wifi" | "bluetooth" | "audio" | "widgets" | "notifs"

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ==========================================
        // DYNAMIC HEADER
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8

            // Left: Back button or Distro Uptime Pill
            Rectangle {
                visible: root.currentSubView !== "home"
                Layout.preferredHeight: 32
                implicitWidth: backRow.implicitWidth + 16
                radius: 16
                color: backHover.hovered ? Theme.bgTertiary : Theme.bgSecondary
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                RowLayout {
                    id: backRow
                    anchors.centerIn: parent
                    spacing: 6

                    SvgIcon {
                        icon: "chevron-left"
                        iconSize: 14
                        flat: true
                        iconColor: Theme.accent
                    }

                    ThemedText {
                        text: "Volver"
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                    }
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.currentSubView = "home" }
            }

            ThemedText {
                visible: root.currentSubView !== "home"
                text: {
                    if (root.currentSubView === "wifi") return "Redes Wi-Fi";
                    if (root.currentSubView === "bluetooth") return "Bluetooth";
                    if (root.currentSubView === "audio") return "Audio & Mezclador";
                    if (root.currentSubView === "widgets") return "Widgets & Productividad";
                    if (root.currentSubView === "notifs") return "Centro de Notificaciones";
                    return "Centro de control";
                }
                font.pixelSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
                Layout.leftMargin: 4
            }

            // In HOME view: Distro initial badge + Uptime text
            RowLayout {
                visible: root.currentSubView === "home"
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: Theme.bgSecondary
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    ThemedText {
                        anchors.centerIn: parent
                        text: (SystemInfo.distroName || "L").charAt(0).toUpperCase()
                        font.bold: true
                        font.pixelSize: Constants.sizeSm
                        color: Theme.accent
                    }
                }

                ThemedText {
                    text: (SystemInfo.distroName || "Linux") + " • " + DateTime.uptime
                    font.pixelSize: Constants.sizeSm
                    font.bold: true
                    color: Theme.fg
                }
            }

            Item { Layout.fillWidth: true }

            // System action buttons (Reload, Settings, Power)
            RowLayout {
                visible: root.currentSubView === "home"
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: rldHover.hovered ? Theme.bgTertiary : Theme.bgSecondary

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "reload"
                        iconSize: 14
                        flat: true
                        iconColor: rldHover.hovered ? Theme.accent : Theme.muted
                    }

                    HoverHandler { id: rldHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            Quickshell.execDetached(["hyprctl", "reload"]);
                            Quickshell.reload(true);
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: setHover.hovered ? Theme.bgTertiary : Theme.bgSecondary

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "settings-icon"
                        iconSize: 14
                        flat: true
                        iconColor: setHover.hovered ? Theme.accent : Theme.muted
                    }

                    HoverHandler { id: setHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            AppState.activePopup = "";
                            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: pwrHover.hovered ? Qt.rgba(1, 0.2, 0.2, 0.2) : Theme.bgSecondary

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "power"
                        iconSize: 14
                        flat: true
                        iconColor: pwrHover.hovered ? "#ff6b6b" : Theme.muted
                    }

                    HoverHandler { id: pwrHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: GlobalStates.sessionOpen = true
                    }
                }
            }

            // Close (x) button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: closeHover.hovered ? Theme.bgTertiary : Theme.bgSecondary

                SvgIcon {
                    anchors.centerIn: parent
                    icon: "x"
                    iconSize: 14
                    flat: true
                    iconColor: closeHover.hovered ? Theme.fg : Theme.muted
                }

                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: AppState.activePopup = "" }
            }
        }

        // ==========================================
        // SUB-VIEWS CONTAINER
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. HOME VIEW (Single-screen high-efficiency layout)
            Flickable {
                anchors.fill: parent
                visible: root.currentSubView === "home"
                contentHeight: homeColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: homeColumn
                    width: parent.width
                    spacing: 12

                    // Quick Sliders (Master Volume, Mic, Brightness)
                    QuickSliders {}

                    // Fast Navigation Pills Row (Audio Mixer, Wi-Fi, BT, Widgets, Notifs)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 19
                            color: pillAudioHover.hovered ? Theme.bgTertiary : Theme.bgSecondary
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.05)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                SvgIcon { icon: "volume"; iconSize: 14; flat: true; iconColor: Theme.accent }
                                ThemedText { text: "Mezclador Apps"; font.pixelSize: Constants.size2Xs + 1; font.bold: true; color: Theme.fg }
                            }

                            HoverHandler { id: pillAudioHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.currentSubView = "audio" }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 19
                            color: pillWidgetsHover.hovered ? Theme.bgTertiary : Theme.bgSecondary
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.05)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                SvgIcon { icon: "apps"; iconSize: 14; flat: true; iconColor: Theme.accent }
                                ThemedText { text: "Tareas / Cal"; font.pixelSize: Constants.size2Xs + 1; font.bold: true; color: Theme.fg }
                            }

                            HoverHandler { id: pillWidgetsHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.currentSubView = "widgets" }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 19
                            color: pillNotifsHover.hovered ? Theme.bgTertiary : Theme.bgSecondary
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.05)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                SvgIcon { icon: "bell"; iconSize: 14; flat: true; iconColor: Notifications.list.length > 0 ? Theme.accent : Theme.muted }
                                ThemedText {
                                    text: "Notifs (" + Notifications.list.length + ")"
                                    font.pixelSize: Constants.size2Xs + 1
                                    font.bold: true
                                    color: Notifications.list.length > 0 ? Theme.accent : Theme.fg
                                }
                            }

                            HoverHandler { id: pillNotifsHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.currentSubView = "notifs" }
                        }
                    }

                    // 12 Quick Toggles Grid (with drilldowns on WiFi & Bluetooth)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        // Wi-Fi (Toggle on card + arrow opens WiFi scan list)
                        QuickToggleButton {
                            icon: Network.wifiEnabled ? "wifi" : "wifi-off"
                            label: "Wi-Fi"
                            sublabel: Network.wifiEnabled ? (Network.networkName || "Conectado") : "Desactivado"
                            toggled: Network.wifiEnabled
                            hasDetail: true
                            onClicked: Network.toggleWifi()
                            onDetailClicked: root.currentSubView = "wifi"
                        }

                        // Bluetooth (Toggle on card + arrow opens Bluetooth device list)
                        QuickToggleButton {
                            icon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth-off"
                            label: "Bluetooth"
                            sublabel: BluetoothStatus.enabled
                                ? (BluetoothStatus.activeDeviceCount > 0 ? BluetoothStatus.firstActiveDevice.name : "Activado")
                                : "Desactivado"
                            toggled: BluetoothStatus.enabled
                            hasDetail: true
                            onClicked: {
                                if (Bluetooth.defaultAdapter)
                                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                            }
                            onDetailClicked: root.currentSubView = "bluetooth"
                        }

                        // Luz Nocturna
                        QuickToggleButton {
                            icon: Hyprsunset.active ? "moon-filled" : "moon"
                            label: "Luz Nocturna"
                            sublabel: Hyprsunset.active ? "Activado" : "Desactivado"
                            toggled: Boolean(Hyprsunset.active ?? false)
                            onClicked: Hyprsunset.toggle()
                        }

                        // Silencio / DND
                        QuickToggleButton {
                            icon: Notifications.silent ? "bell-off" : "bell"
                            label: "Silencio"
                            sublabel: Notifications.silent ? "Silenciado" : "Activo"
                            toggled: Notifications.silent
                            onClicked: Notifications.silent = !Notifications.silent
                        }

                        // No Dormir (Modo Café)
                        QuickToggleButton {
                            icon: Idle.inhibit ? "coffee-filled" : "coffee"
                            label: "No dormir"
                            sublabel: Idle.inhibit ? "Despierto" : "Automático"
                            toggled: Idle.inhibit
                            onClicked: Idle.toggleInhibit()
                        }

                        // Modo Juego (FPS Boost)
                        QuickToggleButton {
                            icon: "gamepad"
                            label: "Modo juego"
                            sublabel: gameToggleOpt.value ? "Activado" : "Desactivado"
                            toggled: !gameToggleOpt.value
                            onClicked: {
                                if (gameToggleOpt.value) {
                                    gameModeSet(false);
                                } else {
                                    gameModeSet(true);
                                }
                            }
                        }

                        // Perfil de Energía
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

                        // Modo Oscuro / Claro
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

                        // Captura de Pantalla
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

                        // Color Picker
                        QuickToggleButton {
                            icon: "color-palette"
                            label: "Color Picker"
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

                        // EasyEffects
                        QuickToggleButton {
                            icon: "tune"
                            label: "EasyEffects"
                            sublabel: EasyEffects.active ? "Activo" : "Inactivo"
                            toggled: EasyEffects.active
                            visible: EasyEffects.available
                            onClicked: EasyEffects.toggle()
                        }

                        // Cloudflare WARP
                        QuickToggleButton {
                            id: warpToggle
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
                                id: warpProc
                                running: true
                                command: ["bash", "-c", "warp-cli status 2>/dev/null || echo 'none'"]
                                stdout: StdioCollector {
                                    onStreamFinished: {
                                        if (text.includes("Connected")) warpToggle.toggled = true;
                                        else warpToggle.toggled = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2. WI-FI DRILLDOWN
            Sections.NetworkSection {
                anchors.fill: parent
                visible: root.currentSubView === "wifi"
            }

            // 3. BLUETOOTH DRILLDOWN
            Sections.BluetoothSection {
                anchors.fill: parent
                visible: root.currentSubView === "bluetooth"
            }

            // 4. AUDIO & APP MIXER DRILLDOWN
            Sections.AudioSection {
                anchors.fill: parent
                visible: root.currentSubView === "audio"
            }

            // 5. WIDGETS DRILLDOWN (Calendar, Todo, Pomodoro)
            Sections.WidgetsSection {
                anchors.fill: parent
                visible: root.currentSubView === "widgets"
            }

            // 6. NOTIFICATIONS DRILLDOWN
            Sections.NotificationsSection {
                anchors.fill: parent
                visible: root.currentSubView === "notifs"
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
        id: gameToggleOpt
        key: "animations:enabled"
    }
}
