import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

PerformanceCard {
    id: root

    property string gpuName: cleanName(SystemStats.gpuName)
    property string gpuTemp: SystemStats.gpuTemp
    property int gpuUsage: SystemStats.gpuUsage
    property bool hasGpu: SystemStats.hasGpu

    function cleanName(name) {
        if (!name)
            return "";

        return name.replace(/\(R\)|\(TM\)/g, "").replace(/\s*(?:Corporation|Graphics\s*Controller|Graphics|Laptop\s*GPU|Mobile|PCIe|DirectX)\s*/gi, " ").replace(/\s+/g, " ").trim();
    }

    visible: root.hasGpu
    icon: "gpu"
    title: root.gpuName
    usage: root.gpuUsage

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true

        PerformanceMetric {
            label: "temp"
            value: root.gpuTemp
        }

        Divider {
            vertical: true
        }

        PerformanceMetric {
            label: "vram"
            value: SystemStats.gpuVram
            visible: SystemStats.gpuVram !== "None"
        }

    }

}
