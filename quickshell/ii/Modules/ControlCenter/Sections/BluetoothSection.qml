import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300

    spacing: 10

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedText {
            text: "Bluetooth"
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        SvgIcon {
            icon: "reload"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: rescanHover.hovered ? Theme.accent : Theme.muted
            visible: BluetoothStatus.enabled
            HoverHandler { id: rescanHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (Bluetooth.defaultAdapter) {
                        Bluetooth.defaultAdapter.discovering = true;
                    }
                }
            }
        }
    }

    // Enable toggle
    ThemedButton {
        Layout.fillWidth: true
        text: BluetoothStatus.enabled ? "Bluetooth activado" : "Activar Bluetooth"
        disabled: !Bluetooth.defaultAdapter ? true : BluetoothStatus.enabled
        onClicked: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = true;
        }
    }

    // Device list (hidden when disabled or empty; empty state shown separately)
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.contentHeightHint, 260)
        Layout.maximumHeight: 300
        clip: true
        spacing: 6
        visible: BluetoothStatus.enabled && BluetoothStatus.friendlyDeviceList.length > 0
        model: BluetoothStatus.friendlyDeviceList
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: btCol.implicitHeight + 12
            radius: Constants.sizeLg
            color: modelData.connected
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                : (btHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)

            ColumnLayout {
                id: btCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SvgIcon {
                        icon: "bluetooth"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: modelData.connected ? Theme.accent : Theme.muted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        ThemedText {
                            Layout.fillWidth: true
                            text: modelData.name || "Dispositivo desconocido"
                            font.pixelSize: Constants.sizeSm
                            font.bold: modelData.connected
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: modelData.connected
                                ? ("Conectado" + (modelData.batteryAvailable ? " • " + Math.round(modelData.battery * 100) + "%" : ""))
                                : (modelData.paired ? "Vinculado" : "No vinculado")
                            font.pixelSize: Constants.size2Xs + 1
                            color: Theme.muted
                        }
                    }

                    SvgIcon {
                        icon: "chevron-down"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: Theme.muted
                        rotation: Boolean(modelData.expanded ?? false) ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 150 } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: Boolean(modelData.expanded ?? false)
                    Item { Layout.fillWidth: true }

                    ThemedButton {
                        text: modelData.connected ? "Desconectar" : "Conectar"
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                    }

                    ThemedButton {
                        text: modelData.paired ? "Olvidar" : "Vincular"
                        onClicked: modelData.paired ? modelData.forget() : modelData.pair()
                    }
                }
            }

            HoverHandler { id: btHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: modelData.expanded = !modelData.expanded
            }
        }
    }

    // Empty state (when enabled but no devices found)
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 80
        radius: Constants.sizeLg
        color: "transparent"
        visible: BluetoothStatus.enabled && BluetoothStatus.friendlyDeviceList.length === 0

        ThemedText {
            anchors.centerIn: parent
            text: "Sin dispositivos"
            font.pixelSize: Constants.sizeSm
            color: Theme.muted
        }
    }
}
