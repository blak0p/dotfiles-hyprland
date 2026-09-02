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
        // Fallback: hyprctl windowList (hidden/mapped aware, only active workspaces)
        const activeIdsAll = Hyprland.workspaces.values.filter(ws => ws.active).map(ws => ws.id);
        return windowList.some(w => {
            const fs = w.fullscreenMode === 2 || w.fullscreenMode === 1 || w.fullscreen === true || w.fullscreen === 1 || w.fullscreen === 2;
            if (!fs) return false;
            if (w.hidden) return false;
            if (w.mapped === false) return false;
            if (!activeIdsAll.includes(w.workspace.id)) return false;
            return true;
        });
    }

    // Per-monitor check so switching workspace on DP-2 doesn't get suppressed by a fullscreen on HDMI
    // Covers both hyprland fullscreen (SUPER+F) and wayland fullscreen (F11) via multiple sources.
    function hasFullscreenOnMonitor(monitorId) {
        // Resolve monitor name for fallback matching (Hyprland id vs hyprctl id can differ)
        let monName = null;
        for (let m = 0; m < monitors.length; m++) if (monitors[m].id === monitorId) { monName = monitors[m].name; break; }
        if (monName === null) {
            const hm = Hyprland.monitors.values.find(mm => mm.id === monitorId);
            if (hm) monName = hm.name;
        }
        // 1) Hyprland workspaces + wayland fullscreen (most reliable for SUPER+F)
        const wsList = Hyprland.workspaces.values;
        for (let i = 0; i < wsList.length; i++) {
            const ws = wsList[i];
            if (!ws.active) continue;
            const m = ws.monitor;
            if (!m) continue;
            if (m.id !== monitorId && m.name !== monName) continue;
            const tops = ws.toplevels.values;
            for (let j = 0; j < tops.length; j++) {
                if (tops[j].wayland?.fullscreen) return true;
            }
        }
        // 2) ToplevelManager direct (covers F11 wayland fullscreen even when Hyprland workspace not yet updated)
        // Only count if the toplevel's workspace is active on that monitor
        const allTops = ToplevelManager.toplevels.values;
        for (let k = 0; k < allTops.length; k++) {
            const t = allTops[k];
            if (!t.wayland?.fullscreen) continue;
            const c = HyprlandData.windowByAddress["0x" + t.HyprlandToplevel?.address];
            if (!c || c.hidden || c.mapped === false) continue;
            if (c.workspace) {
                const ws = Hyprland.workspaces.values.find(w => w.id === c.workspace.id);
                if (ws && ws.active) {
                    const wm = ws.monitor;
                    if (wm && (wm.id === monitorId || wm.name === monName)) return true;
                    if (c.monitor === monitorId) return true;
                }
            }
        }
        // Only count fullscreen windows whose workspace is currently active on that monitor
        const activeIds = Hyprland.workspaces.values.filter(ws => ws.active && ws.monitor && (ws.monitor.id === monitorId || ws.monitor.name === monName)).map(ws => ws.id);
        return windowList.some(w => {
            const fs = w.fullscreenMode === 2 || w.fullscreenMode === 1 || w.fullscreen === true || w.fullscreen === 1 || w.fullscreen === 2 || w.fullscreenClient === 1 || w.fullscreenClient === true;
            if (!fs) return false;
            if (w.hidden) return false;
            if (w.mapped === false) return false;
            if (w.monitor !== monitorId) {
                if (!monName) return false;
                const mon = monitors.find(mm => mm.id === w.monitor);
                if (!mon || mon.name !== monName) return false;
            }
            // Must be on an active workspace of this monitor, otherwise switching workspace would keep it hidden
            if (!activeIds.includes(w.workspace.id)) return false;
            return true;
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
