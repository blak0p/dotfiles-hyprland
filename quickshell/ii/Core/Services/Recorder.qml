import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    property bool running: false

    function toggle(args) {
        if (args === undefined)
            args = [];

        let cmd = [`${Quickshell.env("HOME")}/.config/quickshell/Scripts/record.sh`].concat(args);
        Quickshell.execDetached(cmd);
        checkDelay.restart();
    }

    Timer {
        id: checkTimer

        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            checkProc.running = false;
            checkProc.running = true;
        }
    }

    Timer {
        id: checkDelay

        interval: 150
        repeat: false
        onTriggered: {
            checkProc.running = false;
            checkProc.running = true;
        }
    }

    Process {
        id: checkProc

        command: ["pidof", "wf-recorder"]
        onExited: (code) => {
            root.running = (code === 0);
        }
    }

}
