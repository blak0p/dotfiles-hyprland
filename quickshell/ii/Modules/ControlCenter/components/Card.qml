pragma ComponentBehavior: Bound

import QtQuick
import qs.Core

Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: 14
    property bool bare: false

    radius: Theme.radiusMedium || 12
    color: root.bare ? "transparent" : (Theme.bgSecondary || "#141414")
    border.color: root.bare ? "transparent" : (Theme.border || Qt.rgba(1, 1, 1, 0.08))
    border.width: root.bare ? 0 : 1

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
