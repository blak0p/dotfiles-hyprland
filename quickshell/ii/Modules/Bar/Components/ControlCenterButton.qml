import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Rectangle {
    id: ccRoot

    signal clicked()

    property bool transparentBg: false
    property var notificationService
    property bool isHovered: btnMouse.containsMouse
    property bool isPressed: btnMouse.pressed

    Layout.preferredHeight: 32
    color: transparentBg
        ? (isHovered || isPressed ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        : (isHovered || isPressed ? Theme.bgTertiary : Theme.bgSecondary)
    radius: height / 2
    border.width: transparentBg ? 0 : 1
    border.color: AppState.activePopup === "controlCenter" ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
    implicitWidth: ccLayout.implicitWidth + (transparentBg ? Constants.sizeSm * 2 : Constants.sizeLg * 2)
    scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ccRoot.clicked()
    }

    RowLayout {
        id: ccLayout

        anchors.centerIn: parent
        spacing: 6

        BatteryIcon {
            notificationService: ccRoot.notificationService
        }

        NotificationsIcon {
            id: notifLayout
            notificationService: ccRoot.notificationService
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

    }

}
