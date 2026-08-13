import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Rectangle {
    id: ccRoot

    property var notificationService
    property bool isHovered: ccHoverHandler.hovered
    property bool isPressed: ccTapHandler.pressed

    Layout.preferredHeight: 32
    color: isHovered || isPressed ? Theme.bgTertiary : Theme.bgSecondary
    radius: height / 2
    implicitWidth: ccLayout.implicitWidth + Constants.sizeLg * 2
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
