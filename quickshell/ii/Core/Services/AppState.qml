import QtQuick
import Quickshell
import qs.Core
pragma Singleton

Item {
    id: appState

    property string activePopup: ""
    property int pendingSettingsTab: -1
    property var activeTrayItem: null
    property real activeTrayX: 0

    signal togglePopup(string popupId)
    signal openPopup(string popupId)

    function toggleTrayMenu(trayItem, targetX) {
        if (activePopup === "systemTray" && activeTrayItem === trayItem) {
            activeTrayItem = null;
            togglePopup("systemTray");
        } else {
            activeTrayItem = trayItem;
            if (targetX !== undefined)
                activeTrayX = targetX;
            openPopup("systemTray");
        }
    }

    onTogglePopup: (popupId) => {
        if (popupId !== "systemTray")
            activeTrayItem = null;
        activePopup = (activePopup === popupId ? "" : popupId);
    }

    onOpenPopup: (popupId) => {
        if (popupId !== "systemTray")
            activeTrayItem = null;
        activePopup = popupId;
    }

    function formatTime(seconds) {
        if (seconds <= 0)
            return "Calculating...";

        let hours = Math.floor(seconds / 3600);
        let mins = Math.floor((seconds % 3600) / 60);
        if (hours > 0)
            return hours + "h " + mins + "m";
        else
            return mins + "m";
    }
}
