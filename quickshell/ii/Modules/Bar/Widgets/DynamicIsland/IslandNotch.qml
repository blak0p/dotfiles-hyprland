pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.services

TopPopup {
    id: islandNotchPopup

    popupId: "dynamicIslandNotch"
    isOpen: !HyprlandData.hasFullscreen && IslandState.mode === IslandState.modeExpandedNotch && IslandState.activeNotification !== null
    preferredWidth: 480
    preferredHeight: contentColumn.implicitHeight + Constants.sizeLg * 2
    autoCloseOnUnhover: false

    onIsOpenChanged: {
        if (!isOpen && IslandState.mode === IslandState.modeExpandedNotch) {
            IslandState.collapse();
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (IslandState.activeNotification) {
                if (hovered) {
                    if (typeof IslandState.activeNotification.lock === "function") {
                        IslandState.activeNotification.lock("islandNotchHover");
                    }
                } else {
                    if (typeof IslandState.activeNotification.unlock === "function") {
                        IslandState.activeNotification.unlock("islandNotchHover");
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        Layout.fillWidth: true
        spacing: Constants.sizeMd

        // Top Header: App Icon, Name, Time, Queue Count, Dismiss Button
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter

                NotificationIcon {
                    anchors.fill: parent
                    notifData: IslandState.activeNotification
                    iconSize: 20
                }
            }

            ThemedText {
                text: IslandState.activeNotification?.appName || "Notificación"
                font.bold: true
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
                Layout.alignment: Qt.AlignVCenter
            }

            ThemedText {
                text: "•"
                color: Theme.muted
                font.pixelSize: Constants.size2Xs
                Layout.alignment: Qt.AlignVCenter
            }

            ThemedText {
                text: {
                    let ts = IslandState.activeNotification?.timestamp || IslandState.activeNotification?.time;
                    if (!ts) return "ahora";
                    let date = new Date(ts);
                    return Qt.formatDateTime(date, "HH:mm");
                }
                color: Theme.muted
                font.pixelSize: Constants.sizeXs
                Layout.alignment: Qt.AlignVCenter
            }

            // Queue Badge (+N)
            Rectangle {
                visible: IslandState.queueCount > 0
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: badgeText.implicitWidth + 8
                radius: 9
                color: Theme.bgTertiary

                ThemedText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: "+" + IslandState.queueCount
                    font.pixelSize: Constants.size3Xs
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
            }

            SvgIconButton {
                icon: "x"
                iconSize: 14
                flat: true
                Layout.alignment: Qt.AlignVCenter
                onClicked: IslandState.dismissActive()
            }
        }

        // Summary Title
        ThemedText {
            Layout.fillWidth: true
            text: IslandState.activeNotification?.summary || ""
            font.bold: true
            font.pixelSize: Constants.sizeMd
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        // Message Body
        ThemedText {
            Layout.fillWidth: true
            text: IslandState.activeNotification?.body || ""
            color: Theme.fg
            font.pixelSize: Constants.sizeSm
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            visible: text !== ""
            onLinkActivated: (link) => Qt.openUrlExternally(link)
        }

        // Image Attachment (if any)
        Image {
            Layout.fillWidth: true
            Layout.maximumHeight: 180
            fillMode: Image.PreserveAspectFit
            source: {
                let img = IslandState.activeNotification?.image || "";
                if (!img) return "";
                if (img.startsWith("file://") || img.startsWith("image://") || img.startsWith("http")) return img;
                if (img.startsWith("/")) return "file://" + img;
                return img;
            }
            visible: (IslandState.activeNotification?.image || "") !== ""
            asynchronous: true
        }

        // Action Buttons Row (D-Bus notification actions)
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            visible: {
                let actions = IslandState.activeNotification?.actions || IslandState.activeNotification?.notification?.actions;
                return Boolean(actions && actions.length > 0);
            }

            Repeater {
                model: IslandState.activeNotification?.actions || IslandState.activeNotification?.notification?.actions || []

                ThemedButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.text || "Abrir"
                    onClicked: {
                        if (typeof modelData.invoke === "function") {
                            modelData.invoke();
                        } else if (IslandState.activeNotification?.notification && typeof IslandState.activeNotification.notification.invokeAction === "function") {
                            IslandState.activeNotification.notification.invokeAction(modelData.identifier);
                        }
                        IslandState.dismissActive();
                    }
                }
            }
        }

        // Progress Bar at bottom of notification
        Rectangle {
            Layout.fillWidth: true
            height: 2
            radius: 1
            color: IslandState.isCritical(IslandState.activeNotification) ? Theme.accent : Theme.accentComplementary
            opacity: IslandState.activeNotification?.progress !== undefined ? 0.6 : 0
            visible: opacity > 0
            width: parent ? parent.width * (IslandState.activeNotification?.progress ?? 1) : 0
        }
    }
}
