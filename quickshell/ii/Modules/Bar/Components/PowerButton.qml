import QtQuick
import qs.Core

BarButton {
    id: root
    property bool transparentBg: false
    icon: "power"
    popupId: "powerMenu"
    implicitWidth: 32
    implicitHeight: 32
    color: transparentBg ? "transparent" : Theme.bgSecondary
    radius: height / 2
    border.width: transparentBg ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
}
