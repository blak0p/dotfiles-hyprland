import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property bool isActive: false
    property bool isHovered: hoverHandler.hovered
    property bool isPressed: tapHandler.pressed
    property color bgColor: root.isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : (root.isHovered ? Theme.bgSecondary : "transparent")

    signal clicked()

    width: parent ? parent.width : 260
    implicitHeight: 40
    Layout.fillWidth: true
    scale: root.isPressed ? 0.98 : 1

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -Constants.sizeXs
            radius: Constants.sizeSm
            color: root.bgColor
        }

    }

    Rectangle {
        width: 3
        height: parent.height
        radius: 1.5
        color: Theme.accent
        visible: root.isActive
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: Constants.sizeLg
        spacing: Constants.sizeXs

        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: root.icon
            visible: root.icon !== ""
            iconSize: Constants.sizeLg
            flat: true
            iconColor: root.isActive ? Theme.accent : (root.isHovered ? Theme.fg : Theme.muted)

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            Layout.fillWidth: true
            text: root.label
            color: root.isActive || root.isHovered ? Theme.fg : Theme.muted
            font.pixelSize: Constants.sizeMd
            font.weight: root.isActive ? Font.Medium : Font.Normal
            elide: Text.ElideRight

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            text: root.subLabel
            visible: root.subLabel !== ""
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
        }

    }

    TapHandler {
        id: tapHandler

        onTapped: root.clicked()
    }

    HoverHandler {
        id: hoverHandler

        cursorShape: Qt.PointingHandCursor
    }

    Behavior on bgColor {
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
