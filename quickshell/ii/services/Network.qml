pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false
    property bool ethernetConnected: false
    property string ethernetName: ""
    property string ethernetStatus: "disconnected"
    property string ethernetDevice: ""

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength
    property string materialSymbol: (root.ethernet || root.ethernetConnected)
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        root.wifiEnabled = enabled;
        Quickshell.execDetached(["nmcli", "radio", "wifi", cmd]);
        enableWifiTimer.restart();
    }

    Timer {
        id: enableWifiTimer
        interval: 300
        repeat: false
        onTriggered: {
            wifiStatusProcess.running = true;
            updateConnectionType.startCheck();
            if (root.wifiEnabled) {
                getNetworks.running = true;
            }
        }
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        if (!accessPoint) return;
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", accessPoint.ssid]);
    }

    function connectWithPassword(accessPoint: WifiAccessPoint, password: string): void {
        if (!accessPoint) return;
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", accessPoint.ssid, "password", password]);
        Qt.callLater(() => {
            updateConnectionType.startCheck();
            getNetworks.running = true;
        });
    }

    function disconnectWifiNetwork(): void {
        if (active) Quickshell.execDetached(["nmcli", "connection", "down", active.ssid]);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        network.askingPassword = false;
        Quickshell.execDetached(["nmcli", "connection", "modify", network.ssid, "wifi-sec.psk", password]);
    }

    Process {
        id: enableWifiProc
        onExited: (exitCode, exitStatus) => {
            wifiStatusProcess.running = true;
            updateConnectionType.startCheck();
            if (root.wifiEnabled) {
                getNetworks.running = true;
            }
        }
    }

    Process {
        id: connectProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                // print(line)
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                // print("err:", line)
                if (line.includes("Secrets were required") || line.includes("password")) {
                    if (root.wifiConnectTarget) {
                        root.wifiConnectTarget.askingPassword = true;
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = (exitCode !== 0);
            }
            root.wifiConnectTarget = null;
            root.update();
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: changePasswordProc
        onExited: { // Re-attempt connection after changing password
            connectProc.running = false
            connectProc.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "LANG=C LC_ALL=C nmcli -t -f TYPE,STATE,CONNECTION,DEVICE d status && LANG=C LC_ALL=C nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop(); // none, limited, full
            let hasEthernet = false;
            let ethernetName = "";
            let ethernetDevice = "";
            let ethernetStatus = "disconnected";
            let hasWifi = false;
            let wifiStatus = "disconnected";

            lines.forEach(rawLine => {
                const line = rawLine.replace(/\\:/g, "__COLON__");
                const parts = line.split(":").map(p => p.replace(/__COLON__/g, ":"));
                const type = parts[0] || "";
                const state = parts[1] || "";
                const connection = parts[2] || "";
                const device = parts[3] || "";

                if (type === "ethernet") {
                    ethernetDevice = device;
                    ethernetStatus = state;
                    if (state.includes("connected") || state.includes("conectado")) {
                        hasEthernet = true;
                        ethernetName = connection || device || "Ethernet";
                    } else if (!ethernetName && connection) {
                        ethernetName = connection;
                    }
                } else if (type.startsWith("wifi")) {
                    if (type === "wifi-p2p") return;
                    if (state.includes("disconnected") || state.includes("desconectado")) {
                        wifiStatus = "disconnected";
                    } else if (state.includes("connected") || state.includes("conectado")) {
                        hasWifi = true;
                        wifiStatus = "connected";

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited";
                        }
                    } else if (state.includes("connecting") || state.includes("conectando")) {
                        wifiStatus = "connecting";
                    } else if (state.includes("unavailable") || state.includes("unmanaged") || state.includes("no disponible")) {
                        wifiStatus = "disabled";
                    }
                }
            });

            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.ethernetConnected = hasEthernet;
            root.ethernetName = ethernetName;
            root.ethernetStatus = ethernetStatus;
            root.ethernetDevice = ethernetDevice;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "LANG=C LC_ALL=C nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "LANG=C LC_ALL=C nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["sh", "-c", "LANG=C LC_ALL=C nmcli radio wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["sh", "-c", "LANG=C LC_ALL=C nmcli -g ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY d w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}
