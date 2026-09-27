import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300
    property bool canGoBack: false
    property bool showUnnamed: false
    signal back()

    spacing: 12

    readonly property bool isEnabled: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? true : false
    readonly property bool isDiscovering: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) ? true : false

    readonly property var allDevices: {
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices) {
            return Bluetooth.defaultAdapter.devices.values || [];
        }
        if (Bluetooth.devices && Bluetooth.devices.values) {
            return Bluetooth.devices.values || [];
        }
        return [];
    }

    readonly property var connectedDevices: allDevices.filter(device => device && device.connected)

    function isNamed(device) {
        if (!device) return false;
        const name = (device.name || "").trim();
        if (name.length === 0) return false;
        const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;
        return !macRegex.test(name);
    }

    readonly property var namedDevices: {
        const list = root.allDevices.filter(device => root.isNamed(device) || (device && (device.paired || device.connected || device.pairing)));
        return list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    readonly property var unnamedDevices: {
        const rest = root.allDevices.filter(device => !(root.isNamed(device) || (device && (device.paired || device.connected || device.pairing))));
        return rest.sort((a, b) => (a.address || "").localeCompare(b.address || ""));
    }

    readonly property var displayedDevices: root.showUnnamed
        ? root.namedDevices.concat(root.unnamedDevices)
        : root.namedDevices

    function resolveDeviceIcon(device) {
        if (!device) return "bluetooth";
        const icon = device.icon || "";
        switch (icon) {
            case "audio-headset":
            case "audio-headphones":
                return "icons/fluent/headphones";
            case "audio-card":
                return "volume";
            case "input-gaming":
                return "gamepad";
            case "phone":
                return "icons/fluent/phone";
            case "computer":
                return "cpu";
            default:
                return "bluetooth";
        }
    }

    Component.onCompleted: {
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
            Bluetooth.defaultAdapter.discovering = true;
        }
    }

    Component.onDestruction: {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discovering = false;
        }
    }

    // ==========================================
    // HEADER
    // ==========================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

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

        ColumnLayout {
            spacing: 1

            ThemedText {
                text: Translation.tr("Bluetooth")
                font.pixelSize: Constants.sizeXl
                font.bold: true
                color: Theme.fg
            }

            ThemedText {
                text: {
                    if (!root.isEnabled) return Translation.tr("Adapter off");
                    if (root.isDiscovering) return Translation.tr("Looking for devices…");
                    if (root.connectedDevices.length === 1) return root.connectedDevices[0].name || Translation.tr("Connected");
                    if (root.connectedDevices.length > 1) return root.connectedDevices.length + " " + Translation.tr("devices connected");
                    return Translation.tr("No connected devices");
                }
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
            }
        }

        Item { Layout.fillWidth: true }

        SvgIconButton {
            visible: root.isEnabled
            icon: "reload"
            iconSize: 14
            flat: true
            onClicked: {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.discovering = true;
                }
            }
        }

        ThemedSwitch {
            checked: root.isEnabled
            onToggled: (chk) => {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = chk;
                    if (chk) {
                        Bluetooth.defaultAdapter.discovering = true;
                    }
                }
            }
        }
    }

    // ==========================================
    // EMPTY STATE
    // ==========================================
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Constants.sizeLg
        color: "transparent"
        visible: !root.isEnabled || root.displayedDevices.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            SvgIcon {
                icon: root.isEnabled ? "bluetooth" : "bluetooth-off"
                iconSize: 28
                flat: true
                iconColor: Theme.muted
                Layout.alignment: Qt.AlignHCenter
            }

            ThemedText {
                text: root.isEnabled
                    ? (root.isDiscovering ? Translation.tr("Looking for devices…") : Translation.tr("No devices found"))
                    : Translation.tr("Turn Bluetooth on to see devices")
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // ==========================================
    // DEVICE LIST
    // ==========================================
    ListView {
        id: deviceListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        visible: root.isEnabled && root.displayedDevices.length > 0
        model: root.displayedDevices
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: deviceCard
            required property var modelData

            property bool expanded: false

            width: ListView.view.width
            implicitHeight: cardLayout.implicitHeight + 20
            radius: 12
            color: (deviceCard.modelData && deviceCard.modelData.connected)
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                : (cardHeaderMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
            border.color: (deviceCard.modelData && deviceCard.modelData.connected)
                ? Theme.accent
                : (deviceCard.expanded ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.border)
            border.width: 1
            clip: true

            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }
            Behavior on implicitHeight { NumberAnimation { duration: Constants.animFast } }

            ColumnLayout {
                id: cardLayout
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 8

                // Header container
                Item {
                    id: headerContainer
                    Layout.fillWidth: true
                    implicitHeight: 32

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        spacing: 12

                        SvgIcon {
                            icon: root.resolveDeviceIcon(deviceCard.modelData)
                            iconSize: 18
                            flat: true
                            iconColor: (deviceCard.modelData && deviceCard.modelData.connected) ? Theme.accent : Theme.muted
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            ThemedText {
                                Layout.fillWidth: true
                                text: (deviceCard.modelData ? (deviceCard.modelData.name || deviceCard.modelData.address) : "") || Translation.tr("Unknown device")
                                elide: Text.ElideRight
                                font.pixelSize: Constants.sizeSm
                                font.bold: Boolean(deviceCard.modelData && deviceCard.modelData.connected)
                                color: (deviceCard.modelData && deviceCard.modelData.connected) ? Theme.accent : Theme.fg
                            }

                            ThemedText {
                                Layout.fillWidth: true
                                text: {
                                    if (!deviceCard.modelData) return "";
                                    if (deviceCard.modelData.pairing) return Translation.tr("Pairing…");
                                    let parts = [];
                                    if (deviceCard.modelData.connected) parts.push(Translation.tr("Connected"));
                                    else if (deviceCard.modelData.paired) parts.push(Translation.tr("Paired"));
                                    else parts.push(Translation.tr("Available"));

                                    if (deviceCard.modelData.batteryAvailable) {
                                        parts.push(Math.round(deviceCard.modelData.battery * 100) + "%");
                                    }
                                    return parts.join(" • ");
                                }
                                elide: Text.ElideRight
                                font.pixelSize: Constants.size2Xs + 1
                                color: Theme.muted
                            }
                        }

                        SvgIcon {
                            visible: Boolean(deviceCard.modelData && deviceCard.modelData.connected)
                            icon: "check"
                            iconSize: 14
                            flat: true
                            iconColor: Theme.accent
                            Layout.alignment: Qt.AlignVCenter
                        }

                        SvgIcon {
                            icon: deviceCard.expanded ? "chevron-up" : "chevron-down"
                            iconSize: 12
                            flat: true
                            iconColor: Theme.muted
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: cardHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            deviceCard.expanded = !deviceCard.expanded;
                        }
                    }
                }

                // Action panel row
                RowLayout {
                    id: actionsRow
                    visible: deviceCard.expanded
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    // Forget button (when paired) - Subtle destructive pill
                    Rectangle {
                        id: forgetBtn
                        visible: Boolean(deviceCard.modelData && deviceCard.modelData.paired)
                        implicitHeight: 30
                        implicitWidth: forgetRow.implicitWidth + 28
                        radius: height / 2
                        color: forgetMouse.containsMouse ? Qt.rgba(1, 0.35, 0.35, 0.2) : Qt.rgba(1, 0.35, 0.35, 0.1)
                        scale: forgetMouse.pressed ? 0.92 : (forgetMouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        RowLayout {
                            id: forgetRow
                            anchors.centerIn: parent
                            spacing: 6

                            SvgIcon {
                                icon: "trash"
                                iconSize: 13
                                flat: true
                                iconColor: "#ff6b6b"
                            }

                            ThemedText {
                                text: Translation.tr("Forget")
                                font.pixelSize: 12
                                font.bold: true
                                color: "#ff6b6b"
                            }
                        }

                        MouseArea {
                            id: forgetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (deviceCard.modelData && typeof deviceCard.modelData.forget === "function") {
                                    deviceCard.modelData.forget();
                                }
                            }
                        }
                    }

                    // Pair button (when not paired and not connected) - Primary action pill
                    Rectangle {
                        id: pairBtn
                        visible: Boolean(deviceCard.modelData && !deviceCard.modelData.paired && !deviceCard.modelData.connected)
                        implicitHeight: 30
                        implicitWidth: pairRow.implicitWidth + 28
                        radius: height / 2
                        color: pairMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.88) : Theme.accent
                        scale: pairMouse.pressed ? 0.92 : (pairMouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        readonly property color contrastColor: ColorUtils.isDark(Theme.accent) ? "#ffffff" : "#000000"

                        RowLayout {
                            id: pairRow
                            anchors.centerIn: parent
                            spacing: 6

                            SvgIcon {
                                icon: "plus"
                                iconSize: 13
                                flat: true
                                iconColor: pairBtn.contrastColor
                            }

                            ThemedText {
                                text: Translation.tr("Pair")
                                font.pixelSize: 12
                                font.bold: true
                                color: pairBtn.contrastColor
                            }
                        }

                        MouseArea {
                            id: pairMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (deviceCard.modelData && typeof deviceCard.modelData.pair === "function") {
                                    deviceCard.modelData.pair();
                                }
                            }
                        }
                    }

                    // Connect / Disconnect button - Primary / Secondary action pill
                    Rectangle {
                        id: toggleConnectBtn
                        readonly property bool isConnected: Boolean(deviceCard.modelData && deviceCard.modelData.connected)
                        implicitHeight: 30
                        implicitWidth: toggleConnectRow.implicitWidth + 28
                        radius: height / 2
                        color: isConnected
                            ? (toggleConnectMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Qt.rgba(1, 1, 1, 0.08))
                            : (toggleConnectMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.88) : Theme.accent)
                        scale: toggleConnectMouse.pressed ? 0.92 : (toggleConnectMouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        readonly property color primaryContrast: ColorUtils.isDark(Theme.accent) ? "#ffffff" : "#000000"

                        RowLayout {
                            id: toggleConnectRow
                            anchors.centerIn: parent
                            spacing: 6

                            SvgIcon {
                                icon: toggleConnectBtn.isConnected ? "bluetooth-off" : "bluetooth"
                                iconSize: 13
                                flat: true
                                iconColor: toggleConnectBtn.isConnected ? Theme.fg : toggleConnectBtn.primaryContrast
                            }

                            ThemedText {
                                text: toggleConnectBtn.isConnected ? Translation.tr("Disconnect") : Translation.tr("Connect")
                                font.pixelSize: 12
                                font.bold: true
                                color: toggleConnectBtn.isConnected ? Theme.fg : toggleConnectBtn.primaryContrast
                            }
                        }

                        MouseArea {
                            id: toggleConnectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!deviceCard.modelData) return;
                                if (deviceCard.modelData.connected) {
                                    if (typeof deviceCard.modelData.disconnect === "function") {
                                        deviceCard.modelData.disconnect();
                                    } else {
                                        deviceCard.modelData.connected = false;
                                    }
                                } else {
                                    if (typeof deviceCard.modelData.connect === "function") {
                                        deviceCard.modelData.connect();
                                    } else {
                                        deviceCard.modelData.connected = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // UNNAMED DEVICES FOLD
    // ==========================================
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        visible: root.isEnabled && root.unnamedDevices.length > 0
        implicitWidth: unnamedRow.implicitWidth + 20
        implicitHeight: 28
        radius: 14
        color: unnamedMouse.containsMouse ? Theme.bgTertiary : "transparent"
        scale: unnamedMouse.pressed ? 0.94 : (unnamedMouse.containsMouse ? 1.04 : 1.0)

        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on color { ColorAnimation { duration: Constants.animFast } }

        RowLayout {
            id: unnamedRow
            anchors.centerIn: parent
            spacing: 6

            SvgIcon {
                icon: root.showUnnamed ? "chevron-up" : "chevron-down"
                iconSize: 12
                flat: true
                iconColor: unnamedMouse.containsMouse ? Theme.accent : Theme.muted
                Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
            }

            ThemedText {
                text: root.unnamedDevices.length === 1
                    ? "1 " + Translation.tr("unnamed device nearby")
                    : root.unnamedDevices.length + " " + Translation.tr("unnamed devices nearby")
                font.pixelSize: Constants.sizeXs
                color: unnamedMouse.containsMouse ? Theme.fg : Theme.muted
                Behavior on color { ColorAnimation { duration: Constants.animFast } }
            }
        }

        MouseArea {
            id: unnamedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showUnnamed = !root.showUnnamed
        }
    }
}
