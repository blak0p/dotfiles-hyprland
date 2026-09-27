// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B R I G H T N E S S   S E R V I C E                                    │
// │   backlight level · watched on sysfs, set through brightnessctl          │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight level, watched on sysfs so the OSD also reacts to the hardware
// brightness keys. Supports sysfs and brightnessctl seamlessly.
Singleton {
    id: root

    property string device: ""
    property int raw: 100
    property int maximum: 100
    property int percent: root.maximum > 0 ? Math.round(root.raw / root.maximum * 100) : 100

    readonly property bool available: true

    readonly property string icon: {
        if (root.percent < 34)
            return "󰃞"
        return root.percent < 67 ? "󰃟" : "󰃠"
    }

    readonly property Process discovery: Process {
        command: ["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name !== "") {
                    root.device = name
                } else {
                    root.queryProc.running = true
                }
            }
        }
    }

    readonly property Process queryProc: Process {
        command: ["sh", "-c", "echo \"$(brightnessctl g 2>/dev/null || echo 100) $(brightnessctl m 2>/dev/null || echo 100)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    const cur = parseInt(parts[0]) || 100
                    const max = parseInt(parts[1]) || 100
                    if (max > 0) {
                        root.maximum = max
                        root.raw = cur
                        root.percent = Math.round(cur / max * 100)
                    }
                }
            }
        }
    }

    readonly property FileView maxView: FileView {
        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/max_brightness`
        onLoaded: {
            const val = parseInt(text().trim()) || 0
            if (val > 0)
                root.maximum = val
        }
    }

    readonly property FileView levelView: FileView {
        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/brightness`
        watchChanges: true
        onLoaded: {
            const val = parseInt(text().trim()) || 0
            if (val > 0) {
                root.raw = val
                if (root.maximum > 0)
                    root.percent = Math.round(val / root.maximum * 100)
            }
        }
        onFileChanged: reload()
    }

    readonly property Process setter: Process {}

    function setPercent(value: int): void {
        const clamped = Math.max(1, Math.min(100, value))
        root.percent = clamped
        if (root.maximum > 0)
            root.raw = Math.round(clamped / 100 * root.maximum)

        if (root.device !== "") {
            root.setter.command = ["brightnessctl", "-d", root.device, "--quiet", "set", `${clamped}%`]
            root.setter.running = false
            root.setter.running = true
        } else {
            Quickshell.execDetached(["bash", "-c", `hyprctl hyprsunset gamma ${clamped} 2>/dev/null || true`])
        }
    }
}
