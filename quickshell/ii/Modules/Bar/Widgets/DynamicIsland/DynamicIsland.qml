import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Rectangle {
    id: root

    property var mainBarWidget: null
    readonly property bool isNotifActive: !HyprlandData.hasFullscreen && IslandState.activeNotification !== null && !IslandState.isClosed(IslandState.activeNotification)
    readonly property bool isCritical: isNotifActive && IslandState.isCritical(IslandState.activeNotification)

    width: implicitWidth
    height: implicitHeight
    implicitHeight: 48
    implicitWidth: {
        if (!isNotifActive) {
            return clockLayout.implicitWidth + 36;
        }
        return Math.min(480, Math.max(340, compactRow.implicitWidth + 36));
    }

    radius: height / 2
    color: Theme.bg
    border.width: 1
    border.color: isCritical ? Theme.accent : (isNotifActive ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    // Progress Bar Indicator at the bottom of the pill
    Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.radius / 2
        height: 2
        radius: 1
        width: isNotifActive ? Math.max(0, (parent.width - root.radius) * (IslandState.activeNotification?.progress ?? 0)) : 0
        color: isCritical ? Theme.accent : Theme.accentComplementary
        opacity: isNotifActive && (IslandState.activeNotification?.progress !== undefined) ? 0.8 : 0
        visible: opacity > 0

        Behavior on width {
            NumberAnimation { duration: 50 }
        }
    }

    readonly property bool isPopupActive: AppState.activePopup === "dashboard" || AppState.activePopup === "launcher" || AppState.activePopup === "dynamicIslandNotch"

    // Clock View (Visible in Idle Mode)
    RowLayout {
        id: clockLayout
        anchors.centerIn: parent
        opacity: (isNotifActive || isPopupActive) ? 0 : 1
        scale: (isNotifActive || isPopupActive) ? 0.8 : 1
        visible: opacity > 0
        spacing: Constants.sizeXs

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "HH:mm")
            font.bold: true
            font.pixelSize: Constants.sizeSm
        }

        Divider {
            vertical: true
        }

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "ddd, d MMM")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
        }
    }

    // Compact Notification Toast View (In-Pill 2-line layout with Spring Morph)
    RowLayout {
        id: compactRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        opacity: isNotifActive ? 1 : 0
        scale: isNotifActive ? 1 : 0.85
        visible: opacity > 0
        spacing: Constants.sizeSm

        Behavior on opacity {
            NumberAnimation { duration: 220 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }

        // App / Notification Icon
        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            NotificationIcon {
                anchors.fill: parent
                notifData: IslandState.activeNotification
                iconSize: 18
            }
        }

        // Text: 2-line stacked (App/Summary + Body)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.size2Xs

                ThemedText {
                    text: IslandState.activeNotification?.appName || "Notificación"
                    font.bold: true
                    font.pixelSize: Constants.sizeSm
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }

                ThemedText {
                    text: "•"
                    color: Theme.muted
                    font.pixelSize: Constants.size2Xs
                }

                ThemedText {
                    text: IslandState.activeNotification?.summary || ""
                    color: Theme.fg
                    font.pixelSize: Constants.sizeSm
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            ThemedText {
                text: (IslandState.activeNotification?.body || "").replace(/\n/g, " ")
                color: Theme.muted
                font.pixelSize: Constants.sizeXs
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.maximumWidth: 320
            }
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

        // Close button
        SvgIconButton {
            icon: "x"
            iconSize: 12
            flat: true
            Layout.alignment: Qt.AlignVCenter
            onClicked: IslandState.dismissActive()
        }
    }

    // Interactive mouse area
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onEntered: {
            if (isNotifActive && IslandState.activeNotification && typeof IslandState.activeNotification.lock === "function") {
                IslandState.activeNotification.lock("pillHover");
            } else if (root.mainBarWidget && !isNotifActive) {
                root.mainBarWidget.clockHovered = true;
            }
        }

        onExited: {
            if (isNotifActive && IslandState.activeNotification && typeof IslandState.activeNotification.unlock === "function") {
                IslandState.activeNotification.unlock("pillHover");
            } else if (root.mainBarWidget) {
                root.mainBarWidget.clockHovered = false;
            }
        }

        onClicked: (mouse) => {
            if (isNotifActive) {
                if (mouse.button === Qt.LeftButton) {
                    IslandState.expand();
                } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                    IslandState.dismissActive();
                }
            }
        }

        onWheel: (wheel) => {
            if (isNotifActive && IslandState.queueCount > 0) {
                IslandState.advanceQueue();
            }
        }
    }
}
