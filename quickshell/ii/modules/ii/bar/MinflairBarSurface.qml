import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray as QSSysTray
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.Modules.Bar
import qs.Modules.Bar.Widgets.MainPanel
import qs.Modules.Bar.Widgets.SystemTray
import qs.Modules.Bar.Widgets.Launcher
import qs.Modules.Bar.Widgets.DynamicIsland
import qs.Modules.PackageManager
import qs.Modules.PowerMenu
import qs.Core.Components
import qs.Core.Services

import qs.Services.System

// Minflair-style bar + dashboard, grafted onto the End-4 ii shell.

Scope {
    id: root

    NotificationService {
        id: globalNotificationService
    }

    PopupLoader {
        popupId: "packagemanager"

        sourceComponent: Component {
            PackageManager {
            }
        }
    }

    PopupLoader {
        popupId: "powerMenu"

        sourceComponent: Component {
            PowerMenu {
            }
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: surfaceLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: Item {
                id: surface

                property bool clockHovered: false
                readonly property int barHeight: 48
                readonly property int barMarginTop: 8
                readonly property int barMarginSide: 8
                readonly property int popupStartY: barMarginTop + barHeight + 8

                Connections {
                    target: barStrip
                    function onClockHoveredChanged() {
                        surface.clockHovered = barStrip.clockHovered;
                        if (surface.clockHovered) {
                            if (AppState.activePopup === "launcher") {
                                AppState.activePopup = "dashboard";
                            }
                            mainPanel.isOpen = true;
                        }
                    }
                }

                // The TopPopup auto-closes ~500ms after the cursor leaves it,
                // so keep it open while the cursor stays on the clock.
                Timer {
                    id: clockHoverKeepAlive
                    interval: 250
                    repeat: true
                    running: surface.clockHovered
                    onTriggered: {
                        if (AppState.activePopup !== "launcher") {
                            mainPanel.isOpen = true;
                        }
                    }
                }

                // Bar window
                PanelWindow {
                    id: barSurface
                    screen: surfaceLoader.modelData

                    WlrLayershell.layer: WlrLayer.Top
                    color: "transparent"
                    focusable: false
                    implicitHeight: surface.barHeight + surface.barMarginTop

                    anchors {
                        top: !Config.options.bar.bottom
                        bottom: Config.options.bar.bottom
                        left: true
                        right: true
                    }

                    Bar {
                        id: barStrip
                        z: 1
                        notificationService: globalNotificationService
                        mainPanelWidget: unifiedIsland
                        x: surface.barMarginSide
                        y: surface.barMarginTop
                        width: barSurface.width - surface.barMarginSide * 2
                        height: surface.barHeight
                    }
                }

                // Popup window (Unified Dynamic Island + tray menus)
                PanelWindow {
                    id: popupSurface

                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.keyboardFocus: unifiedIsland.currentMode === "launcher" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                    color: "transparent"
                    focusable: unifiedIsland.currentMode === "launcher"
                    screen: surfaceLoader.modelData

                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }

                    UnifiedDynamicIsland {
                        id: unifiedIsland
                        x: (popupSurface.width - implicitWidth) / 2
                        y: surface.barMarginTop

                        onCurrentModeChanged: {
                            if (currentMode === "launcher" || currentMode === "dashboard") {
                                GlobalFocusGrab.addDismissable(popupSurface);
                            } else {
                                GlobalFocusGrab.removeDismissable(popupSurface);
                            }
                        }
                    }

                    Connections {
                        target: GlobalFocusGrab
                        function onDismissed() {
                            if (AppState.activePopup === "launcher" || AppState.activePopup === "dashboard") {
                                AppState.activePopup = "";
                            }
                        }
                    }

                    SystemTray {
                        id: trayPopup0
                        popupId: "systemTray_0"
                        currentTrayItem: QSSysTray.SystemTray.items.values[0]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup1
                        popupId: "systemTray_1"
                        currentTrayItem: QSSysTray.SystemTray.items.values[1]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup2
                        popupId: "systemTray_2"
                        currentTrayItem: QSSysTray.SystemTray.items.values[2]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup3
                        popupId: "systemTray_3"
                        currentTrayItem: QSSysTray.SystemTray.items.values[3]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup4
                        popupId: "systemTray_4"
                        currentTrayItem: QSSysTray.SystemTray.items.values[4]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup5
                        popupId: "systemTray_5"
                        currentTrayItem: QSSysTray.SystemTray.items.values[5]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup6
                        popupId: "systemTray_6"
                        currentTrayItem: QSSysTray.SystemTray.items.values[6]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }
                    SystemTray {
                        id: trayPopup7
                        popupId: "systemTray_7"
                        currentTrayItem: QSSysTray.SystemTray.items.values[7]
                        x: popupSurface.width - implicitWidth - surface.barMarginSide
                        y: surface.popupStartY
                    }

                    mask: Region {
                        Region {
                            x: unifiedIsland.x
                            y: unifiedIsland.y
                            width: unifiedIsland.width
                            height: unifiedIsland.height
                        }

                        Region {
                            x: trayPopup0.x
                            y: trayPopup0.y
                            width: trayPopup0._visible ? trayPopup0.implicitWidth : 0
                            height: trayPopup0._visible ? trayPopup0.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup1.x
                            y: trayPopup1.y
                            width: trayPopup1._visible ? trayPopup1.implicitWidth : 0
                            height: trayPopup1._visible ? trayPopup1.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup2.x
                            y: trayPopup2.y
                            width: trayPopup2._visible ? trayPopup2.implicitWidth : 0
                            height: trayPopup2._visible ? trayPopup2.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup3.x
                            y: trayPopup3.y
                            width: trayPopup3._visible ? trayPopup3.implicitWidth : 0
                            height: trayPopup3._visible ? trayPopup3.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup4.x
                            y: trayPopup4.y
                            width: trayPopup4._visible ? trayPopup4.implicitWidth : 0
                            height: trayPopup4._visible ? trayPopup4.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup5.x
                            y: trayPopup5.y
                            width: trayPopup5._visible ? trayPopup5.implicitWidth : 0
                            height: trayPopup5._visible ? trayPopup5.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup6.x
                            y: trayPopup6.y
                            width: trayPopup6._visible ? trayPopup6.implicitWidth : 0
                            height: trayPopup6._visible ? trayPopup6.implicitHeight : 0
                        }
                        Region {
                            x: trayPopup7.x
                            y: trayPopup7.y
                            width: trayPopup7._visible ? trayPopup7.implicitWidth : 0
                            height: trayPopup7._visible ? trayPopup7.implicitHeight : 0
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }

    IpcHandler {
        target: "search"

        function toggle(): void {
            AppState.togglePopup("launcher");
        }
        function open(): void {
            AppState.openPopup("launcher");
        }
        function close(): void {
            if (AppState.activePopup === "launcher")
                AppState.activePopup = "";
        }
        function workspacesToggle(): void {
            AppState.togglePopup("launcher");
        }
        function toggleReleaseInterrupt(): void {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle(): void {
            AppState.togglePopup("launcher");
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles launcher on press"
        onPressed: AppState.togglePopup("launcher")
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles launcher on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            AppState.togglePopup("launcher");
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts search toggle on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes launcher on press"
        onPressed: {
            if (AppState.activePopup === "launcher")
                AppState.activePopup = "";
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles launcher on press"
        onPressed: AppState.togglePopup("launcher")
    }
}

