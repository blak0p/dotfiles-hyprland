import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Windows

TopPopup {
    id: root

    property var currentTrayItem: null

    contentWidth: Math.max(250, Math.min(trayMenu.implicitWidth, 450))
    contentHeight: Math.min(trayMenu.implicitHeight, 300)
    onIsOpenChanged: {
        if (!isOpen)
            trayMenu.resetToRoot();

    }

    TrayMenu {
        id: trayMenu

        width: parent.width
        Layout.preferredHeight: root.contentHeight
        menuHandle: root.currentTrayItem ? root.currentTrayItem.menu : null
        title: {
            let item = root.currentTrayItem;
            if (!item)
                return "Menu";

            let t = item.title ? item.title.toString().trim() : "";
            if (t !== "")
                return t;

            let tt = item.toolTipTitle ? item.toolTipTitle.toString().trim() : "";
            if (tt !== "")
                return tt;

            let id = item.id ? item.id.toString().trim() : "";
            if (id !== "" && !id.startsWith("org.kde.StatusNotifier")) {
                let clean = id.replace(/_status_icon_\d+$/i, "");
                clean = clean.replace(/[-_]/g, " ");
                clean = clean.split(" ").map((w) => {
                    return w.charAt(0).toUpperCase() + w.slice(1);
                }).join(" ");
                return clean.trim();
            }
            return "Menu";
        }
        onBackRequested: root.isOpen = false
        onCloseRequested: root.isOpen = false
    }

}
