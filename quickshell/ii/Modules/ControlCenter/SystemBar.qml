import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 56
    radius: Constants.sizeLg + 2
    color: Theme.bgSecondary
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.05)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        // Distro / uptime
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 9
                color: Theme.bgTertiary

                SvgIcon {
                    anchors.centerIn: parent
                    icon: "minflair"
                    iconSize: Constants.sizeLg
                    flat: true
                    iconColor: Theme.accent
                    visible: false
                }

                ThemedText {
                    anchors.centerIn: parent
                    text: (SystemInfo.distroName || "OS").charAt(0).toUpperCase()
                    font.bold: true
                    font.pixelSize: Constants.sizeXl
                    color: Theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                ThemedText {
                    text: SystemInfo.distroName || Translation.tr("System")
                    font.pixelSize: Constants.sizeSm
                    font.bold: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    font.pixelSize: Constants.size2Xs + 1
                    color: Theme.muted
                    elide: Text.ElideRight
                }
            }
        }

        // Buttons
        SvgIcon {
            icon: "reload"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: sbReloadHover.hovered ? Theme.accent : Theme.muted
            HoverHandler { id: sbReloadHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    Quickshell.execDetached(["hyprctl", "reload"]);
                    Quickshell.reload(true);
                }
            }
        }

        SvgIcon {
            icon: "settings-icon"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: sbSettingsHover.hovered ? Theme.accent : Theme.muted
            HoverHandler { id: sbSettingsHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    AppState.activePopup = "";
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
                }
            }
        }

        SvgIcon {
            icon: "power"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: sbPowerHover.hovered ? "#ff6b6b" : Theme.muted
            HoverHandler { id: sbPowerHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: GlobalStates.sessionOpen = true
            }
        }
    }
}
