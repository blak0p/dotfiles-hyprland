import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

PerformanceCard {
    id: root

    property int memUsage: SystemStats.memUsage
    property string memSizeText: SystemStats.memUsed.toFixed(1) + " / " + SystemStats.memTotal.toFixed(1) + " GiB"

    icon: "memory"
    title: Translation.tr("Memory")
    usage: root.memUsage
    color: Theme.accent

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true

        PerformanceMetric {
            label: "used"
            value: SystemStats.memUsed.toFixed(1) + " GiB"
        }

        Divider {
            vertical: true
        }

        PerformanceMetric {
            label: "total"
            value: SystemStats.memTotal.toFixed(1) + " GiB"
        }

    }

}
