pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.services

TopPopup {
    id: launcherPopup

    popupId: "launcher"
    autoCloseOnUnhover: false
    preferredWidth: searchQuery !== "" ? 720 : 480
    preferredHeight: {
        if (searchQuery === "") return 68;
        if (searchModel.count === 0) return 170;
        return Math.min(540, 92 + Math.min(searchModel.count, 6) * 58);
    }

    property string searchQuery: ""
    property int selectedIndex: 0

    readonly property string searchIconName: {
        if (searchQuery.startsWith("=") || searchQuery.startsWith("calc")) return "calculate";
        if (searchQuery.startsWith(">") || searchQuery.startsWith("$") || searchQuery.startsWith("!")) return "terminal";
        if (searchQuery.startsWith("@") || searchQuery.startsWith("#")) return "category";
        if (searchQuery.startsWith("?") || searchQuery.startsWith("http")) return "travel_explore";
        if (searchQuery !== "") return "apps";
        return "search";
    }

    function highlightContent(content, query) {
        if (!query || query.length === 0 || content === query)
            return content;
        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();
        let result = "";
        let lastIndex = 0;
        let qIndex = 0;
        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                if (i > lastIndex) {
                    result += `<font color="` + Theme.muted + `">` + content.slice(lastIndex, i) + `</font>`;
                }
                result += `<b><font color="` + Theme.fg + `">` + content[i] + `</font></b>`;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        if (lastIndex < content.length) {
            result += `<font color="` + Theme.muted + `">` + content.slice(lastIndex) + `</font>`;
        }
        return result;
    }

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

    function launchApp(entry) {
        if (!entry) return;
        if (typeof entry.execute === "function") {
            entry.execute();
        } else if (entry.id) {
            AppSearch.launchApp(entry.id);
        } else if (entry.exec) {
            Quickshell.execDetached(entry.exec);
        }
        launcherPopup.isOpen = false;
        if (AppState.activePopup === launcherPopup.popupId) {
            AppState.activePopup = "";
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchQuery = "";
            selectedIndex = 0;
            LauncherSearch.query = "";
            Qt.callLater(() => {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            });
        }
    }

    ColumnLayout {
        id: mainLayout

        Layout.fillWidth: true
        spacing: 10

        // Search Bar Row (Integrated directly into Dynamic Island)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 12

            Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.minimumWidth: 26
                Layout.maximumWidth: 26
                Layout.alignment: Qt.AlignVCenter

                SvgIcon {
                    id: prefixIcon
                    anchors.centerIn: parent
                    icon: launcherPopup.searchIconName
                    iconColor: searchInput.text !== "" ? Theme.accent : Theme.muted
                    iconSize: 22
                    flat: true

                    Behavior on iconColor {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            TextField {
                id: searchInput

                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                focus: true
                placeholderText: launcherPopup.searchQuery === "" ? "Buscar apps, comandos (>), cálculos (=)..." : ""
                placeholderTextColor: Theme.muted
                font.family: Constants.fontFamily
                font.pixelSize: 14
                color: Theme.fg
                selectByMouse: true
                background: null
                leftPadding: 0
                rightPadding: 0

                onTextChanged: {
                    launcherPopup.searchQuery = text;
                    LauncherSearch.query = text;
                    launcherPopup.selectedIndex = 0;
                    updateSearchModel();
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        if (text !== "") {
                            text = "";
                        } else {
                            launcherPopup.isOpen = false;
                            if (AppState.activePopup === launcherPopup.popupId) AppState.activePopup = "";
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (launcherPopup.searchQuery !== "" && searchListView.count > 0 && launcherPopup.selectedIndex >= 0) {
                            const item = searchModel.get(launcherPopup.selectedIndex);
                            if (item && item.name) {
                                text = item.name;
                                cursorPosition = text.length;
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        if (launcherPopup.searchQuery !== "" && searchListView.count > 0) {
                            launcherPopup.selectedIndex = Math.min(launcherPopup.selectedIndex + 1, searchListView.count - 1);
                            searchListView.positionViewAtIndex(launcherPopup.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (launcherPopup.searchQuery !== "") {
                            launcherPopup.selectedIndex = Math.max(launcherPopup.selectedIndex - 1, 0);
                            searchListView.positionViewAtIndex(launcherPopup.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }
                }

                onAccepted: {
                    if (launcherPopup.searchQuery !== "") {
                        if (searchListView.count > 0 && launcherPopup.selectedIndex >= 0 && launcherPopup.selectedIndex < searchListView.count) {
                            const item = searchModel.get(launcherPopup.selectedIndex);
                            if (item && item.rawEntry) {
                                launcherPopup.launchApp(item.rawEntry);
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: clearText.implicitWidth + 14
                Layout.alignment: Qt.AlignVCenter
                radius: 12
                color: escMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                ThemedText {
                    id: clearText
                    anchors.centerIn: parent
                    text: launcherPopup.searchQuery !== "" ? "ESC para borrar" : "ESC"
                    font.pixelSize: 10
                    color: escMouse.containsMouse ? Theme.fg : Theme.muted

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    id: escMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (launcherPopup.searchQuery !== "") {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        } else {
                            launcherPopup.isOpen = false;
                            if (AppState.activePopup === launcherPopup.popupId) AppState.activePopup = "";
                        }
                    }
                }
            }
        }

        // Separator (only when results are showing)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            color: Qt.rgba(1, 1, 1, 0.12)
            visible: launcherPopup.searchQuery !== ""
        }

        // Search Results List (appears only when typing)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: searchModel.count > 0 ? (Math.min(searchModel.count, 6) * 58) : 90
            Layout.maximumHeight: 6 * 58
            Layout.bottomMargin: 8
            visible: launcherPopup.searchQuery !== ""
            clip: true

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                visible: launcherPopup.searchQuery !== "" && searchModel.count === 0
                spacing: 8

                SvgIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "search"
                    iconSize: 26
                    iconColor: Theme.muted
                    flat: true
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Sin resultados para \"" + launcherPopup.searchQuery + "\""
                    font.pixelSize: 13
                    color: Theme.muted
                }
            }

            ListView {
                id: searchListView

                anchors.fill: parent
                visible: searchModel.count > 0
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: searchModel

                delegate: Rectangle {
                    id: resultItem
                    required property string name
                    required property string category
                    required property string iconName
                    required property var rawEntry
                    required property int index

                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    height: 54
                    radius: 14
                    color: (launcherPopup.selectedIndex === index || searchItemMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    scale: searchItemMouse.pressed ? 0.98 : 1.0

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            Layout.minimumWidth: 26
                            Layout.maximumWidth: 26
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                fillMode: Image.PreserveAspectFit
                                source: launcherPopup.resolveIcon(iconName)
                                sourceSize.width: 52
                                sourceSize.height: 52
                                smooth: true
                                onStatusChanged: {
                                    if (status === Image.Error && source !== Quickshell.iconPath("application-x-executable", true)) {
                                        source = Quickshell.iconPath("application-x-executable", true);
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            ThemedText {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                textFormat: Text.StyledText
                                text: launcherPopup.highlightContent(name, launcherPopup.searchQuery)
                                font.bold: launcherPopup.selectedIndex === index
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            ThemedText {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: category
                                font.pixelSize: 11
                                color: Theme.muted
                                elide: Text.ElideRight
                            }
                        }

                        ThemedText {
                            visible: launcherPopup.selectedIndex === index
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignVCenter
                            text: "Abrir ↵"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.fg
                            opacity: 0.75
                        }
                    }

                    MouseArea {
                        id: searchItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: launcherPopup.selectedIndex = index
                        onClicked: launcherPopup.launchApp(rawEntry)
                    }
                }
            }
        }
    }

    ListModel {
        id: searchModel
    }

    function updateSearchModel() {
        searchModel.clear();
        if (launcherPopup.searchQuery === "") return;

        const results = AppSearch.fuzzyQuery(launcherPopup.searchQuery);
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
}
