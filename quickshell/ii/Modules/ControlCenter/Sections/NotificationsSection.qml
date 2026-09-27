import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300
    property bool canGoBack: false
    signal back()

    spacing: 12

    function formatRelativeTime(timestamp) {
        if (!timestamp) return "";
        var now = Date.now();
        var diffMs = Math.max(0, now - Number(timestamp));
        if (diffMs < 60000) return Translation.tr("Just now");
        var mins = Math.floor(diffMs / 60000);
        if (mins < 60) return "Hace " + mins + "m";
        var hours = Math.floor(diffMs / 3600000);
        if (hours < 24) return Qt.formatDateTime(new Date(Number(timestamp)), "HH:mm");
        var days = Math.floor(diffMs / 86400000);
        if (days < 7) return "Hace " + days + "d";
        return Qt.formatDateTime(new Date(Number(timestamp)), "dd/MM");
    }

    function formatImageUrl(img) {
        if (!img || img === "") return "";
        if (img.startsWith("file://") || img.startsWith("http://") || img.startsWith("https://") || img.startsWith("image://")) return img;
        if (img.startsWith("/")) return "file://" + img;
        return img;
    }

    function resolveAppIcon(appIcon, appName) {
        if (appIcon && appIcon !== "") {
            if (appIcon.startsWith("file://") || appIcon.startsWith("http://") || appIcon.startsWith("https://") || appIcon.startsWith("image://")) {
                return appIcon;
            }
            if (appIcon.startsWith("/")) {
                return "file://" + appIcon;
            }
            let directPath = Quickshell.iconPath(appIcon, true);
            if (directPath && directPath.length > 0) return directPath;

            let entry = DesktopEntries.byId(appIcon);
            if (entry && entry.icon) {
                let p = Quickshell.iconPath(entry.icon, true);
                if (p && p.length > 0) return p;
            }
        }

        if (appName && appName !== "") {
            let lower = appName.toLowerCase().trim();

            let entry = DesktopEntries.byId(lower);
            if (entry && entry.icon) {
                let p = Quickshell.iconPath(entry.icon, true);
                if (p && p.length > 0) return p;
            }

            let directPath = Quickshell.iconPath(lower, true);
            if (directPath && directPath.length > 0) return directPath;

            const appMap = {
                "telegram": "telegram",
                "telegram desktop": "telegram",
                "discord": "discord",
                "vesktop": "vesktop",
                "spotify": "spotify",
                "firefox": "firefox",
                "chrome": "google-chrome",
                "chromium": "chromium",
                "brave": "brave-browser",
                "steam": "steam",
                "obs": "obs",
                "vlc": "vlc",
                "mpv": "mpv",
                "code": "code",
                "visual studio code": "code",
                "vscodium": "vscodium",
                "terminal": "utilities-terminal",
                "kitty": "kitty",
                "alacritty": "alacritty",
                "foot": "foot",
                "ghostty": "ghostty",
                "wezterm": "org.wezfurlong.wezterm"
            };
            if (appMap[lower]) {
                let p = Quickshell.iconPath(appMap[lower], true);
                if (p && p.length > 0) return p;
            }

            const cliTools = [
                "herdr", "pi", "agy", "bash", "zsh", "sh", "python", "python3",
                "node", "cargo", "rustc", "git", "gcc", "g++", "clang", "make",
                "ninja", "docker", "tmux", "zellij", "pacman", "yay", "paru",
                "apt", "curl", "wget", "shell", "terminal", "cli"
            ];
            if (cliTools.includes(lower) || lower.endsWith("sh") || lower.includes("term") || lower.includes("cli")) {
                let termIcon = Quickshell.iconPath("utilities-terminal", true) || Quickshell.iconPath("terminal", true);
                if (termIcon && termIcon.length > 0) return termIcon;
            }
        }

        return "";
    }

    // ==========================================
    // 1. ENCABEZADO Y ACCIONES GLOBALES
    // ==========================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Botón Volver (<)
        Rectangle {
            visible: root.canGoBack
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.bgTertiary : "transparent"
            scale: backMouse.pressed ? 0.88 : (backMouse.containsMouse ? 1.12 : 1.0)

            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-left"
                iconSize: 14
                iconColor: backMouse.containsMouse ? Theme.accent : Theme.fg
                flat: true
                Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        // Título + Badge Chip Contador
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            ThemedText {
                text: Translation.tr("Notifications")
                font.pixelSize: Constants.sizeXl
                font.bold: true
                color: Theme.fg
            }

            Rectangle {
                Layout.preferredHeight: 22
                implicitWidth: badgeCountText.implicitWidth + 14
                radius: 11
                color: Notifications.list.length > 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Notifications.list.length > 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color { ColorAnimation { duration: Constants.animFast } }
                Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                ThemedText {
                    id: badgeCountText
                    anchors.centerIn: parent
                    text: Notifications.list.length.toString()
                    font.pixelSize: 12
                    font.bold: true
                    color: Notifications.list.length > 0 ? Theme.accent : Theme.muted
                    Behavior on color { ColorAnimation { duration: Constants.animFast } }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Botón / Toggle Do Not Disturb (DND)
        Rectangle {
            id: dndBtn
            Layout.preferredHeight: 34
            implicitWidth: dndRow.implicitWidth + 22
            radius: 17
            color: Notifications.silent
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                : (dndMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
            border.width: 1
            border.color: Notifications.silent
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                : Qt.rgba(1, 1, 1, 0.06)
            scale: dndMouse.pressed ? 0.92 : (dndMouse.containsMouse ? 1.05 : 1.0)

            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

            RowLayout {
                id: dndRow
                anchors.centerIn: parent
                spacing: 8

                SvgIcon {
                    icon: Notifications.silent ? "bell-off" : "bell"
                    iconSize: 16
                    flat: true
                    iconColor: Notifications.silent ? Theme.accent : (dndMouse.containsMouse ? Theme.fg : Theme.muted)
                    Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                }

                ThemedText {
                    text: Translation.tr("Silent Mode")
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Notifications.silent ? Theme.accent : Theme.fg
                    Behavior on color { ColorAnimation { duration: Constants.animFast } }
                }
            }

            MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.silent = !Notifications.silent
            }
        }

        // Botón Limpiar Todo
        Rectangle {
            id: clearAllBtn
            Layout.preferredHeight: 34
            implicitWidth: clearAllRow.implicitWidth + 22
            radius: 17
            opacity: Notifications.list.length > 0 ? 1.0 : 0.45
            color: (clearAllMouse.containsMouse && Notifications.list.length > 0)
                ? Qt.rgba(1, 0.2, 0.2, 0.15)
                : Theme.bgSecondary
            border.width: 1
            border.color: (clearAllMouse.containsMouse && Notifications.list.length > 0)
                ? Qt.rgba(1, 0.2, 0.2, 0.35)
                : Qt.rgba(1, 1, 1, 0.06)
            scale: (clearAllMouse.pressed && Notifications.list.length > 0)
                ? 0.92
                : (clearAllMouse.containsMouse && Notifications.list.length > 0 ? 1.05 : 1.0)

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

            RowLayout {
                id: clearAllRow
                anchors.centerIn: parent
                spacing: 8

                SvgIcon {
                    icon: "trash"
                    iconSize: 16
                    flat: true
                    iconColor: (clearAllMouse.containsMouse && Notifications.list.length > 0) ? "#ff6b6b" : Theme.fg
                    Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                }

                ThemedText {
                    text: Translation.tr("Clear all")
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: (clearAllMouse.containsMouse && Notifications.list.length > 0) ? "#ff6b6b" : Theme.fg
                    Behavior on color { ColorAnimation { duration: Constants.animFast } }
                }
            }

            MouseArea {
                id: clearAllMouse
                anchors.fill: parent
                hoverEnabled: Notifications.list.length > 0
                cursorShape: Notifications.list.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (Notifications.list.length > 0) {
                        Notifications.discardAllNotifications();
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. EMPTY STATE
    // ==========================================
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 18
        color: Theme.bgSecondary
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.05)
        visible: Notifications.list.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            // Resplandor e icono de campana estilizada
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 32
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)

                SvgIcon {
                    anchors.centerIn: parent
                    icon: Notifications.silent ? "bell-off" : "bell"
                    iconSize: 28
                    flat: true
                    iconColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.75)
                }

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: Notifications.list.length === 0
                    NumberAnimation { to: 1.05; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Todo al día")
                    font.pixelSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.fg
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No hay notificaciones pendientes")
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }
    }

    // ==========================================
    // 3. LISTVIEW CON AGRUPACIÓN Y ACORDEÓN
    // ==========================================
    ListView {
        id: notifListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 12
        visible: Notifications.list.length > 0
        model: Notifications.appNameList
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.88; to: 1.0; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                NumberAnimation { property: "y"; from: -24; to: 0; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; to: 0.85; duration: 220; easing.type: Easing.OutCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: appGroupCard
            required property string modelData
            required property int index

            readonly property var groupData: (Notifications.groupsByAppName && modelData) ? Notifications.groupsByAppName[modelData] : null
            readonly property var notifsList: (groupData && groupData.notifications) ? groupData.notifications : []
            readonly property int notifCount: notifsList ? notifsList.length : 0
            readonly property bool isSingle: notifCount === 1

            property bool expanded: true
            property bool isDismissing: false

            Timer {
                id: cardDiscardTimer
                interval: 230
                repeat: false
                property var callback: null
                onTriggered: {
                    if (callback) callback();
                }
            }

            function discardGroup() {
                if (!groupData || !groupData.notifications) return;
                appGroupCard.isDismissing = true;
                cardDiscardTimer.callback = () => {
                    const notifs = [...groupData.notifications];
                    notifs.forEach((n) => {
                        Notifications.discardNotification(n.notificationId);
                    });
                };
                cardDiscardTimer.start();
            }

            function discardSingle(notifId) {
                appGroupCard.isDismissing = true;
                cardDiscardTimer.callback = () => {
                    Notifications.discardNotification(notifId);
                };
                cardDiscardTimer.start();
            }

            width: ListView.view.width
            implicitHeight: isSingle ? singleCardLayout.implicitHeight + 32 : groupCardLayout.implicitHeight + 32
            radius: 18
            color: cardHover.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
            border.width: 1
            border.color: cardHover.containsMouse
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                : Qt.rgba(1, 1, 1, 0.06)
            clip: true
            scale: isDismissing ? 0.85 : (cardHover.containsMouse ? 1.008 : 1.0)
            opacity: isDismissing ? 0.0 : 1.0

            Behavior on scale { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 230
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

            HoverHandler { id: cardHover }

            // ----------------------------------------------------
            // A. TARJETA COMPLETA PARA APLICACIÓN CON 1 NOTIFICACIÓN
            // ----------------------------------------------------
            ColumnLayout {
                id: singleCardLayout
                visible: appGroupCard.isSingle
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                readonly property var singleNotif: (appGroupCard.notifsList && appGroupCard.notifsList.length > 0) ? appGroupCard.notifsList[0] : null

                // Fila Superior: Icono de app + Nombre + Timestamp + Botón X
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // Icono de la App (36x36)
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        clip: true
                        Layout.alignment: Qt.AlignVCenter

                        readonly property string resolvedIcon: root.resolveAppIcon(
                            singleCardLayout.singleNotif ? singleCardLayout.singleNotif.appIcon : "",
                            singleCardLayout.singleNotif ? singleCardLayout.singleNotif.appName : ""
                        )

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            source: parent.resolvedIcon
                            visible: parent.resolvedIcon !== "" && status === Image.Ready
                        }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "bell"
                            iconSize: 18
                            flat: true
                            iconColor: Theme.accent
                            visible: !parent.resolvedIcon || parent.resolvedIcon === ""
                        }
                    }

                    // Nombre de app y Timestamp
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        ThemedText {
                            text: (singleCardLayout.singleNotif && singleCardLayout.singleNotif.appName) ? singleCardLayout.singleNotif.appName : Translation.tr("System")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.fg
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        ThemedText {
                            text: singleCardLayout.singleNotif ? root.formatRelativeTime(singleCardLayout.singleNotif.time) : ""
                            font.pixelSize: 12
                            color: Theme.muted
                            visible: text !== ""
                        }
                    }

                    // Botón Descarte Individual (X)
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: singleDismissMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.15) : "transparent"
                        scale: singleDismissMouse.pressed ? 0.85 : (singleDismissMouse.containsMouse ? 1.15 : 1.0)
                        rotation: singleDismissMouse.containsMouse ? 90 : 0

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "x"
                            iconSize: 13
                            flat: true
                            iconColor: singleDismissMouse.containsMouse ? "#ff6b6b" : Theme.muted
                            Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                        }

                        MouseArea {
                            id: singleDismissMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (singleCardLayout.singleNotif) {
                                    appGroupCard.discardSingle(singleCardLayout.singleNotif.notificationId);
                                }
                            }
                        }
                    }
                }

                // Título / Resumen (Summary)
                ThemedText {
                    Layout.fillWidth: true
                    text: (singleCardLayout.singleNotif && singleCardLayout.singleNotif.summary) ? singleCardLayout.singleNotif.summary : ""
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                // Cuerpo de la Notificación (Body)
                ThemedText {
                    Layout.fillWidth: true
                    text: (singleCardLayout.singleNotif && singleCardLayout.singleNotif.body) ? singleCardLayout.singleNotif.body : ""
                    font.pixelSize: 14
                    color: Theme.fg
                    opacity: 0.9
                    lineHeight: 1.25
                    lineHeightMode: Text.ProportionalHeight
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    visible: text !== ""
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }

                // Imagen Adjunta de la Notificación con Vista Previa y Animación
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 380
                    Layout.preferredHeight: 140
                    radius: 12
                    color: Theme.bgTertiary
                    border.width: 1
                    border.color: imgHover.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(1, 1, 1, 0.08)
                    clip: true
                    visible: Boolean(singleCardLayout.singleNotif && singleCardLayout.singleNotif.image && singleCardLayout.singleNotif.image !== "")
                    scale: imgHover.containsMouse ? 1.02 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    Image {
                        anchors.fill: parent
                        source: (singleCardLayout.singleNotif && singleCardLayout.singleNotif.image) ? root.formatImageUrl(singleCardLayout.singleNotif.image) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }

                    HoverHandler { id: imgHover; cursorShape: Qt.PointingHandCursor }

                    TapHandler {
                        onTapped: {
                            if (singleCardLayout.singleNotif && singleCardLayout.singleNotif.image) {
                                Qt.openUrlExternally(root.formatImageUrl(singleCardLayout.singleNotif.image));
                            }
                        }
                    }
                }

                // Botones de Acción Interactivos (si existen)
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: Boolean(singleCardLayout.singleNotif && singleCardLayout.singleNotif.actions && singleCardLayout.singleNotif.actions.length > 0)

                    Repeater {
                        model: (singleCardLayout.singleNotif && singleCardLayout.singleNotif.actions) ? singleCardLayout.singleNotif.actions : []

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            implicitHeight: 28
                            implicitWidth: singleActionText.implicitWidth + 18
                            radius: 14
                            color: singleActionMouse.containsMouse ? (Theme.bgTertiary || Qt.rgba(1, 1, 1, 0.16)) : Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.08)
                            border.width: 1
                            border.color: singleActionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                            scale: singleActionMouse.pressed ? 0.94 : (singleActionMouse.containsMouse ? 1.04 : 1.0)

                            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                            Behavior on color { ColorAnimation { duration: Constants.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                            ThemedText {
                                id: singleActionText
                                anchors.centerIn: parent
                                text: parent.modelData.text || parent.modelData.identifier || ""
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.fg
                                Behavior on color { ColorAnimation { duration: Constants.animFast } }
                            }

                            MouseArea {
                                id: singleActionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (singleCardLayout.singleNotif) {
                                        Notifications.attemptInvokeAction(singleCardLayout.singleNotif.notificationId, parent.modelData.identifier);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------
            // B. TARJETA DE GRUPO CON ACORDEÓN PARA MULTI-NOTIFICACIÓN
            // ----------------------------------------------------
            ColumnLayout {
                id: groupCardLayout
                visible: !appGroupCard.isSingle
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                readonly property var latestNotif: (appGroupCard.notifsList && appGroupCard.notifsList.length > 0)
                    ? appGroupCard.notifsList[appGroupCard.notifsList.length - 1]
                    : null

                // Encabezado del Grupo
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // Icono de la App
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        clip: true
                        Layout.alignment: Qt.AlignVCenter

                        readonly property string resolvedIcon: root.resolveAppIcon(
                            (appGroupCard.groupData && appGroupCard.groupData.appIcon) ? appGroupCard.groupData.appIcon : "",
                            (appGroupCard.groupData && appGroupCard.groupData.appName) ? appGroupCard.groupData.appName : ""
                        )

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            source: parent.resolvedIcon
                            visible: parent.resolvedIcon !== "" && status === Image.Ready
                        }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "bell"
                            iconSize: 18
                            flat: true
                            iconColor: Theme.accent
                            visible: !parent.resolvedIcon || parent.resolvedIcon === ""
                        }
                    }

                    // Nombre de la App + Badge de Conteo + Tiempo Relativo
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        ThemedText {
                            text: (appGroupCard.groupData && appGroupCard.groupData.appName) ? appGroupCard.groupData.appName : Translation.tr("System")
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        // Badge con conteo
                        Rectangle {
                            Layout.preferredHeight: 20
                            implicitWidth: countBadgeText.implicitWidth + 14
                            radius: 10
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)

                            ThemedText {
                                id: countBadgeText
                                anchors.centerIn: parent
                                text: appGroupCard.notifCount.toString()
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accent
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ThemedText {
                            text: appGroupCard.groupData ? root.formatRelativeTime(appGroupCard.groupData.time) : ""
                            font.pixelSize: 12
                            color: Theme.muted
                            visible: text !== ""
                        }
                    }

                    // Botón para descartar todo el grupo
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: groupDismissMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.15) : "transparent"
                        scale: groupDismissMouse.pressed ? 0.88 : (groupDismissMouse.containsMouse ? 1.15 : 1.0)

                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "trash"
                            iconSize: 13
                            flat: true
                            iconColor: groupDismissMouse.containsMouse ? "#ff6b6b" : Theme.muted
                            rotation: groupDismissMouse.containsMouse ? -12 : 0
                            Behavior on rotation { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                            Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                        }

                        MouseArea {
                            id: groupDismissMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appGroupCard.discardGroup();
                            }
                        }
                    }

                    // Flecha de Expansión Acordeón (Chevron)
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: expandArrowMouse.containsMouse ? Theme.bgTertiary : "transparent"
                        scale: expandArrowMouse.pressed ? 0.9 : 1.0

                        SvgIcon {
                            id: chevronIcon
                            anchors.centerIn: parent
                            icon: "chevron-down"
                            iconSize: 14
                            flat: true
                            iconColor: (expandArrowMouse.containsMouse || appGroupCard.expanded) ? Theme.accent : Theme.muted
                            rotation: appGroupCard.expanded ? 180 : 0

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.2
                                }
                            }
                            Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                        }

                        MouseArea {
                            id: expandArrowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appGroupCard.expanded = !appGroupCard.expanded;
                            }
                        }
                    }
                }

                // Teaser del mensaje más reciente (visible solo cuando !expanded)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: !appGroupCard.expanded

                    ThemedText {
                        Layout.fillWidth: true
                        text: (groupCardLayout.latestNotif && groupCardLayout.latestNotif.summary)
                            ? groupCardLayout.latestNotif.summary
                            : ((groupCardLayout.latestNotif && groupCardLayout.latestNotif.body) ? groupCardLayout.latestNotif.body : "")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.fg
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: text !== ""
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: (groupCardLayout.latestNotif && groupCardLayout.latestNotif.summary && groupCardLayout.latestNotif.body)
                            ? groupCardLayout.latestNotif.body
                            : ""
                        font.pixelSize: 13
                        color: Theme.muted
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: text !== ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            appGroupCard.expanded = true;
                        }
                    }
                }

                // Acordeón Desplegado: Lista de Notificaciones Individuales
                ColumnLayout {
                    id: accordionContent
                    Layout.fillWidth: true
                    spacing: 8
                    visible: appGroupCard.expanded

                    Repeater {
                        model: appGroupCard.notifsList ? appGroupCard.notifsList.slice().reverse() : []

                        delegate: Rectangle {
                            id: subNotifItem
                            required property var modelData
                            required property int index

                            property bool isDismissing: false

                            Layout.fillWidth: true
                            implicitHeight: isDismissing ? 0 : (subNotifCol.implicitHeight + 20)
                            scale: isDismissing ? 0.85 : 1.0
                            opacity: isDismissing ? 0.0 : 1.0
                            radius: 12
                            color: subHover.containsMouse ? Theme.bgSecondary : Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.04)
                            border.width: 1
                            border.color: subHover.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Qt.rgba(1, 1, 1, 0.04)
                            clip: true

                            Behavior on scale { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                            Behavior on implicitHeight { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Constants.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                            Timer {
                                id: subDiscardTimer
                                interval: 230
                                repeat: false
                                onTriggered: {
                                    if (subNotifItem.modelData && subNotifItem.modelData.notificationId !== undefined) {
                                        Notifications.discardNotification(subNotifItem.modelData.notificationId);
                                    }
                                }
                            }

                            HoverHandler { id: subHover }

                            ColumnLayout {
                                id: subNotifCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                // Sub-Header: Timestamp + Botón X
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter

                                    ThemedText {
                                        text: (subNotifItem.modelData && subNotifItem.modelData.time) ? root.formatRelativeTime(subNotifItem.modelData.time) : ""
                                        font.pixelSize: 11
                                        color: Theme.muted
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 11
                                        color: subDismissMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.15) : "transparent"
                                        scale: subDismissMouse.pressed ? 0.88 : (subDismissMouse.containsMouse ? 1.15 : 1.0)

                                        Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                                        SvgIcon {
                                            anchors.centerIn: parent
                                            icon: "x"
                                            iconSize: 11
                                            flat: true
                                            iconColor: subDismissMouse.containsMouse ? "#ff6b6b" : Theme.muted
                                            rotation: subDismissMouse.containsMouse ? 90 : 0
                                            Behavior on rotation { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                                            Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
                                        }

                                        MouseArea {
                                            id: subDismissMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                subNotifItem.isDismissing = true;
                                                subDiscardTimer.start();
                                            }
                                        }
                                    }
                                }

                                // Resumen / Título
                                ThemedText {
                                    Layout.fillWidth: true
                                    text: (subNotifItem.modelData && subNotifItem.modelData.summary) ? subNotifItem.modelData.summary : ""
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.fg
                                    wrapMode: Text.Wrap
                                    visible: text !== ""
                                }

                                // Cuerpo
                                ThemedText {
                                    Layout.fillWidth: true
                                    text: (subNotifItem.modelData && subNotifItem.modelData.body) ? subNotifItem.modelData.body : ""
                                    font.pixelSize: 13
                                    color: Theme.fg
                                    opacity: 0.9
                                    lineHeight: 1.2
                                    lineHeightMode: Text.ProportionalHeight
                                    wrapMode: Text.Wrap
                                    textFormat: Text.RichText
                                    visible: text !== ""
                                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                                }

                                // Imagen Adjunta (si existe)
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 360
                                    Layout.preferredHeight: 120
                                    radius: 10
                                    color: Theme.bgTertiary
                                    border.width: 1
                                    border.color: subImgHover.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(1, 1, 1, 0.08)
                                    clip: true
                                    visible: Boolean(subNotifItem.modelData && subNotifItem.modelData.image && subNotifItem.modelData.image !== "")
                                    scale: subImgHover.containsMouse ? 1.02 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Image {
                                        anchors.fill: parent
                                        source: (subNotifItem.modelData && subNotifItem.modelData.image) ? root.formatImageUrl(subNotifItem.modelData.image) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        smooth: true
                                    }

                                    HoverHandler { id: subImgHover; cursorShape: Qt.PointingHandCursor }

                                    TapHandler {
                                        onTapped: {
                                            if (subNotifItem.modelData && subNotifItem.modelData.image) {
                                                Qt.openUrlExternally(root.formatImageUrl(subNotifItem.modelData.image));
                                            }
                                        }
                                    }
                                }

                                // Botones de Acción Interactivos (si existen)
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: Boolean(subNotifItem.modelData && subNotifItem.modelData.actions && subNotifItem.modelData.actions.length > 0)

                                    Repeater {
                                        model: (subNotifItem.modelData && subNotifItem.modelData.actions) ? subNotifItem.modelData.actions : []

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            implicitHeight: 26
                                            implicitWidth: subActionText.implicitWidth + 16
                                            radius: 13
                                            color: subActionMouse.containsMouse ? (Theme.bgTertiary || Qt.rgba(1, 1, 1, 0.16)) : Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.08)
                                            border.width: 1
                                            border.color: subActionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                                            scale: subActionMouse.pressed ? 0.94 : (subActionMouse.containsMouse ? 1.04 : 1.0)

                                            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                                            Behavior on color { ColorAnimation { duration: Constants.animFast } }
                                            Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                                            ThemedText {
                                                id: subActionText
                                                anchors.centerIn: parent
                                                text: parent.modelData.text || parent.modelData.identifier || ""
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Theme.fg
                                                Behavior on color { ColorAnimation { duration: Constants.animFast } }
                                            }

                                            MouseArea {
                                                id: subActionMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (subNotifItem.modelData && subNotifItem.modelData.notificationId !== undefined) {
                                                        Notifications.attemptInvokeAction(subNotifItem.modelData.notificationId, parent.modelData.identifier);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
