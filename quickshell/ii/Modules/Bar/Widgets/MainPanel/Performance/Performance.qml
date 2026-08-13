import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    id: root

    spacing: Constants.sizeLg

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true
        Layout.fillHeight: false

        CpuCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        MemoryCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

    }

    RowLayout {
        spacing: Constants.sizeLg
        Layout.fillWidth: true
        Layout.fillHeight: true

        StorageCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        GpuCard {
            id: gpuCard

            Layout.fillWidth: visible
            Layout.fillHeight: true
        }

    }

}
