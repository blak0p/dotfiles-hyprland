import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300

    width: parent.width
    spacing: 10

    QuickToggles {}

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    QuickSliders {}

    SystemBar {}
}
