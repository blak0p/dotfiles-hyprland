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
import qs.services.network

ColumnLayout {
    id: root

    property int subTab: 0 // 0: Wi-Fi, 1: Bluetooth
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedTabs {
            activeValue: root.subTab
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            ThemedTab { value: 0; text: "Wi-Fi" }
            ThemedTab { value: 1; text: "Bluetooth" }

            onTabSelected: (v) => { root.subTab = v }
        }
    }

    // ==========================================
    // TAB 0: WI-FI
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.subTab === 0
        spacing: 10

        // Header actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ThemedText {
                text: Network.wifiScanning ? "Buscando redes..." : (Network.networkName ? "Conectado a: " + Network.networkName : "Redes disponibles")
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            SvgIcon {
                icon: "reload"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: rescanHover.hovered ? Theme.accent : Theme.muted
                HoverHandler { id: rescanHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Network.rescanWifi() }
            }
        }

        // Network list
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            spacing: 6
            model: Network.friendlyWifiNetworks
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: netDelegate
                required property var modelData
                width: ListView.view.width
                implicitHeight: netCol.implicitHeight + 14
                radius: Constants.sizeLg
                readonly property bool isActive: modelData?.active ?? false
                color: isActive
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    : (netHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                border.width: isActive ? 1 : 0
                border.color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

                ColumnLayout {
                    id: netCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        SvgIcon {
                            icon: netDelegate.isActive ? "wifi"
                                : (netDelegate.modelData?.strength > 66 ? "wifi"
                                    : (netDelegate.modelData?.strength > 33 ? "wifi" : "wifi"))
                            iconSize: Constants.sizeLg
                            flat: true
                            iconColor: netDelegate.isActive ? Theme.accent : Theme.muted
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: netDelegate.modelData?.ssid || "Red oculta"
                            font.pixelSize: Constants.sizeSm
                            font.bold: netDelegate.isActive
                            color: netDelegate.isActive ? Theme.accent : Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            text: netDelegate.modelData?.strength ? (netDelegate.modelData.strength + "%") : ""
                            font.pixelSize: Constants.size2Xs
                            color: Theme.muted
                        }

                        SvgIcon {
                            icon: netDelegate.isActive ? "check" : (netDelegate.modelData?.security ? "lock" : "")
                            iconSize: Constants.sizeSm
                            flat: true
                            iconColor: netDelegate.isActive ? Theme.accent : Theme.muted
                            visible: icon !== ""
                        }
                    }

                    // Password input row if requested
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Boolean(netDelegate.modelData?.askingPassword)
                        spacing: 8

                        TextField {
                            id: pwField
                            Layout.fillWidth: true
                            implicitHeight: 32
                            placeholderText: "Contraseña de la red..."
                            echoMode: TextInput.Password
                            color: Theme.fg
                            placeholderTextColor: Theme.muted
                            background: Rectangle {
                                color: Theme.bgTertiary
                                radius: Constants.sizeXs
                                border.color: Theme.border
                            }
                            onAccepted: Network.changePassword(netDelegate.modelData, pwField.text)
                        }

                        ThemedButton {
                            text: "Conectar"
                            onClicked: Network.changePassword(netDelegate.modelData, pwField.text)
                        }
                    }
                }

                HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: Network.connectToWifiNetwork(netDelegate.modelData)
                }
            }
        }

        // Bottom Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ThemedButton {
                Layout.fillWidth: true
                text: Network.wifiEnabled ? "Desactivar Wi-Fi" : "Activar Wi-Fi"
                onClicked: Network.toggleWifi()
            }

            ThemedButton {
                Layout.fillWidth: true
                text: "Desconectar"
                disabled: !Network.active
                onClicked: Network.disconnectWifiNetwork()
            }
        }
    }

    // ==========================================
    // TAB 1: BLUETOOTH
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.subTab === 1
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ThemedText {
                text: BluetoothStatus.enabled
                    ? ("Adaptador activo • " + BluetoothStatus.friendlyDeviceList.length + " dispositivos")
                    : "Bluetooth desactivado"
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            SvgIcon {
                icon: "reload"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: btRescanHover.hovered ? Theme.accent : Theme.muted
                visible: BluetoothStatus.enabled
                HoverHandler { id: btRescanHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (Bluetooth.defaultAdapter) {
                            Bluetooth.defaultAdapter.discovering = true;
                        }
                    }
                }
            }
        }

        // Toggle state button
        ThemedButton {
            Layout.fillWidth: true
            text: BluetoothStatus.enabled ? "Desactivar Bluetooth" : "Activar Bluetooth"
            onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            }
        }

        // Device list
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            spacing: 6
            visible: BluetoothStatus.enabled && BluetoothStatus.friendlyDeviceList.length > 0
            model: BluetoothStatus.friendlyDeviceList
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: btDelegate
                required property var modelData
                width: ListView.view.width
                implicitHeight: btCol.implicitHeight + 14
                radius: Constants.sizeLg
                readonly property bool isConnected: modelData?.connected ?? false
                color: isConnected
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    : (btHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                border.width: isConnected ? 1 : 0
                border.color: isConnected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

                ColumnLayout {
                    id: btCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        SvgIcon {
                            icon: "bluetooth"
                            iconSize: Constants.sizeLg
                            flat: true
                            iconColor: btDelegate.isConnected ? Theme.accent : Theme.muted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            ThemedText {
                                Layout.fillWidth: true
                                text: btDelegate.modelData?.name || "Dispositivo desconocido"
                                font.pixelSize: Constants.sizeSm
                                font.bold: btDelegate.isConnected
                                color: btDelegate.isConnected ? Theme.accent : Theme.fg
                                elide: Text.ElideRight
                            }

                            ThemedText {
                                Layout.fillWidth: true
                                text: btDelegate.isConnected
                                    ? ("Conectado" + (btDelegate.modelData?.batteryAvailable ? " • Batería: " + Math.round(btDelegate.modelData.battery * 100) + "%" : ""))
                                    : (btDelegate.modelData?.paired ? "Vinculado" : "Disponible")
                                font.pixelSize: Constants.size2Xs + 1
                                color: Theme.muted
                            }
                        }

                        RowLayout {
                            spacing: 6

                            ThemedButton {
                                text: btDelegate.isConnected ? "Desconectar" : "Conectar"
                                onClicked: {
                                    if (btDelegate.isConnected) btDelegate.modelData.disconnect();
                                    else btDelegate.modelData.connect();
                                }
                            }

                            ThemedButton {
                                text: btDelegate.modelData?.paired ? "Olvidar" : "Vincular"
                                onClicked: {
                                    if (btDelegate.modelData?.paired) btDelegate.modelData.forget();
                                    else btDelegate.modelData?.pair();
                                }
                            }
                        }
                    }
                }

                HoverHandler { id: btHover }
            }
        }

        // Empty state when Bluetooth enabled but 0 devices
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: Constants.sizeLg
            color: Theme.bgSecondary
            visible: BluetoothStatus.enabled && BluetoothStatus.friendlyDeviceList.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                SvgIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "bluetooth"
                    iconSize: 24
                    flat: true
                    iconColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Buscando dispositivos Bluetooth..."
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }
    }
}
