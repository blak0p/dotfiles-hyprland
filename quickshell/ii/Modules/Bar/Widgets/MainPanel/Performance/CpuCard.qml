import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

PerformanceCard {
    id: root

    property string cpuName: cleanName(SystemStats.cpuModel)
    property string cpuTemp: SystemStats.cpuTemp
    property int cpuUsage: SystemStats.cpuUsage

    function cleanName(name) {
        if (!name)
            return "";

        return name.replace(/\(R\)|\(TM\)/g, "").replace(/\s*(?:Processor|CPU|APU|\d+-Core|\d+\s*cores?|with.*Graphics)\s*/gi, " ").replace(/@\s*\d+(?:\.\d+)?\s*[Gg][Hh][Zz]/g, "").replace(/\s+/g, " ").trim();
    }

    icon: "cpu"
    title: root.cpuName
    usage: root.cpuUsage

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true

        PerformanceMetric {
            label: "temp"
            value: root.cpuTemp
        }

        Divider {
            vertical: true
        }

        PerformanceMetric {
            label: "speed"
            value: SystemStats.cpuFreq
        }

        Divider {
            vertical: true
        }

        PerformanceMetric {
            label: "cores"
            value: SystemStats.cpuCores
        }

    }

}
