pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services
import qs.Modules.Bar.Widgets.MainPanel.Dashboard as MainPanelDashboard
import qs.Modules.Bar.Widgets.MainPanel.Performance as MainPanelPerformance

Rectangle {
    id: root

    property string currentMode: {
        if (AppState.activePopup === "launcher") return "launcher";
        if (AppState.activePopup === "dashboard") return "dashboard";
        if (IslandState.activeNotification !== null && !IslandState.isClosed(IslandState.activeNotification)) return "notif";
        return "clock";
    }

    readonly property bool isNotifActive: currentMode === "notif"
    readonly property bool isCritical: isNotifActive && IslandState.isCritical(IslandState.activeNotification)
    readonly property bool isExpanded: currentMode === "launcher" || currentMode === "dashboard"

    width: implicitWidth
    height: implicitHeight
    radius: 24
    color: Theme.bg
    border.width: 1
    border.color: isCritical ? Theme.accent : (isNotifActive ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))
    clip: true

    implicitWidth: {
        if (currentMode === "dashboard") {
            if (dashboardActiveTab === 1) return 600;
            return 680;
        }
        if (currentMode === "launcher") return searchQuery !== "" ? 720 : 480;
        if (currentMode === "notif") return Math.min(480, Math.max(340, notifRow.implicitWidth + 36));
        return clockRow.implicitWidth + 36;
    }

    implicitHeight: {
        if (currentMode === "dashboard") {
            if (dashboardActiveTab === 0) return 590;
            if (dashboardActiveTab === 1) return 410;
            if (dashboardActiveTab === 2) return 500;
            return 580;
        }
        if (currentMode === "launcher") {
            if (searchQuery === "") return 48;
            if (searchModel.count === 0) return 170;
            return Math.min(540, 68 + Math.min(searchModel.count, 6) * 58);
        }
        return 48;
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.12
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: openDashboardTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root.currentMode === "clock" && clockHoverHandler.hovered) {
                AppState.activePopup = "dashboard";
            }
        }
    }

    Timer {
        id: autoCloseDashboardTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.currentMode === "dashboard" && !islandHoverHandler.hovered) {
                AppState.activePopup = "";
            }
        }
    }

    HoverHandler {
        id: islandHoverHandler
        onHoveredChanged: {
            if (root.currentMode === "dashboard") {
                if (hovered) {
                    autoCloseDashboardTimer.stop();
                } else {
                    autoCloseDashboardTimer.restart();
                }
            }
        }
    }

    // ==========================================
    // 1. CLOCK VIEW
    // ==========================================
    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        opacity: root.currentMode === "clock" ? 1 : 0
        scale: root.currentMode === "clock" ? 1 : 0.8
        visible: opacity > 0
        spacing: Constants.sizeXs

        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "HH:mm")
            font.bold: true
            font.pixelSize: Constants.sizeSm
        }

        Divider { vertical: true }

        ThemedText {
            text: Qt.formatDateTime(SystemInfoService.currentTime, "ddd, d MMM")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
        }
    }

    // Interactive hover & click for Clock to open Dashboard
    HoverHandler {
        id: clockHoverHandler
        enabled: root.currentMode === "clock"
        onHoveredChanged: {
            if (hovered) {
                openDashboardTimer.restart();
            } else {
                openDashboardTimer.stop();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.currentMode === "clock"
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            openDashboardTimer.stop();
            AppState.activePopup = "dashboard";
        }
    }

    // ==========================================
    // 2. NOTIFICATION VIEW (2-line compact)
    // ==========================================
    RowLayout {
        id: notifRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        opacity: root.currentMode === "notif" ? 1 : 0
        scale: root.currentMode === "notif" ? 1 : 0.85
        visible: opacity > 0
        spacing: Constants.sizeSm

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            NotificationIcon {
                anchors.fill: parent
                notifData: IslandState.activeNotification
                iconSize: 18
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.size2Xs

                ThemedText {
                    text: IslandState.activeNotification?.appName || "Notificación"
                    font.bold: true
                    font.pixelSize: Constants.sizeSm
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }

                ThemedText {
                    text: "•"
                    color: Theme.muted
                    font.pixelSize: Constants.size2Xs
                }

                ThemedText {
                    text: IslandState.activeNotification?.summary || ""
                    color: Theme.fg
                    font.pixelSize: Constants.sizeSm
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            ThemedText {
                text: (IslandState.activeNotification?.body || "").replace(/\n/g, " ")
                color: Theme.muted
                font.pixelSize: Constants.sizeXs
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.maximumWidth: 320
            }
        }

        Rectangle {
            visible: IslandState.queueCount > 0
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: badgeText.implicitWidth + 8
            radius: 9
            color: Theme.bgTertiary

            ThemedText {
                id: badgeText
                anchors.centerIn: parent
                text: "+" + IslandState.queueCount
                font.pixelSize: Constants.size3Xs
                font.bold: true
            }
        }

        SvgIconButton {
            icon: "x"
            iconSize: 12
            flat: true
            Layout.alignment: Qt.AlignVCenter
            onClicked: IslandState.dismissActive()
        }
    }

    // Notification progress line
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 46
        anchors.leftMargin: root.radius / 2
        height: 2
        radius: 1
        width: root.currentMode === "notif" ? Math.max(0, (parent.width - root.radius) * (IslandState.activeNotification?.progress ?? 0)) : 0
        color: root.isCritical ? Theme.accent : Theme.accentComplementary
        opacity: root.currentMode === "notif" && (IslandState.activeNotification?.progress !== undefined) ? 0.8 : 0
        visible: opacity > 0
    }

    // ==========================================
    // 3. LAUNCHER VIEW (Search Input & Results)
    // ==========================================
    property string searchQuery: ""
    property int selectedIndex: 0

    function resolveIcon(iconName) {
        if (!iconName || iconName === "") return "image://icon/application-x-executable";
        if (iconName.startsWith("image://") || iconName.startsWith("file://") || iconName.startsWith("/")) {
            return iconName;
        }
        const path = Quickshell.iconPath(iconName, true);
        if (path && path.length > 0) return path;
        const guessed = AppSearch.guessIcon(iconName);
        if (guessed && guessed.length > 0) {
            const guessPath = Quickshell.iconPath(guessed, true);
            if (guessPath && guessPath.length > 0) return guessPath;
        }
        return `image://icon/${iconName}`;
    }

    ListModel { id: searchModel }

    function updateSearchModel() {
        searchModel.clear();
        if (root.searchQuery === "") return;

        const results = AppSearch.fuzzyQuery(root.searchQuery);
        for (let i = 0; i < Math.min(results.length, 12); i++) {
            const entry = results[i];
            searchModel.append({
                name: entry.name || "",
                category: (entry.categories && entry.categories.length > 0) ? entry.categories[0] : (entry.comment || "Aplicación"),
                iconName: entry.icon || "application-x-executable",
                rawEntry: entry
            });
        }
    }

    function launchEntry(entry) {
        if (!entry) return;
        if (typeof entry.execute === "function") {
            entry.execute();
        } else if (entry.id) {
            AppSearch.launchApp(entry.id);
        } else if (entry.exec) {
            Quickshell.execDetached(entry.exec);
        }
        AppState.activePopup = "";
    }

    ColumnLayout {
        id: launcherColumn
        anchors.fill: parent
        anchors.margins: 0
        spacing: 8
        opacity: root.currentMode === "launcher" ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Top Search Row (48px)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 12

            SvgIcon {
                icon: "search"
                iconColor: searchInput.text !== "" ? Theme.accent : Theme.muted
                iconSize: 20
                flat: true
                Layout.alignment: Qt.AlignVCenter
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                focus: root.currentMode === "launcher"
                placeholderText: "Buscar aplicaciones, comandos (>)..."
                placeholderTextColor: Theme.muted
                font.family: Constants.fontFamily
                font.pixelSize: 14
                color: Theme.fg
                background: null
                leftPadding: 0
                rightPadding: 0

                onTextChanged: {
                    root.searchQuery = text;
                    root.selectedIndex = 0;
                    updateSearchModel();
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        if (text !== "") {
                            text = "";
                        } else {
                            AppState.activePopup = "";
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        if (searchListView.count > 0) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, searchListView.count - 1);
                            searchListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                        searchListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        event.accepted = true;
                    }
                }

                onAccepted: {
                    if (searchListView.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < searchListView.count) {
                        const item = searchModel.get(root.selectedIndex);
                        if (item && item.rawEntry) {
                            launchEntry(item.rawEntry);
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: 38
                Layout.alignment: Qt.AlignVCenter
                radius: 11
                color: Qt.rgba(1, 1, 1, 0.08)

                ThemedText {
                    anchors.centerIn: parent
                    text: "ESC"
                    font.pixelSize: Constants.size3Xs
                    font.bold: true
                    color: Theme.muted
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: AppState.activePopup = ""
                }
            }
        }

        Divider {
            Layout.fillWidth: true
            visible: root.searchQuery !== ""
        }

        // Search Results List
        ListView {
            id: searchListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8
            clip: true
            model: searchModel
            visible: root.searchQuery !== ""

            delegate: Rectangle {
                id: itemDelegate
                required property string name
                required property string category
                required property string iconName
                required property var rawEntry
                required property int index

                width: searchListView.width
                height: 52
                radius: Constants.sizeMd
                color: root.selectedIndex === index ? Theme.bgTertiary : (itemMouse.containsMouse ? Theme.bgSecondary : "transparent")

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selectedIndex = itemDelegate.index;
                        if (itemDelegate.rawEntry) {
                            launchEntry(itemDelegate.rawEntry);
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        source: root.resolveIcon(itemDelegate.iconName || "")
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        ThemedText {
                            text: itemDelegate.name || ""
                            font.bold: true
                            font.pixelSize: Constants.sizeSm
                        }

                        ThemedText {
                            text: itemDelegate.category || ""
                            color: Theme.muted
                            font.pixelSize: Constants.sizeXs
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // Reset search input on launcher opened
    onCurrentModeChanged: {
        if (currentMode === "launcher") {
            searchQuery = "";
            Qt.callLater(() => {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            });
        }
    }

    // ==========================================
    // 4. DASHBOARD VIEW (Tabs & Performance/Codex)
    // ==========================================
    property int dashboardActiveTab: 0

    ColumnLayout {
        id: dashboardColumn
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 4
        anchors.bottomMargin: 16
        spacing: Constants.sizeMd
        opacity: root.currentMode === "dashboard" ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Top Tabs Row (48px)
        ThemedTabs {
            id: headerRowItem
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            activeValue: root.dashboardActiveTab
            onTabSelected: (value) => root.dashboardActiveTab = value

            ThemedTab {
                glyph: root.dashboardActiveTab === 0 ? "dashboard-filled" : "dashboard"
                text: "Dashboard"
                value: 0
            }

            ThemedTab {
                glyph: root.dashboardActiveTab === 1 ? "performance-filled" : "performance"
                text: "Rendimiento"
                value: 1
            }

            ThemedTab {
                glyph: "code"
                text: "Codex"
                value: 2
            }
        }

        // Tab Contents
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MainPanelDashboard.Dashboard {
                id: dashboardTab
                anchors.fill: parent
                visible: root.dashboardActiveTab === 0
            }

            MainPanelPerformance.Performance {
                id: performanceTab
                anchors.fill: parent
                visible: root.dashboardActiveTab === 1
            }

            MainPanelDashboard.CodexBarCard {
                id: codexTab
                anchors.fill: parent
                visible: root.dashboardActiveTab === 2
                active: root.currentMode === "dashboard" && visible
            }
        }
    }
}
