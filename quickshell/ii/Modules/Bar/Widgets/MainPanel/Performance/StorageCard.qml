import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

PerformanceCard {
    id: root

    property string diskName: SystemStats.diskName
    property int diskUsage: SystemStats.diskUsage
    property string diskSizeText: SystemStats.diskSizeText
    property var diskParts: root.diskSizeText.split(" / ")
    property string usedText: diskParts.length > 0 ? diskParts[0] + " GiB" : ""
    property string totalText: diskParts.length > 1 ? diskParts[1] : ""

    icon: "disk"
    title: root.diskName
    usage: root.diskUsage

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true

        PerformanceMetric {
            label: "used"
            value: root.usedText
        }

        Divider {
            vertical: true
        }

        PerformanceMetric {
            label: "total"
            value: root.totalText
        }

    }

}
