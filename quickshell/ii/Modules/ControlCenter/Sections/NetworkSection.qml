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
    property bool canGoBack: false
    signal back()

    spacing: 10

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            visible: root.canGoBack
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.bgTertiary : "transparent"
            scale: backMouse.pressed ? 0.88 : (backMouse.containsMouse ? 1.12 : 1.0)

            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-left"
                iconSize: 14
                iconColor: backMouse.containsMouse ? Theme.accent : Theme.fg
                flat: true
                Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        ThemedText {
            text: Translation.tr("Wi-Fi Networks")
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        SvgIconButton {
            visible: Network.wifiEnabled
            icon: "reload"
            iconSize: 14
            flat: true
            onClicked: Network.rescanWifi()
        }

        ThemedSwitch {
            checked: Network.wifiEnabled
            onToggled: (chk) => {
                if (chk !== Network.wifiEnabled) {
                    Network.toggleWifi();
                }
            }
        }
    }

    // Featured Ethernet Card
    Rectangle {
        id: ethernetCard
        Layout.fillWidth: true
        implicitHeight: 50
        radius: Constants.sizeLg
        clip: true

        readonly property bool isEthConnected: Boolean(Network.ethernetConnected || Network.ethernet)

        color: isEthConnected
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
            : (ethMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
        border.width: 1
        border.color: isEthConnected
            ? Theme.accent
            : (ethMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : "transparent")

        Behavior on color { ColorAnimation { duration: Constants.animFast } }
        Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            SvgIcon {
                icon: "lan"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: ethernetCard.isEthConnected ? Theme.accent : Theme.muted
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                ThemedText {
                    Layout.fillWidth: true
                    text: Translation.tr("Ethernet (Cable)")
                    font.pixelSize: Constants.sizeSm
                    font.bold: ethernetCard.isEthConnected
                    color: ethernetCard.isEthConnected ? Theme.accent : Theme.fg
                    elide: Text.ElideRight
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: ethernetCard.isEthConnected
                        ? (
                            (Network.ethernetDevice ? (Network.ethernetDevice + " • ") : "") +
                            (Network.ethernetName && Network.ethernetName !== Network.ethernetDevice ? (Network.ethernetName + " • ") : "") +
                            Translation.tr("Connected")
                          )
                        : Translation.tr("Disconnected")
                    font.pixelSize: Constants.size2Xs + 1
                    color: ethernetCard.isEthConnected ? Theme.accent : Theme.muted
                    elide: Text.ElideRight
                }
            }

            SvgIcon {
                icon: "check"
                iconSize: Constants.sizeSm
                flat: true
                iconColor: Theme.accent
                visible: ethernetCard.isEthConnected
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: ethMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
        }
    }

    // Scanning hint
    ThemedText {
        Layout.fillWidth: true
        text: Network.wifiScanning ? Translation.tr("Searching for networks...") : ""
        font.pixelSize: Constants.sizeSm
        color: Theme.muted
        visible: Network.wifiScanning
    }

    // Empty state
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Constants.sizeLg
        color: "transparent"
        visible: !Network.wifiEnabled || (Network.friendlyWifiNetworks && Network.friendlyWifiNetworks.length === 0)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            SvgIcon {
                icon: Network.wifiEnabled ? "wifi" : "wifi-off"
                iconSize: 28
                flat: true
                iconColor: Theme.muted
                Layout.alignment: Qt.AlignHCenter
            }

            ThemedText {
                text: !Network.wifiEnabled ? Translation.tr("Turn Wi-Fi on to see networks") : (Network.wifiScanning ? Translation.tr("Searching for networks...") : Translation.tr("No Wi-Fi networks found"))
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Network list
    ListView {
        id: netListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Network.wifiEnabled && Network.friendlyWifiNetworks && Network.friendlyWifiNetworks.length > 0
        clip: true
        spacing: 6
        model: Network.friendlyWifiNetworks
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: netDelegate
            required property var modelData
            width: ListView.view.width

            readonly property bool isAskingPassword: Boolean(modelData && modelData.askingPassword)
            readonly property bool isActive: Boolean(modelData && modelData.active)
            readonly property bool isConnecting: Boolean(Network.wifiConnectTarget === modelData)
            readonly property bool isSecured: Boolean(modelData && (modelData.isSecure || (modelData.security && modelData.security.length > 0)))

            implicitHeight: isAskingPassword ? 88 : 48
            radius: Constants.sizeLg
            clip: true

            color: (isActive || isConnecting)
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                : (netMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
            border.width: 1
            border.color: (isActive || isConnecting)
                ? Theme.accent
                : (isAskingPassword
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                    : (netMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : "transparent"))

            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 12
                    rightMargin: 12
                    topMargin: 8
                }
                spacing: 6

                // Header Row (Network info & click area)
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 32

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        SvgIcon {
                            icon: netDelegate.isActive ? "wifi"
                                : (netDelegate.modelData.strength > 66 ? "wifi-2"
                                    : (netDelegate.modelData.strength > 33 ? "wifi-1" : "wifi-0"))
                            iconSize: Constants.sizeLg
                            flat: true
                            iconColor: netDelegate.isActive ? Theme.accent : Theme.muted
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            ThemedText {
                                Layout.fillWidth: true
                                text: netDelegate.modelData.ssid || Translation.tr("Hidden network")
                                font.pixelSize: Constants.sizeSm
                                font.bold: netDelegate.isActive
                                color: netDelegate.isActive ? Theme.accent : Theme.fg
                                elide: Text.ElideRight
                            }

                            ThemedText {
                                visible: netDelegate.isActive || netDelegate.isConnecting
                                Layout.fillWidth: true
                                text: netDelegate.isActive ? Translation.tr("Connected") : Translation.tr("Connecting…")
                                font.pixelSize: Constants.size2Xs + 1
                                color: Theme.accent
                                elide: Text.ElideRight
                            }
                        }

                        ThemedText {
                            visible: !netDelegate.isActive && netDelegate.modelData.strength > 0
                            text: netDelegate.modelData.strength + "%"
                            font.pixelSize: Constants.size2Xs
                            color: Theme.muted
                            Layout.alignment: Qt.AlignVCenter
                        }

                        SvgIcon {
                            icon: netDelegate.isActive ? "check"
                                : (netDelegate.isSecured ? "lock" : "")
                            iconSize: Constants.sizeSm
                            flat: true
                            iconColor: netDelegate.isActive ? Theme.accent : Theme.muted
                            visible: icon !== ""
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (netDelegate.isActive) return;
                            if (netDelegate.isSecured) {
                                netDelegate.modelData.askingPassword = !netDelegate.modelData.askingPassword;
                            } else {
                                Network.connectToWifiNetwork(netDelegate.modelData);
                            }
                        }
                    }
                }

                // Expandable Inline Password Row
                RowLayout {
                    id: pwRow
                    Layout.fillWidth: true
                    implicitHeight: 34
                    visible: netDelegate.isAskingPassword
                    opacity: netDelegate.isAskingPassword ? 1.0 : 0.0
                    spacing: 8

                    Behavior on opacity {
                        NumberAnimation { duration: Constants.animFast }
                    }

                    onVisibleChanged: {
                        if (visible) {
                            pwInput.forceActiveFocus();
                        } else {
                            pwInput.text = "";
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: Theme.bgTertiary
                        radius: Constants.sizeXs
                        border.color: pwInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 6

                            TextInput {
                                id: pwInput
                                Layout.fillWidth: true
                                echoMode: showPw ? TextInput.Normal : TextInput.Password
                                color: Theme.fg
                                font.family: Constants.fontFamily
                                font.pixelSize: Constants.sizeSm
                                selectByMouse: true
                                clip: true

                                property bool showPw: false

                                function submit() {
                                    if (text.length > 0) {
                                        Network.connectWithPassword(netDelegate.modelData, text);
                                    }
                                }

                                Keys.onReturnPressed: submit()
                                Keys.onEnterPressed: submit()
                                Keys.onEscapePressed: {
                                    netDelegate.modelData.askingPassword = false;
                                }

                                ThemedText {
                                    anchors.fill: parent
                                    text: Translation.tr("Password...")
                                    font.pixelSize: Constants.sizeSm
                                    color: Theme.muted
                                    visible: !pwInput.text && !pwInput.inputMethodComposing
                                }
                            }

                            SvgIconButton {
                                icon: pwInput.showPw ? "eye" : "eye-off"
                                iconSize: 13
                                iconColor: Theme.muted
                                hoverColor: Theme.accent
                                flat: true
                                onClicked: pwInput.showPw = !pwInput.showPw
                            }
                        }
                    }

                    ThemedButton {
                        Layout.preferredHeight: 32
                        text: Translation.tr("Connect")
                        disabled: pwInput.text.length === 0
                        onClicked: {
                            if (pwInput.text.length > 0) {
                                Network.connectWithPassword(netDelegate.modelData, pwInput.text);
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 15
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 0.35, 0.35, 0.2) : Qt.rgba(1, 1, 1, 0.06)
                        scale: cancelMouse.pressed ? 0.9 : (cancelMouse.containsMouse ? 1.08 : 1.0)

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "x"
                            iconSize: 12
                            flat: true
                            iconColor: cancelMouse.containsMouse ? "#ff6b6b" : Theme.muted
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netDelegate.modelData.askingPassword = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Disconnect active
    ThemedButton {
        Layout.fillWidth: true
        text: Translation.tr("Disconnect")
        disabled: !Network.active
        visible: Network.wifiEnabled && Network.active
        onClicked: Network.disconnectWifiNetwork()
    }
}
