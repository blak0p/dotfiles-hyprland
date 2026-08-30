pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common
import qs.Core
import qs.Core.Components
import qs.Core.Services

Scope {
    id: root

    readonly property int barTopMargin: 8
    readonly property int barHeight: 48

    // Collapsed dimensions (matching the clock capsule in the bar)
    readonly property int collapsedWidth: 190
    readonly property int collapsedHeight: 36
    readonly property int collapsedY: barTopMargin + Math.round((barHeight - collapsedHeight) / 2) // 14px
    readonly property int collapsedRadius: 18

    // Expanded dimensions (Dynamic Island open)
    readonly property int expandedWidth: 640
    readonly property int expandedHeight: LauncherSearch.query !== "" ? Math.min(520, Math.max(180, 110 + Math.min(searchModel.count, 7) * 56)) : 480
    readonly property int expandedY: barTopMargin
    readonly property int expandedRadius: 26

    property bool isIslandOpen: GlobalStates.overviewOpen
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

    function openIsland() {
        searchQuery = "";
        selectedIndex = 0;
        LauncherSearch.query = "";
        GlobalStates.overviewOpen = true;
    }

    function closeIsland() {
        GlobalStates.overviewOpen = false;
        searchQuery = "";
        LauncherSearch.query = "";
    }

    function launchApp(entry) {
        if (!entry) return;
        if (typeof entry.execute === "function") {
            entry.execute();
        } else if (entry.id) {
            AppSearch.launchApp(entry.id);
        } else if (entry.exec) {
            Quickshell.execDetached(entry.exec);
        }
        root.closeIsland();
    }

    PanelWindow {
        id: islandWindow

        visible: GlobalStates.overviewOpen || islandCard.opacity > 0.01
        WlrLayershell.namespace: "quickshell:dynamic-island-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: GlobalStates.overviewOpen ? islandCard : null
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (GlobalStates.overviewOpen) {
                    GlobalFocusGrab.addDismissable(islandWindow);
                    Qt.callLater(() => {
                        searchInput.forceActiveFocus();
                    });
                } else {
                    GlobalFocusGrab.dismiss();
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                root.closeIsland();
            }
        }

        // Morphing Dynamic Island Capsule
        Rectangle {
            id: islandCard

            anchors.horizontalCenter: parent.horizontalCenter
            y: root.isIslandOpen ? root.expandedY : root.collapsedY
            width: root.isIslandOpen ? root.expandedWidth : root.collapsedWidth
            height: root.isIslandOpen ? root.expandedHeight : root.collapsedHeight
            radius: root.isIslandOpen ? root.expandedRadius : root.collapsedRadius
            color: Theme.bg
            border.color: root.isIslandOpen ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.16) : "transparent"
            border.width: 1
            opacity: root.isIslandOpen ? 1.0 : 0.0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 320 : 0
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.12
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 300 : 0
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 300 : 0
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 260 : 0
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 180 : 0
                    easing.type: Easing.OutQuad
                }
            }

            // Keyboard navigation inside island
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    root.closeIsland();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    if (root.searchQuery !== "") {
                        if (searchListView.count > 0) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, searchListView.count - 1);
                            searchListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    } else {
                        if (appsGridView.count > 0) {
                            root.selectedIndex = Math.min(root.selectedIndex + 4, appsGridView.count - 1);
                            appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                        }
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (root.searchQuery !== "") {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                        searchListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                    } else {
                        root.selectedIndex = Math.max(root.selectedIndex - 4, 0);
                        appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.searchQuery !== "") {
                        if (searchListView.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < searchListView.count) {
                            const item = searchModel.get(root.selectedIndex);
                            if (item && item.rawEntry) {
                                root.launchApp(item.rawEntry);
                            }
                        }
                    } else {
                        if (appsGridView.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < appsGridView.count) {
                            const entry = AppSearch.list[root.selectedIndex];
                            if (entry) root.launchApp(entry);
                        }
                    }
                    event.accepted = true;
                }
            }

            // Internal Content
            ColumnLayout {
                id: islandLayout

                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                opacity: root.isIslandOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: (typeof HyprlandService !== "undefined" && HyprlandService.enableAnimations) ? 200 : 0
                        easing.type: Easing.OutQuad
                    }
                }

                // Apple-style Island Notch indicator
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.22)
                }

                // Search Bar Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 22
                    color: Theme.bgSecondary
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        SvgIcon {
                            icon: "search"
                            iconColor: Theme.muted
                            iconSize: 18
                            flat: true
                        }

                        TextField {
                            id: searchInput

                            Layout.fillWidth: true
                            focus: true
                            placeholderText: "Buscar aplicaciones o comandos..."
                            placeholderTextColor: Theme.muted
                            font.family: Constants.fontFamily
                            font.pixelSize: Constants.sizeMd
                            color: Theme.fg
                            selectByMouse: true
                            background: null

                            onTextChanged: {
                                root.searchQuery = text;
                                LauncherSearch.query = text;
                                root.selectedIndex = 0;
                                updateSearchModel();
                            }

                            onAccepted: {
                                if (root.searchQuery !== "" && searchListView.count > 0) {
                                    const item = searchModel.get(root.selectedIndex);
                                    if (item && item.rawEntry) {
                                        root.launchApp(item.rawEntry);
                                    }
                                }
                            }
                        }

                        // ESC / Clear Pill
                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: clearText.implicitWidth + 14
                            radius: 12
                            color: Theme.bgTertiary
                            visible: true

                            ThemedText {
                                id: clearText
                                anchors.centerIn: parent
                                text: root.searchQuery !== "" ? "ESC para borrar" : "ESC"
                                font.pixelSize: 10
                                color: Theme.muted
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.searchQuery !== "") {
                                        searchInput.text = "";
                                        searchInput.forceActiveFocus();
                                    } else {
                                        root.closeIsland();
                                    }
                                }
                            }
                        }
                    }
                }

                // Body Section
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // MODE 1: Grid of all applications (when query is empty)
                    ColumnLayout {
                        anchors.fill: parent
                        visible: root.searchQuery === ""
                        spacing: 10

                        // Section Title
                        RowLayout {
                            Layout.fillWidth: true
                            ThemedText {
                                text: "Aplicaciones"
                                font.bold: true
                                font.pixelSize: Constants.sizeSm
                                color: Theme.muted
                            }
                            Item { Layout.fillWidth: true }
                            ThemedText {
                                text: `${AppSearch.list.length} instaladas`
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }

                        GridView {
                            id: appsGridView

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: Math.floor(width / 4)
                            cellHeight: 88
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: AppSearch.list

                            delegate: Item {
                                required property var modelData
                                required property int index

                                width: appsGridView.cellWidth
                                height: appsGridView.cellHeight

                                Rectangle {
                                    id: appCard

                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 14
                                    color: (root.selectedIndex === index || appMouse.containsMouse) ? Theme.bgSecondary : "transparent"
                                    border.color: (root.selectedIndex === index) ? Theme.accent : "transparent"
                                    border.width: 1

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Image {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            source: root.resolveIcon(modelData.icon)
                                            sourceSize.width: 36
                                            sourceSize.height: 36
                                            smooth: true
                                        }

                                        ThemedText {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.maximumWidth: appCard.width - 12
                                            text: modelData.name
                                            font.pixelSize: 11
                                            font.bold: root.selectedIndex === index
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        id: appMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.selectedIndex = index
                                        onClicked: root.launchApp(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // MODE 2: Search Results List (when query is active)
                    ListView {
                        id: searchListView

                        anchors.fill: parent
                        visible: root.searchQuery !== ""
                        spacing: 6
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: searchModel

                        delegate: Rectangle {
                            required property string name
                            required property string category
                            required property string iconName
                            required property var rawEntry
                            required property int index

                            width: searchListView.width
                            height: 52
                            radius: 12
                            color: (root.selectedIndex === index || searchItemMouse.containsMouse) ? Theme.bgSecondary : "transparent"
                            border.color: (root.selectedIndex === index) ? Theme.accent : "transparent"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Image {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    source: root.resolveIcon(iconName)
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    smooth: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    ThemedText {
                                        text: name
                                        font.bold: true
                                        font.pixelSize: Constants.sizeSm
                                        elide: Text.ElideRight
                                    }

                                    ThemedText {
                                        text: category
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: launchBadge.implicitWidth + 12
                                    radius: 11
                                    color: (root.selectedIndex === index) ? Theme.accent : Theme.bgTertiary

                                    ThemedText {
                                        id: launchBadge
                                        anchors.centerIn: parent
                                        text: "Abrir ↵"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: (root.selectedIndex === index) ? Theme.bg : Theme.fg
                                    }
                                }
                            }

                            MouseArea {
                                id: searchItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: root.launchApp(rawEntry)
                            }
                        }
                    }
                }
            }
        }
    }

    // Search model population
    ListModel {
        id: searchModel
    }

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

    // Global shortcut and IPC compatibility
    IpcHandler {
        target: "search"

        function toggle() {
            if (GlobalStates.overviewOpen) {
                root.closeIsland();
            } else {
                root.openIsland();
            }
        }
        function open() { root.openIsland(); }
        function close() { root.closeIsland(); }
        function workspacesToggle() { toggle(); }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() { toggle(); }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles dynamic island launcher on press"
        onPressed: {
            if (GlobalStates.overviewOpen) root.closeIsland();
            else root.openIsland();
        }
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles dynamic island launcher on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            if (GlobalStates.overviewOpen) root.closeIsland();
            else root.openIsland();
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts search toggle on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes launcher on press"
        onPressed: root.closeIsland()
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles launcher on press"
        onPressed: {
            if (GlobalStates.overviewOpen) root.closeIsland();
            else root.openIsland();
        }
    }
}
