import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.services

RowLayout {
    id: notifIconRoot
    property var notificationService
    spacing: 4

    readonly property int unreadCount: {
        if (typeof Notifications !== "undefined" && Notifications.list)
            return Notifications.list.length;
        if (notificationService && notificationService.unreadCount !== undefined)
            return notificationService.unreadCount;
        return 0;
    }

    readonly property bool isSilent: {
        if (typeof Notifications !== "undefined")
            return Notifications.silent;
        return notificationService?.dndEnabled ?? false;
    }

    SvgIcon {
        icon: notifIconRoot.isSilent ? "bell-off" : (notifIconRoot.unreadCount > 0 ? "bell-dot" : "bell")
        iconColor: notifIconRoot.isSilent ? Theme.muted : (notifIconRoot.unreadCount > 0 ? Theme.accent : Theme.fg)
        iconSize: Constants.sizeLg
        flat: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        visible: notifIconRoot.unreadCount > 0
        Layout.preferredHeight: 16
        Layout.preferredWidth: Math.max(16, countText.implicitWidth + 8)
        radius: 8
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter

        ThemedText {
            id: countText
            anchors.centerIn: parent
            text: notifIconRoot.unreadCount > 99 ? "99+" : notifIconRoot.unreadCount.toString()
            font.pixelSize: 10
            font.bold: true
            color: Theme.bg
        }
    }
}
