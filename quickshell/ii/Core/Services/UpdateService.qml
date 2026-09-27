import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: updateService

    property bool updateProcessRunning: false
    readonly property bool isSystemUpdating: updateProcessRunning
    property bool packageManagerChecksEnabled: true
    property int packageManagerCheckInterval: 3.6e+06
    property string cachyUpdatesCount: "..."
    property string homebrewUpdatesCount: "..."
    property bool checkRequested: false
    readonly property bool isCheckingUpdates: cachyUpdateProc.running || homebrewUpdateProc.running

    signal checkUpdates()

    function runSystemUpdate() {
        if (updateService.updateProcessRunning || updateProc.running)
            return false;

        const updateScript = Quickshell.env("HOME") + "/.config/quickshell/ii/Scripts/system_update.sh";
        updateProc.command = ["kitty", "--class", "kitty-floating", "-e", "bash", updateScript, "update"];
        updateService.updateProcessRunning = true;
        updateProc.running = true;
        return true;
    }

    function requestUpdateChecks() {
        updateService.checkRequested = true;
        if (!updateService.isCheckingUpdates)
            checkStartTimer.restart();
    }

    function scheduleQueuedCheck() {
        if (updateService.checkRequested && !updateService.isCheckingUpdates)
            checkStartTimer.restart();
    }

    function startUpdateChecks() {
        if (updateService.isCheckingUpdates)
            return;

        updateService.checkRequested = false;
        updateService.cachyUpdatesCount = "...";
        updateService.homebrewUpdatesCount = "...";
        cachyUpdateProc.running = true;
        homebrewUpdateProc.running = true;
        cachyCheckWatchdog.restart();
        homebrewCheckWatchdog.restart();
    }

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
            updateService.homebrewUpdatesCount = "...";
            checkDelayTimer.start();
        }
    }
    onCheckUpdates: updateService.requestUpdateChecks()

    Process {
        id: updateProc

        onExited: updateService.updateProcessRunning = false
    }

    Process {
        id: cachyUpdateProc

        command: ["sh", "-c", "if command -v cachy-update >/dev/null 2>&1; then cachy-update --list 2>/dev/null | grep -c ' -> ' || true; elif command -v checkupdates >/dev/null 2>&1 || command -v yay >/dev/null 2>&1; then (checkupdates 2>/dev/null; yay -Qua 2>/dev/null) | sort -u | grep -v '^[[:space:]]*$' | wc -l; elif command -v dnf >/dev/null 2>&1; then dnf check-update -q 2>/dev/null | grep -v '^[[:space:]]*$' | wc -l; elif command -v apt >/dev/null 2>&1; then apt list --upgradable 2>/dev/null | grep -v '^Listing' | grep -v '^[[:space:]]*$' | wc -l; elif command -v zypper >/dev/null 2>&1; then zypper list-updates 2>/dev/null | grep -c '^v' || true; else echo '0'; fi"]

        stdout: SplitParser {
            onRead: (data) => {
                const count = data.trim();
                updateService.cachyUpdatesCount = /^\d+$/.test(count) ? count : "0";
            }
        }

        onExited: {
            cachyCheckWatchdog.stop();
            if (!/^\d+$/.test(updateService.cachyUpdatesCount))
                updateService.cachyUpdatesCount = "0";
            updateService.scheduleQueuedCheck();
        }
    }

    Process {
        id: homebrewUpdateProc

        command: ["sh", "-c", "brew_path=\"$(command -v brew >/dev/null 2>&1 && command -v brew || true)\"; if [ -z \"$brew_path\" ] || [ ! -x \"$brew_path\" ]; then for candidate in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do if [ -x \"$candidate\" ]; then brew_path=\"$candidate\"; break; fi; done; fi; if [ -n \"$brew_path\" ]; then if brew_output=\"$(\"$brew_path\" outdated --quiet 2>/dev/null)\"; then printf '%s\\n' \"$brew_output\" | awk 'NF { count++ } END { print count + 0 }'; else echo 0; fi; else echo 0; fi"]

        stdout: SplitParser {
            onRead: (data) => {
                const count = data.trim();
                updateService.homebrewUpdatesCount = /^\d+$/.test(count) ? count : "0";
            }
        }

        onExited: {
            homebrewCheckWatchdog.stop();
            if (!/^\d+$/.test(updateService.homebrewUpdatesCount))
                updateService.homebrewUpdatesCount = "0";
            updateService.scheduleQueuedCheck();
        }
    }

    Timer {
        id: cachyCheckWatchdog

        interval: 60000
        repeat: false
        onTriggered: {
            if (cachyUpdateProc.running) {
                updateService.cachyUpdatesCount = "0";
                cachyUpdateProc.running = false;
            }
        }
    }

    Timer {
        id: homebrewCheckWatchdog

        interval: 60000
        repeat: false
        onTriggered: {
            if (homebrewUpdateProc.running) {
                updateService.homebrewUpdatesCount = "0";
                homebrewUpdateProc.running = false;
            }
        }
    }

    Timer {
        id: checkStartTimer

        interval: 50
        repeat: false
        onTriggered: updateService.startUpdateChecks()
    }

    Timer {
        id: hourlyUpdateTimer

        interval: updateService.packageManagerCheckInterval
        running: updateService.packageManagerChecksEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: updateService.requestUpdateChecks()
    }

    Timer {
        id: checkDelayTimer

        interval: 800
        repeat: false
        onTriggered: updateService.requestUpdateChecks()
    }

}
