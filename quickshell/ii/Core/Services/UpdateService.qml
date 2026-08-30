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

        command: ["sh", "-c", "if command -v cachy-update &>/dev/null; then cachy-update --list 2>/dev/null | grep -c ' -> ' || true; elif command -v checkupdates &>/dev/null || command -v yay &>/dev/null; then (checkupdates 2>/dev/null; yay -Qua 2>/dev/null) | sort -u | grep -v '^[[:space:]]*$' | wc -l; elif command -v dnf &>/dev/null; then dnf check-update -q 2>/dev/null | grep -v '^[[:space:]]*$' | wc -l; elif command -v apt &>/dev/null; then apt list --upgradable 2>/dev/null | grep -v '^Listing' | grep -v '^[[:space:]]*$' | wc -l; elif command -v zypper &>/dev/null; then zypper list-updates 2>/dev/null | grep -c '^v' || true; else echo '0'; fi"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.cachyUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: checkLockProc

        command: ["sh", "-c", "test -f /var/lib/pacman/db.lck || test -f /var/run/dnf.pid || test -f /var/lib/dnf/transaction.lock || test -f /var/lib/dpkg/lock-frontend || test -f /var/lib/apt/lists/lock"]
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
