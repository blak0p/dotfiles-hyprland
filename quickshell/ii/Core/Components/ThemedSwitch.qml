import QtQuick
import qs.Core

Rectangle {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled(bool checked)

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    opacity: root.disabled ? 0.45 : 1

    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

    color: root.checked ? Theme.accent : Theme.bgSecondary
    border.color: root.checked ? Theme.accent : Theme.border
    border.width: 1

    Behavior on color { ColorAnimation { duration: Constants.animFast } }
    Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

    Rectangle {
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        width: root.height - 6
        height: width
        radius: width / 2
        color: root.checked ? Theme.bg : Theme.fg

        Behavior on x {
            NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }
        Behavior on color { ColorAnimation { duration: Constants.animFast } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: !root.disabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.toggled(!root.checked);
        }
    }
}
