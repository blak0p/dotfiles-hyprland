// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E S S I O N   S E R V I C E                                          │
// │   lock, suspend, log out, reboot, shut down                              │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Session actions as data, rendered from one list. `destructive` marks the
// ones that end the session; PowerRow asks for confirmation, not this service.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",     icon: "󰌾", label: "Lock",      destructive: false },
        { id: "suspend",  icon: "󰤄", label: "Sleep",     destructive: false },
        { id: "logout",   icon: "󰗽", label: "Log out",   destructive: true },
        { id: "reboot",   icon: "󰜉", label: "Restart",   destructive: true },
        { id: "shutdown", icon: "󰐥", label: "Shut down", destructive: true }
    ]

    readonly property Process runner: Process {}

    // Suspend only after the compositor confirms the lock, so the machine
    // never wakes showing the desktop. No confirmation within five seconds
    // means no suspend.
    property bool suspendWhenLocked: false

    readonly property Timer suspendGiveUp: Timer {
        interval: 5000
        onTriggered: {
            if (!root.suspendWhenLocked)
                return
            root.suspendWhenLocked = false
            console.warn("The session did not lock; not suspending.")
        }
    }

    readonly property Connections lockWatch: Connections {
        target: LockService

        function onSecureChanged(): void {
            if (!LockService.secure || !root.suspendWhenLocked)
                return
            root.suspendWhenLocked = false
            root.suspendGiveUp.stop()
            root.exec(["systemctl", "suspend"])
        }
    }

    function run(actionId: string): void {
        switch (actionId) {
        case "lock":
            root.exec(["sh", "-c", "hyprlock || loginctl lock-session"])
            break
        case "suspend":
        case "sleep":
            root.exec(["systemctl", "suspend"])
            break
        case "logout":
            root.exec(["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER"])
            break
        case "reboot":
            root.exec(["systemctl", "reboot"])
            break
        case "shutdown":
        case "poweroff":
            root.exec(["systemctl", "poweroff"])
            break
        default:
            console.warn("Unknown session action:", actionId)
        }
    }

    function exec(command: var): void {
        Quickshell.execDetached(command)
    }
}

