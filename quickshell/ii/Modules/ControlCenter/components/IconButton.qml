// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I C O N   B U T T O N                                                  │
// │   square icon action                                                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../theme"

// Square icon button, transparent until hovered.
Rectangle {
    id: root

    property string icon: ""
    property int iconSize: 13
    property color iconColor: Theme.text
    property bool active: false

    signal clicked()

    implicitWidth: 32
    implicitHeight: 28
    radius: Theme.radiusSmall

    color: root.active ? Theme.accent
        : (mouse.containsMouse ? Theme.islandSurfaceHover : "transparent")
    border.color: root.active ? Theme.accent
        : (mouse.containsMouse ? Theme.islandBorder : "transparent")
    border.width: 1

    scale: mouse.pressed ? 0.90 : (mouse.containsMouse ? 1.08 : 1.0)

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontMono
        font.pixelSize: root.iconSize
        color: root.active ? Theme.accentText
            : (mouse.containsMouse ? Theme.accent : root.iconColor)

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
