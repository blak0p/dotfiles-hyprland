import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    color: "transparent"
    radius: Constants.sizeLg
    implicitWidth: mainLayout.implicitWidth + (Constants.sizeLg * 2)
    implicitHeight: 32

    RowLayout {
        id: mainLayout

        anchors.centerIn: parent
        spacing: Constants.sizeXs

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "HH:mm")
            font.bold: true
            font.pixelSize: Constants.sizeSm
        }

        Divider {
            vertical: true
        }

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "ddd, d MMM")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
        }

    }

}
