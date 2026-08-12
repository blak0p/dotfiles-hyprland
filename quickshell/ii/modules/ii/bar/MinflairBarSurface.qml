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
import qs.Modules.PackageManager
import qs.Modules.PowerMenu
import qs.Core.Components
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
                readonly property int popupStartY: barMarginTop + barHeight

                Connections {
                    target: barStrip
                    function onClockHoveredChanged() {
                        surface.clockHovered = barStrip.clockHovered;
                        if (surface.clockHovered)
                            mainPanel.isOpen = true;
                    }
                }

                // The TopPopup auto-closes ~500ms after the cursor leaves it,
                // so keep it open while the cursor stays on the clock.
                Timer {
                    id: clockHoverKeepAlive
                    interval: 250
                    repeat: true
                    running: surface.clockHovered
                    onTriggered: mainPanel.isOpen = true
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
                        mainPanelWidget: mainPanel
                        x: surface.barMarginSide
                        y: surface.barMarginTop
                        width: barSurface.width - surface.barMarginSide * 2
                        height: surface.barHeight
                    }
                }

                // Popup window (dashboard + tray menus)
                PanelWindow {
                    id: popupSurface

                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    color: "transparent"
                    focusable: false
                    screen: surfaceLoader.modelData

                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }

                    MainPanel {
                        id: mainPanel
                        popupId: "dashboard"
                        x: (popupSurface.width - implicitWidth) / 2
                        y: surface.popupStartY
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
                            x: mainPanel.x
                            y: mainPanel.y
                            width: mainPanel._visible ? mainPanel.implicitWidth : 0
                            height: mainPanel._visible ? mainPanel.implicitHeight : 0
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
}
