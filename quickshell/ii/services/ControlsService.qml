pragma Singleton

import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

import qs.Core
import qs.Core.Services
import qs.services
import qs.modules.common

// Control centre layout service managing doors, toggles, and the 3-column blocks grid.
Singleton {
    id: root

    // ── DOORS ───────────────────────────────────────────────────────────────
    readonly property var doors: [
        { id: "wifi",          icon: "󰖩", label: "Wi-Fi",                 panel: "wifi" },
        { id: "bluetooth",     icon: "󰂯", label: "Bluetooth",             panel: "bluetooth" },
        { id: "audio",         icon: "󰕾", label: "Audio & Mixer",         panel: "audio" },
        { id: "notifications", icon: "󰂚", label: "Notifications",         panel: "notifications" },
        { id: "calendar",      icon: "󰃭", label: "Calendar",              panel: "calendar" },
        { id: "tasks",         icon: "󰄲", label: "Tasks & Todo",          panel: "tasks" },
        { id: "widgets",       icon: "󱂠", label: "Widgets",                panel: "widgets" },
        { id: "pomodoro",      icon: "󰔛", label: "Pomodoro",             panel: "pomodoro" },
        { id: "settings",      icon: "󰒓", label: "Settings",              panel: "" }
    ]

    readonly property var defaultButtons: ["wifi", "bluetooth", "audio", "notifications", "widgets", "settings"]

    function stored(value: var): bool {
        return value !== null && value !== undefined && typeof value.length === "number"
    }

    readonly property var buttons: {
        const kept = SettingsService.centreButtons
        const list = root.stored(kept) ? kept : root.defaultButtons
        return list.filter(id => root.door(id) !== null)
    }

    function door(id: string): var {
        return root.doors.find(entry => entry.id === id) ?? null
    }

    readonly property var shownDoors: root.buttons.map(id => root.door(id))

    // ── TOGGLES CATALOGUE ───────────────────────────────────────────────────
    component Toggle: QtObject {
        property string key: ""
        property string icon: ""
        property string label: ""
        property string detail: ""
        property bool active: false
        property bool available: true
        property bool expandable: false
        property string panel: ""
        property bool closes: false
        property var action: null

        function activate(): void {
            if (root.editing || !available)
                return
            if (action)
                action()
        }
    }

    readonly property bool airborne: !Network.wifiEnabled && !BluetoothStatus.enabled

    readonly property list<QtObject> toggleCatalogue: [
        Toggle {
            key: "wifi"
            icon: Network.wifiEnabled ? "󰖩" : "󰖪"
            label: Translation.tr("Wi-Fi")
            detail: Network.wifiEnabled ? (Network.networkName || Translation.tr("Connected")) : Translation.tr("Disconnected")
            active: Network.wifiEnabled
            expandable: true
            panel: "wifi"
            action: () => Network.toggleWifi()
        },
        Toggle {
            key: "bluetooth"
            icon: BluetoothStatus.enabled ? "󰂯" : "󰂲"
            label: Translation.tr("Bluetooth")
            detail: BluetoothStatus.connected
                ? (BluetoothStatus.firstActiveDevice?.name || Translation.tr("Connected"))
                : (BluetoothStatus.enabled ? Translation.tr("On") : Translation.tr("Off"))
            active: BluetoothStatus.enabled
            available: BluetoothStatus.available
            expandable: BluetoothStatus.available
            panel: "bluetooth"
            action: () => {
                if (typeof Bluetooth !== "undefined" && Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                }
            }
        },
        Toggle {
            key: "power"
            icon: "󰓅"
            label: Translation.tr("Power")
            detail: {
                const p = SystemInfoService.powerProfile
                if (!p) return Translation.tr("Balanced")
                if (p === "power-saver") return Translation.tr("Power Saver")
                if (p === "performance") return Translation.tr("Performance")
                return Translation.tr("Balanced")
            }
            active: SystemInfoService.powerProfile === "performance"
            available: true
            action: () => {
                if (SystemInfoService.powerProfile === "power-saver")
                    SystemInfoService.applyProfile("balanced");
                else if (SystemInfoService.powerProfile === "balanced")
                    SystemInfoService.applyProfile("performance");
                else
                    SystemInfoService.applyProfile("power-saver");
            }
        },
        Toggle {
            key: "focus"
            icon: Notifications.silent ? "󰂛" : "󰂚"
            label: (typeof Translation !== "undefined" && Translation.languageCode && Translation.languageCode.startsWith("es")) ? "Modo silencio" : Translation.tr("Silent Mode")
            detail: Notifications.silent
                ? ((typeof Translation !== "undefined" && Translation.languageCode && Translation.languageCode.startsWith("es")) ? "Silenciado" : Translation.tr("Silenced"))
                : ((typeof Translation !== "undefined" && Translation.languageCode && Translation.languageCode.startsWith("es")) ? "Notificando" : Translation.tr("Notifying"))
            active: Notifications.silent
            available: true
            action: () => {
                Notifications.silent = !Notifications.silent;
                SettingsService.set("doNotDisturb", Notifications.silent);
            }
        },
        Toggle {
            key: "microphone"
            icon: ((Audio.source && Audio.source.audio && Audio.source.audio.muted) ? true : false) ? "󰍭" : "󰍬"
            label: Translation.tr("Microphone")
            detail: ((Audio.source && Audio.source.audio && Audio.source.audio.muted) ? true : false) ? Translation.tr("Muted") : Translation.tr("Live")
            active: !((Audio.source && Audio.source.audio && Audio.source.audio.muted) ? true : false)
            available: Audio.source !== null
            action: () => Audio.toggleMicMute()
        },
        Toggle {
            key: "airplane"
            icon: root.airborne ? "󰀝" : "󰀞"
            label: Translation.tr("Airplane Mode")
            detail: root.airborne ? Translation.tr("Radios off") : Translation.tr("Radios on")
            active: root.airborne
            action: () => {
                const turnOff = !root.airborne;
                if (turnOff) {
                    if (Network.wifiEnabled) Network.toggleWifi();
                    if (BluetoothStatus.enabled && typeof Bluetooth !== "undefined" && Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = false;
                } else {
                    if (!Network.wifiEnabled) Network.toggleWifi();
                    if (!BluetoothStatus.enabled && typeof Bluetooth !== "undefined" && Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = true;
                }
            }
        },
        Toggle {
            key: "nightlight"
            icon: Boolean(Hyprsunset.temperatureActive) ? "󰖔" : "󰖙"
            label: Translation.tr("Night Light")
            detail: Boolean(Hyprsunset.temperatureActive) ? Translation.tr("Warm") : Translation.tr("Daylight")
            active: Boolean(Hyprsunset.temperatureActive)
            available: true
            action: () => Hyprsunset.toggleTemperature()
        },
        Toggle {
            key: "output"
            icon: (Audio.sink?.audio?.muted ?? false) ? "󰝟" : "󰕾"
            label: Translation.tr("Audio Output")
            detail: (Audio.sink?.audio?.muted ?? false) ? Translation.tr("Muted") : `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
            active: !(Audio.sink?.audio?.muted ?? false)
            available: Audio.ready
            expandable: true
            panel: "audio"
            action: () => Audio.toggleMute()
        }
    ]

    readonly property var defaultToggles: ["wifi", "bluetooth", "power", "focus", "microphone", "nightlight"]

    function tileOf(key: string): var {
        for (let i = 0; i < root.toggleCatalogue.length; i++) {
            const tile = root.toggleCatalogue[i]
            if (tile.key === key)
                return tile
        }
        return null
    }

    readonly property var toggleKeys: {
        const kept = SettingsService.centreToggles
        const list = root.stored(kept) ? kept : root.defaultToggles
        return Array.from(list).filter(key => root.tileOf(key) !== null)
    }

    function toggleKeysOf(key: string): var {
        const block = root.entryOf(key)
        const own = block ? block.toggles : undefined
        const list = root.stored(own) ? Array.from(own) : root.toggleKeys
        return list.filter(tile => root.tileOf(tile) !== null)
    }

    function tilesOf(key: string): var {
        return root.toggleKeysOf(key).map(tile => root.tileOf(tile))
    }

    // ── BLOCKS CATALOGUE ────────────────────────────────────────────────────
    readonly property var catalogue: [
        { id: "toggles",       name: "Toggles",       icon: "󰨚", sizes: ["2x2", "2x3", "2x4", "3x2", "3x3", "4x2", "4x3"] },
        { id: "volume",        name: "Volume",        icon: "󰕾", sizes: ["2x1", "3x1", "4x1"] },
        { id: "brightness",    name: "Brightness",    icon: "󰃠", sizes: ["2x1", "3x1", "4x1"] },
        { id: "appearance",    name: "Appearance",    icon: "󰔏", sizes: ["2x2", "2x3", "2x4", "3x3", "4x2"] },
        { id: "media",         name: "Media",         icon: "󰝚", sizes: ["2x2", "2x3", "3x2", "4x2"] },
        { id: "weather",       name: "Weather",       icon: "󰖐", sizes: ["2x1", "2x2", "2x3", "4x2"] },
        { id: "calendar",      name: "Calendar",      icon: "󰃭", sizes: ["2x3", "2x4", "3x4"] },
        { id: "notifications", name: "Notifications", icon: "󰂚", sizes: ["2x4", "2x6", "2x8", "3x8"] },
        { id: "clock",         name: "Clock",         icon: "󰥔", sizes: ["1x2", "2x2", "2x4"] },
        { id: "tasks",         name: "Tasks",         icon: "󰄲", sizes: ["1x2", "2x2", "2x3", "2x4"] }
    ]

    // Balanced 2-column layout:
    // Col 0 (left):  Toggles (2x3) + Volume (2x1) + Brightness (2x1)
    // Col 2 (right): Weather (2x2) + Calendar (2x3)
    readonly property var defaultBlocks: [
        { id: "toggles",       col: 0, row: 0, size: "2x3" },
        { id: "volume",        col: 0, row: 3, size: "2x1" },
        { id: "brightness",    col: 0, row: 4, size: "2x1" },
        { id: "weather",       col: 2, row: 0, size: "2x2" },
        { id: "calendar",      col: 2, row: 2, size: "2x3" }
    ]

    function entry(id: string): var {
        return root.catalogue.find(item => item.id === id) ?? null
    }

    function sizesFor(id: string): var {
        const item = root.entry(id)
        return item ? item.sizes : ["2x2"]
    }

    function offers(id: string, size: string): bool {
        return root.sizesFor(id).indexOf(size) >= 0
    }

    function parse(size: string): var {
        const found = /^(\d+)x(\d+)$/.exec(size ?? "")
        return found
            ? { cols: parseInt(found[1]), rows: parseInt(found[2]) }
            : { cols: 2, rows: 2 }
    }

    function sizeOf(block: var): string {
        if (block && root.offers(block.id, block.size))
            return block.size
        return root.sizesFor(block ? block.id : "")[0]
    }

    // ── BOARD METRICS ───────────────────────────────────────────────────────
    readonly property int columns: 4
    readonly property int rows: 5
    readonly property int gutter: Theme.centreGutter || 12

    readonly property int cellWidth: (root.board && root.board.width > 200)
        ? Math.floor((root.board.width - (root.columns - 1) * root.gutter) / root.columns)
        : (Theme.centreCellWidth || 202)

    readonly property int cellHeight: (root.board && root.board.height > 200)
        ? Math.floor((root.board.height - (root.rows - 1) * root.gutter) / root.rows)
        : (Theme.centreCellHeight || 86)

    readonly property int strideX: root.cellWidth + root.gutter
    readonly property int strideY: root.cellHeight + root.gutter

    readonly property int boardWidth: root.columns * root.cellWidth + (root.columns - 1) * root.gutter
    readonly property int boardHeight: root.rows * root.cellHeight + (root.rows - 1) * root.gutter

    readonly property int rowHeight: 28
    readonly property int rowGap: 14

    readonly property int panelWidth: root.boardWidth + 2 * (Theme.panelPadding || 20)
    readonly property int panelHeight: root.boardHeight + root.rowHeight + root.rowGap + 2 * (Theme.panelPadding || 20)

    function offsetX(col: int): real {
        return col * root.strideX
    }

    function offsetY(row: int): real {
        return row * root.strideY
    }

    function pixels(size: string): var {
        const shape = root.parse(size)
        return {
            width: shape.cols * root.cellWidth + (shape.cols - 1) * root.gutter,
            height: shape.rows * root.cellHeight + (shape.rows - 1) * root.gutter
        }
    }

    function geometry(block: var): var {
        const size = root.sizeOf(block)
        const shape = root.parse(size)
        const box = root.pixels(size)
        const lastColumn = Math.max(0, root.columns - shape.cols)
        const lastRow = Math.max(0, root.rows - shape.rows)
        return {
            x: root.offsetX(Math.max(0, Math.min(lastColumn, block.col ?? 0))),
            y: root.offsetY(Math.max(0, Math.min(lastRow, block.row ?? 0))),
            width: box.width,
            height: box.height
        }
    }

    // ── LAYOUT DATA ─────────────────────────────────────────────────────────
    function normalise(list: var): var {
        const result = []
        const length = list && typeof list.length === "number" ? list.length : 0
        for (let i = 0; i < length; i++) {
            const kept = list[i]
            if (!kept || root.entry(kept.id) === null)
                continue
            const r = Object.assign({}, kept)
            if (!r.key)
                r.key = r.id
            result.push(r)
        }
        return result
    }

    function read(): var {
        const kept = SettingsService.centreBlocks
        return root.normalise(root.stored(kept) ? kept : root.defaultBlocks)
    }

    property var blocks: root.read()

    Connections {
        target: SettingsService
        function onCentreBlocksChanged(): void {
            if (saver.running)
                return
            root.blocks = root.read()
        }
    }

    readonly property Timer saver: Timer {
        interval: 120
        onTriggered: SettingsService.set("centreBlocks", root.blocks)
    }

    property var keys: []

    onBlocksChanged: root.syncKeys()
    Component.onCompleted: root.syncKeys()

    function syncKeys(): void {
        const next = root.blocks.map(block => block.key)
        if (next.length === root.keys.length && next.every((k, i) => k === root.keys[i]))
            return
        root.keys = next
    }

    function entryOf(key: string): var {
        return root.blocks.find(block => block.key === key) ?? null
    }

    // ── COLLISIONS & POSITIONING ────────────────────────────────────────────
    function overlaps(col: int, row: int, size: string, exceptKey: string): bool {
        const shape = root.parse(size)
        for (let i = 0; i < root.blocks.length; i++) {
            const other = root.blocks[i]
            if (other.key === exceptKey)
                continue
            const theirs = root.parse(root.sizeOf(other))
            const theirCol = other.col ?? 0
            const theirRow = other.row ?? 0
            if (col < theirCol + theirs.cols && theirCol < col + shape.cols &&
                row < theirRow + theirs.rows && theirRow < row + shape.rows)
                return true
        }
        return false
    }

    function onBoard(col: int, row: int, size: string): bool {
        const shape = root.parse(size)
        return col >= 0 && row >= 0 &&
               col + shape.cols <= root.columns &&
               row + shape.rows <= root.rows
    }

    function free(col: int, row: int, size: string, exceptKey: string): bool {
        return root.onBoard(col, row, size) && !root.overlaps(col, row, size, exceptKey)
    }

    function nearestFree(col: int, row: int, size: string, exceptKey: string): var {
        if (root.free(col, row, size, exceptKey))
            return { col: col, row: row }
        let best = null
        let bestDistance = Infinity
        for (let c = 0; c < root.columns; c++) {
            for (let r = 0; r < root.rows; r++) {
                if (!root.free(c, r, size, exceptKey))
                    continue
                const dist = (c - col) * (c - col) + (r - row) * (r - row)
                if (dist < bestDistance) {
                    bestDistance = dist
                    best = { col: c, row: r }
                }
            }
        }
        return best
    }

    function firstFree(size: string, exceptKey: string): var {
        for (let r = 0; r < root.rows; r++) {
            for (let c = 0; c < root.columns; c++) {
                if (root.free(c, r, size, exceptKey))
                    return { col: c, row: r }
            }
        }
        return null
    }

    function cellX(pos: real): int {
        return Math.round(pos / root.strideX)
    }

    function cellY(pos: real): int {
        return Math.round(pos / root.strideY)
    }

    // ── MUTATIONS ───────────────────────────────────────────────────────────
    function write(next: var): void {
        root.blocks = next
        saver.restart()
    }

    function update(key: string, changes: var): void {
        root.write(root.blocks.map(b => b.key === key ? Object.assign({}, b, changes) : b))
    }

    function newKey(id: string): string {
        for (let n = 1; ; n++) {
            const key = `${id}-${n}`
            if (!root.entryOf(key))
                return key
        }
    }

    function add(id: string, col = -1, row = -1): string {
        if (root.entry(id) === null)
            return ""
        const size = root.sizesFor(id)[0]
        const spot = col >= 0 ? root.nearestFree(col, row, size, "") : root.firstFree(size, "")
        if (!spot)
            return ""
        const key = root.newKey(id)
        root.write(root.blocks.concat([{ key: key, id: id, col: spot.col, row: spot.row, size: size }]))
        return key
    }

    function remove(key: string): void {
        root.write(root.blocks.filter(b => b.key !== key))
        if (root.selected === key)
            root.selected = ""
    }

    function place(key: string, col: int, row: int): void {
        const block = root.entryOf(key)
        if (!block)
            return
        const spot = root.nearestFree(col, row, root.sizeOf(block), key)
        if (!spot)
            return
        root.update(key, { col: spot.col, row: spot.row })
    }

    function setSize(key: string, size: string): void {
        const block = root.entryOf(key)
        if (!block || !root.offers(block.id, size))
            return
        if (root.sizeOf(block) === size)
            return
        const spot = root.nearestFree(block.col ?? 0, block.row ?? 0, size, key)
        if (!spot)
            return
        root.update(key, { size: size, col: spot.col, row: spot.row })
    }

    function restore(): void {
        SettingsService.set("centreBlocks", null)
    }

    // ── EDITING STATE ───────────────────────────────────────────────────────
    property bool editing: false
    property string dragging: ""
    property string selected: ""
    property var landing: null
    property Item board: null
    property Item tray: null
    property var galleryAt: null
    property var gallerySize: null

    function overTray(x: real, y: real): bool {
        if (!root.tray || !root.board)
            return false
        const at = root.tray.mapFromItem(root.board, x, y)
        return at.x >= 0 && at.x <= root.tray.width && at.y >= 0 && at.y <= root.tray.height
    }

    function edit(on: bool): void {
        root.editing = on
        root.selected = ""
        if (!on) {
            root.dragging = ""
            root.landing = null
            root.galleryAt = null
        }
    }
}
