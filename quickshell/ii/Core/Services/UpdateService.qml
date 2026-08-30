import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: updateService

    property bool isSystemUpdating: false
    property bool packageManagerChecksEnabled: true
    property int packageManagerCheckInterval: 3.6e+06
    property string cachyUpdatesCount: "..."
    readonly property bool isCheckingUpdates: cachyUpdateProc.running

    signal checkUpdates()

    onPackageManagerChecksEnabledChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onPackageManagerCheckIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onIsSystemUpdatingChanged: {
        if (!updateService.isSystemUpdating) {
            updateService.cachyUpdatesCount = "...";
            checkDelayTimer.start();
        }
    }
    onCheckUpdates: {
        cachyUpdateProc.running = false;
        cachyUpdateProc.running = true;
    }

    Process {
        id: cachyUpdateProc

        command: ["sh", "-c", "cachy-update --list 2>/dev/null | grep -c ' -> ' || true"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.cachyUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: checkLockProc

        command: ["test", "-f", "/var/lib/pacman/db.lck"]
        onExited: (code) => {
            updateService.isSystemUpdating = (code === 0);
        }
    }

    Timer {
        id: lockCheckTimer

        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkLockProc.running = true;
        }
    }

    Timer {
        id: hourlyUpdateTimer

        interval: updateService.packageManagerCheckInterval
        running: updateService.packageManagerChecksEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cachyUpdateProc.running = false;
            cachyUpdateProc.running = true;
        }
    }

    Timer {
        id: checkDelayTimer

        interval: 800
        repeat: false
        onTriggered: {
            cachyUpdateProc.running = false;
            cachyUpdateProc.running = true;
        }
    }

}
