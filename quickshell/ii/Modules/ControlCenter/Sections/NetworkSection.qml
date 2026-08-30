import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services
import qs.services.network

ColumnLayout {
    id: root

    property int contentHeightHint: 300

    spacing: 10

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedText {
            text: "Redes Wi-Fi"
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
            HoverHandler { id: rescanHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Network.rescanWifi() }
        }
    }

    // Scanning hint
    ThemedText {
        Layout.fillWidth: true
        text: Network.wifiScanning ? "Buscando redes..." : ""
        font.pixelSize: Constants.sizeSm
        color: Theme.muted
        visible: Network.wifiScanning
    }

    // Network list
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.contentHeightHint, 260)
        Layout.maximumHeight: 300
        clip: true
        spacing: 6
        model: Network.friendlyWifiNetworks
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: netCol.implicitHeight + 12
            radius: Constants.sizeLg
            color: (modelData.active || Network.wifiConnectTarget === modelData)
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                : (netHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)

            ColumnLayout {
                id: netCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SvgIcon {
                        icon: modelData.active ? "wifi"
                            : (modelData.strength > 66 ? "wifi-2"
                                : (modelData.strength > 33 ? "wifi-1" : "wifi-0"))
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: modelData.active ? Theme.accent : Theme.muted
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: modelData.ssid || "Red oculta"
                        font.pixelSize: Constants.sizeSm
                        font.bold: modelData.active
                        color: Theme.fg
                        elide: Text.ElideRight
                    }

                    SvgIcon {
                        icon: modelData.active ? "check"
                            : (modelData.security ? "lock" : "wifi")
                        iconSize: Constants.sizeSm
                        flat: true
                        iconColor: modelData.active ? Theme.accent : Theme.muted
                    }
                }

                // Password prompt
                RowLayout {
                    Layout.fillWidth: true
                    visible: modelData.askingPassword

                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        implicitHeight: 32
                        placeholderText: "Contraseña"
                        echoMode: TextInput.Password
                        color: Theme.fg
                        placeholderTextColor: Theme.muted
                        background: Rectangle {
                            color: Theme.bgSecondary
                            radius: Constants.sizeXs
                            border.color: Theme.border
                        }
                    }

                    ThemedButton {
                        text: "Conectar"
                        onClicked: Network.changePassword(modelData, pwField.text)
                    }
                }
            }

            HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: Network.connectToWifiNetwork(modelData)
            }
        }
    }

    // Disconnect active
    ThemedButton {
        Layout.fillWidth: true
        text: "Desconectar"
        disabled: !Network.active
        onClicked: Network.disconnectWifiNetwork()
    }
}
