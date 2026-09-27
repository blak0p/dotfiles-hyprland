pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string detail: ""
    property bool active: false
    property bool available: true
    property bool expandable: false

    signal toggled()
    signal expanded()

    radius: Theme.radiusMedium || 12
    opacity: root.available ? 1 : 0.45

    color: mouse.containsMouse ? (Theme.surfaceHover || "#202020") : (Theme.surface || "#141414")
    border.color: Theme.border || Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.02 : 1.0)

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            Layout.alignment: Qt.AlignVCenter
            radius: 17
            color: root.active ? "#ffffff" : (mouse.containsMouse ? "#282828" : (Theme.bgTertiary || "#1f1f1f"))

            Behavior on color { ColorAnimation { duration: 140 } }

            ThemedText {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontMono || "monospace"
                font.pixelSize: 16
                color: root.active ? "#000000" : (Theme.muted || "#8e8e93")

                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Layout.rightMargin: root.expandable ? 16 : 0

            ThemedText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall || 13
                font.bold: true
                color: Theme.text || "#ffffff"
            }

            ThemedText {
                Layout.fillWidth: true
                text: root.detail
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeLabel || 11
                color: Theme.muted || "#8e8e93"

                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 28
        visible: root.expandable

        ThemedText {
            anchors.centerIn: parent
            text: "󰅂"
            font.family: Theme.fontMono || "monospace"
            font.pixelSize: 13
            color: chevron.containsMouse ? (Theme.text || "#ffffff") : (Theme.muted || "#8e8e93")

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: chevron
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.available
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded()
        }
    }
}
