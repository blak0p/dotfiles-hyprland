// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C O N T R O L S   P A N E L                                            │
// │   control centre · shortcut row and block grid                           │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import "./theme"
import "./services"
import "./components"
import "./controls"

// The control centre: a row of buttons over a grid of blocks
// (`ControlsService.blocks`) that the user arranges like desktop widgets.
//
// Right-click the background to arrange: drag blocks from the tray
// (`ControlsTray`, hung under the island by the bar) onto a cell, pull a
// corner or scroll to resize, and drop one back on the tray to remove it.
// Tiles that lead to a list (Wi-Fi, Bluetooth) open it as an island panel of
// its own, sized as a list rather than a block.
//
// Session actions sit at the left of the row and panel buttons at the right.
ColumnLayout {
    id: root

    signal closed()
    signal panelRequested(string panel)
    // Settings is a window this panel does not own; the request is passed up.
    signal settingsRequested()

    readonly property bool editing: ControlsService.editing

    spacing: ControlsService.rowGap

    // Escape leaves arranging first; otherwise it reaches the island, which
    // closes.
    Component.onCompleted: root.forceActiveFocus()

    Keys.onEscapePressed: event => {
        if (!root.editing) {
            event.accepted = false
            return
        }
        ControlsService.edit(false)
    }

    // Closing the panel ends arranging too, so it never reopens still in that
    // mode, swallowing clicks.
    Component.onDestruction: {
        ControlsService.edit(false)
        ControlsService.board = null
    }

    // ── TOP ROW ─────────────────────────────────────────────────────────────

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.preferredHeight: ControlsService.rowHeight
        spacing: 8

        PowerRow { onRan: root.closed() }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Center Pills: System Uptime, Ethernet, Notifications
        RowLayout {
            spacing: 8

            // 1. Distro & Uptime
            Rectangle {
                Layout.preferredHeight: 28
                implicitWidth: uptimeRow.implicitWidth + 24
                radius: 14
                color: Theme.islandSurface || Theme.bgSecondary
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    id: uptimeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: (SystemInfo.distroName || "CachyOS") + " - " + DateTime.uptime
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall || 11
                        font.weight: Font.DemiBold
                        color: Theme.text || Theme.fg
                    }
                }
            }

            // 2. Ethernet
            Rectangle {
                Layout.preferredHeight: 28
                implicitWidth: ethRow.implicitWidth + 20
                radius: 14
                color: ethMouse.containsMouse ? (Theme.islandSurfaceHover || Theme.bgTertiary) : (Theme.islandSurface || Theme.bgSecondary)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    id: ethRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰈀"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.text
                    }

                    Text {
                        text: Translation.tr("Ethernet")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall || 11
                        font.weight: Font.DemiBold
                        color: Theme.text || Theme.fg
                    }
                }

                MouseArea {
                    id: ethMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panelRequested("network")
                }
            }

            // 3. Notifications
            Rectangle {
                visible: true
                Layout.preferredHeight: 28
                implicitWidth: notifRow.implicitWidth + 20
                radius: 14
                color: notifMouse.containsMouse ? (Theme.islandSurfaceHover || Theme.bgTertiary) : (Theme.islandSurface || Theme.bgSecondary)
                border.width: 1
                border.color: (typeof Notifications !== "undefined" && Notifications.unread > 0)
                    ? Qt.rgba(1, 1, 1, 0.16)
                    : Qt.rgba(1, 1, 1, 0.08)
                scale: notifMouse.pressed ? 0.94 : (notifMouse.containsMouse ? 1.04 : 1.0)

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: notifRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: (typeof Notifications !== "undefined" && Notifications.unread > 0) ? "󰂞" : "󰂚"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.text || Theme.fg
                    }

                    Text {
                        text: Translation.tr("Notifications")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall || 11
                        font.weight: Font.DemiBold
                        color: Theme.text || Theme.fg
                    }

                    // Badge de notificaciones pendientes
                    Rectangle {
                        visible: typeof Notifications !== "undefined" && Notifications.unread > 0
                        Layout.preferredHeight: 18
                        implicitWidth: Math.max(18, notifBadgeText.implicitWidth + 8)
                        radius: 9
                        color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: notifBadgeText
                            anchors.centerIn: parent
                            text: (typeof Notifications !== "undefined")
                                ? (Notifications.unread > 99 ? "99+" : Notifications.unread.toString())
                                : "0"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.fg || "#ffffff"
                        }
                    }
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    z: 1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panelRequested("notifications")
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Right Actions (Appearance/Wallpaper, Settings, Close)
        RowLayout {
            spacing: 4

            IconButton {
                icon: "󰸉"
                iconSize: 14
                onClicked: root.panelRequested("appearance")
            }

            IconButton {
                icon: "󰒓"
                iconSize: 14
                onClicked: root.settingsRequested()
            }

            IconButton {
                icon: "󰅖"
                iconSize: 14
                onClicked: root.closed()
            }
        }
    }

    // ── GRID ────────────────────────────────────────────────────────────────

    // Not `board`, the name of the property the blocks are handed: an id and a
    // property with the same name in one scope resolve to the property.
    Item {
        id: surface

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Published for the tray, which lives outside this panel and maps the
        // pointer into these cells.
        Binding {
            target: ControlsService
            property: "board"
            value: surface
        }

        // Right-click on the background toggles arranging. Declared first,
        // beneath everything: blocks take the left button and the right one
        // falls through.
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: ControlsService.edit(!ControlsService.editing)
        }

        // Left-click on the background closes the inspector. A block's own
        // tap is exclusive from the press, so this never fires under one.
        TapHandler {
            enabled: root.editing
            acceptedButtons: Qt.LeftButton
            onTapped: ControlsService.selected = ""
        }

        // The cells, only while arranging.
        Loader {
            anchors.fill: parent
            active: root.editing
            sourceComponent: lattice
        }

        // The drop target, lit on the grid before the drop. Moved
        // imperatively rather than bound, so it appears in place and only
        // animates from cell to cell instead of sliding in from where it was
        // hidden.
        Rectangle {
            id: landing

            readonly property var spot: ControlsService.landing
            property bool showing: false

            visible: root.editing && landing.showing
            radius: Theme.radiusMedium
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
            border.color: Theme.accent
            border.width: 2

            onSpotChanged: {
                if (!landing.spot) {
                    landing.showing = false
                    return
                }
                const box = ControlsService.pixels(landing.spot.size)
                slide.enabled = landing.showing
                landing.x = ControlsService.offsetX(landing.spot.col)
                landing.y = ControlsService.offsetY(landing.spot.row)
                landing.width = box.width
                landing.height = box.height
                slide.enabled = true
                landing.showing = true
            }

            Behavior on x { id: slide; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
            Behavior on y { enabled: slide.enabled; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
            Behavior on width { enabled: slide.enabled; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
            Behavior on height { enabled: slide.enabled; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
        }

        // Keyed on block ids rather than rows: a Repeater given a new array
        // rebuilds every delegate, and the rows are a new array after every
        // drop. Ids change only when a block is added or removed, so the snap
        // animates and a playing track or a scrolled list survives a drag.
        Repeater {
            model: ControlsService.keys

            Block {
                board: surface
                onPanelRequested: panel => root.panelRequested(panel)
                onDismissed: root.closed()
            }
        }

        // The selected block's options, on a card beside it.
        Loader {
            anchors.fill: parent
            z: 5
            active: root.editing && ControlsService.selected !== ""
            sourceComponent: BlockInspector { board: surface }
        }
    }

    Component {
        id: lattice

        Item {
            Repeater {
                model: ControlsService.columns * ControlsService.rows

                Rectangle {
                    required property int index

                    x: ControlsService.offsetX(index % ControlsService.columns)
                    y: ControlsService.offsetY(Math.floor(index / ControlsService.columns))
                    width: ControlsService.cellWidth
                    height: ControlsService.cellHeight
                    radius: Theme.radiusSmall
                    color: "transparent"
                    border.color: Theme.hairline
                    border.width: 1
                }
            }
        }
    }
}
