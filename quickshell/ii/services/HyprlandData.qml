pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Fullscreen gate for Dynamic Island. Primary source is Hyprland's wayland fullscreen
    // (covers both hyprland fullscreen SUPER+F and apps requesting fullscreen via wayland).
    // Falls back to hyprctl windowList for cases where Toplevel hasn't updated yet.
    readonly property bool hasFullscreen: {
        // Check active workspaces for a wayland-fullscreen toplevel (same logic as Background.qml / MinflairBarSurface)
        const wsList = Hyprland.workspaces.values;
        for (let i = 0; i < wsList.length; i++) {
            const ws = wsList[i];
            if (!ws.active) continue;
            const tops = ws.toplevels.values;
            for (let j = 0; j < tops.length; j++) {
                if (tops[j].wayland?.fullscreen) return true;
            }
        }
        // Fallback: hyprctl windowList (hidden/mapped aware)
        return windowList.some(w => {
            const fs = w.fullscreenMode === 2 || w.fullscreenMode === 1 || w.fullscreen === true || w.fullscreen === 1 || w.fullscreen === 2;
            if (!fs) return false;
            if (w.hidden) return false;
            if (w.mapped === false) return false;
            return true;
        });
    }

    // Per-monitor check so switching workspace on DP-2 doesn't get suppressed by a fullscreen on HDMI
    function hasFullscreenOnMonitor(monitorId) {
        // Try wayland fullscreen on that monitor first
        const wsList = Hyprland.workspaces.values;
        for (let i = 0; i < wsList.length; i++) {
            const ws = wsList[i];
            if (!ws.active) continue;
            if (!ws.monitor || ws.monitor.id !== monitorId) continue;
            const tops = ws.toplevels.values;
            for (let j = 0; j < tops.length; j++) {
                if (tops[j].wayland?.fullscreen) return true;
            }
        }
        return windowList.some(w => {
            const fs = w.fullscreenMode === 2 || w.fullscreenMode === 1 || w.fullscreen === true || w.fullscreen === 1 || w.fullscreen === 2;
            if (!fs) return false;
            if (w.hidden) return false;
            if (w.mapped === false) return false;
            return w.monitor === monitorId;
        });
    }

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Internals

    function updateWindowList() {
        getClients.running = true;
    }

    function updateLayers() {
        getLayers.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // console.log("Hyprland raw event:", event.name);
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return;
            updateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var rawWorkspaces = JSON.parse(workspacesCollector.text);
                // Filter out invalid workspace ids (e.g. lock-screen temp workspace 2147483647 - N)
                root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}
