
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
import "panels" as Panels

Item {
    id: root

    property string currentSubView: "home" // "home" | "wifi" | "bluetooth" | "audio" | "widgets" | "notifs"

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ==========================================
        // DYNAMIC HEADER (Only for sub-views)
        // ==========================================
        RowLayout {
            visible: root.currentSubView !== "home"
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8

            // Left: Back button
            Rectangle {
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
                        text: Translation.tr("Back")
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                    }
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.currentSubView = "home" }
            }

            ThemedText {
                text: {
                    if (root.currentSubView === "wifi" || root.currentSubView === "network") return Translation.tr("Wi-Fi Networks");
                    if (root.currentSubView === "bluetooth") return Translation.tr("Bluetooth");
                    if (root.currentSubView === "audio") return Translation.tr("Audio & Mixer");
                    if (root.currentSubView === "widgets" || root.currentSubView === "calendar" || root.currentSubView === "tasks") return Translation.tr("Widgets & Productivity");
                    if (root.currentSubView === "notifs" || root.currentSubView === "notifications") return Translation.tr("Notifications");
                    return Translation.tr("Control Center");
                }
                font.pixelSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
                Layout.leftMargin: 4
            }

            Item { Layout.fillWidth: true }

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
        // SUB-VIEWS & IMPASTO CONTROLS CONTAINER
        // ==========================================
        // SUB-VIEWS & IMPASTO CONTROLS CONTAINER
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. HOME: Impasto 2-Column Controls Panel
            SubViewContainer {
                active: root.currentSubView === "home"
                ControlsPanel {
                    id: controlsPanel
                    anchors.fill: parent
                    onPanelRequested: panel => root.openPanel(panel)
                    onClosed: AppState.activePopup = ""
                    onSettingsRequested: {
                        AppState.activePopup = "";
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
                    }
                }
            }

            // 2. WI-FI DRILLDOWN
            SubViewContainer {
                active: root.currentSubView === "wifi" || root.currentSubView === "network"
                Sections.NetworkSection {
                    anchors.fill: parent
                }
            }

            // 3. BLUETOOTH DRILLDOWN
            SubViewContainer {
                active: root.currentSubView === "bluetooth"
                Sections.BluetoothSection {
                    anchors.fill: parent
                }
            }

            // 4. AUDIO & APP MIXER DRILLDOWN
            SubViewContainer {
                active: root.currentSubView === "audio"
                Sections.AudioSection {
                    anchors.fill: parent
                }
            }

            // 5. WIDGETS DRILLDOWN (Calendar, Todo, Pomodoro)
            SubViewContainer {
                active: root.currentSubView === "widgets" || root.currentSubView === "calendar" || root.currentSubView === "tasks" || root.currentSubView === "todo" || root.currentSubView === "pomodoro"
                Sections.WidgetsSection {
                    anchors.fill: parent
                }
            }

            // 6. NOTIFICATIONS DRILLDOWN
            SubViewContainer {
                active: root.currentSubView === "notifs" || root.currentSubView === "notifications"
                Sections.NotificationsSection {
                    anchors.fill: parent
                }
            }
        }
    }

    component SubViewContainer: Item {
        id: svc
        property bool active: false
        anchors.fill: parent
        visible: opacity > 0.001
        enabled: svc.active
        opacity: svc.active ? 1.0 : 0.0
        scale: svc.active ? 1.0 : 0.96
        y: svc.active ? 0 : -14
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }

    function openPanel(panel) {
        if (!panel || panel === "") return;
        if (panel === "wifi" || panel === "network") root.currentSubView = "wifi";
        else if (panel === "bluetooth") root.currentSubView = "bluetooth";
        else if (panel === "audio") root.currentSubView = "audio";
        else if (panel === "notifications" || panel === "notifs") root.currentSubView = "notifs";
        else if (panel === "widgets" || panel === "calendar" || panel === "tasks" || panel === "todo" || panel === "pomodoro") root.currentSubView = "widgets";
        else root.currentSubView = panel;
    }
}
