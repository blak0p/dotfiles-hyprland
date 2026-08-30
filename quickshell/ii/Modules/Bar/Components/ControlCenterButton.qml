import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Rectangle {
    id: ccRoot

    property bool transparentBg: false
    property var notificationService
    property bool isHovered: ccHoverHandler.hovered
    property bool isPressed: ccTapHandler.pressed

    Layout.preferredHeight: 32
    color: transparentBg
        ? (isHovered || isPressed ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        : (isHovered || isPressed ? Theme.bgTertiary : Theme.bgSecondary)
    radius: height / 2
    border.width: transparentBg ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    implicitWidth: ccLayout.implicitWidth + (transparentBg ? Constants.sizeSm * 2 : Constants.sizeLg * 2)
    scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

    TapHandler {
        id: ccTapHandler

        onTapped: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }

    HoverHandler {
        id: ccHoverHandler

        cursorShape: Qt.PointingHandCursor
    }

    RowLayout {
        id: ccLayout

        anchors.centerIn: parent
        spacing: 2

        BatteryIcon {
            notificationService: ccRoot.notificationService
        }

        SvgIcon {
            icon: "tune"
            iconColor: Theme.fg
            iconSize: Constants.sizeLg
            flat: true
        }

        NotificationsIcon {
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
