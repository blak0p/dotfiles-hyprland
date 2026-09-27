import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.services

CenterWindow {
    id: root

    property string searchText: ""
    property var allResults: []
    property string installingPkg: ""
    property bool isSearching: false
    property string actionMode: "install"
    property var selectedPackages: ([])
    property var selectedPackageObjects: ({
    })
    property string accumulatedSearchOutput: ""
    readonly property bool updateCountsReady: /^\d+$/.test(UpdateService.cachyUpdatesCount) && /^\d+$/.test(UpdateService.homebrewUpdatesCount)
    readonly property int cachyPendingCount: updateCountsReady ? Number(UpdateService.cachyUpdatesCount) : 0
    readonly property int homebrewPendingCount: updateCountsReady ? Number(UpdateService.homebrewUpdatesCount) : 0
    readonly property bool updateCountsChecking: !updateCountsReady || UpdateService.isCheckingUpdates
    readonly property bool hasPendingUpdates: updateCountsReady && (cachyPendingCount > 0 || homebrewPendingCount > 0)

    function updateSummary(name, count, source, description) {
        return {
            "name": name,
            "version": count + " packages pending",
            "repo": source,
            "source": source,
            "description": description,
            "installed": true,
            "isSummary": true
        };
    }

    function selectAllUpdateResults() {
        if (root.actionMode !== "update")
            return ;

        let arr = [];
        let objs = {};
        for (let i = 0; i < resultsModel.count; i++) {
            let pkg = resultsModel.get(i);
            arr.push(pkg.name);
            objs[pkg.name] = {
                "name": pkg.name,
                "version": pkg.version,
                "repo": pkg.repo,
                "source": pkg.source,
                "description": pkg.description,
                "installed": pkg.installed
            };
        }
        root.selectedPackages = arr;
        root.selectedPackageObjects = objs;
        root.updateModel();
    }

    function refreshUpdateResults() {
        if (root.actionMode !== "update" || root.isSearching)
            return ;

        root.updateModel();
        root.selectAllUpdateResults();
    }

    function doSearch(query) {
        if (root.actionMode === "install") {
            if (query.length < 2) {
                root.allResults = [];
                root.updateModel();
                root.isSearching = false;
                startSearchTimer.stop();
                return ;
            }
            searchProc.running = false;
            startSearchTimer.nextCommand = query;
            startSearchTimer.restart();
        } else if (root.actionMode === "remove") {
            searchProc.running = false;
            startSearchTimer.nextCommand = "--list-installed";
            startSearchTimer.restart();
        } else if (root.actionMode === "update") {
            searchProc.running = false;
            startSearchTimer.nextCommand = "--list-updates";
            startSearchTimer.restart();
        }
    }

    function updateModel() {
        let currentPkgName = "";
        if (pkgView && pkgView.currentIndex >= 0 && resultsModel.count > pkgView.currentIndex)
            currentPkgName = resultsModel.get(pkgView.currentIndex).name;

        resultsModel.clear();
        let data = root.allResults.slice();
        if ((root.actionMode === "remove" || root.actionMode === "update") && root.searchText.length > 0) {
            let q = root.searchText.toLowerCase();
            data = data.filter(function(p) {
                return p.name.toLowerCase().indexOf(q) !== -1 || p.description.toLowerCase().indexOf(q) !== -1;
            });
        }
        if (root.actionMode === "update" && root.updateCountsReady) {
            if (data.length === 0 && root.cachyPendingCount > 0)
                data.push(root.updateSummary("CachyOS updates", root.cachyPendingCount, "CachyOS", "CachyOS packages available for update"));

            if (root.homebrewPendingCount > 0)
                data.push(root.updateSummary("Homebrew updates", root.homebrewPendingCount, "Homebrew", "Homebrew packages available for upgrade"));
        }
        let selectedNames = root.selectedPackages;
        for (let i = 0; i < data.length; i++) {
            let pkg = data[i];
            let isSel = selectedNames.indexOf(pkg.name) !== -1;
            let pkgObj = {
                "name": pkg.name,
                "version": pkg.version,
                "repo": pkg.repo,
                "source": pkg.source,
                "description": pkg.description,
                "installed": pkg.installed,
                "selected": isSel
            };
            resultsModel.append(pkgObj);
        }
        if (pkgView) {
            let found = false;
            if (currentPkgName !== "") {
                for (let i = 0; i < resultsModel.count; i++) {
                    if (resultsModel.get(i).name === currentPkgName) {
                        pkgView.currentIndex = i;
                        found = true;
                        break;
                    }
                }
            }
            if (!found)
                pkgView.currentIndex = resultsModel.count > 0 ? 0 : -1;

        }
    }

    function toggleSelect(pkgName) {
        let arr = root.selectedPackages.slice();
        let idx = arr.indexOf(pkgName);
        let objs = Object.assign({
        }, root.selectedPackageObjects);
        if (idx !== -1) {
            arr.splice(idx, 1);
            delete objs[pkgName];
        } else {
            arr.push(pkgName);
            let found = false;
            for (let i = 0; i < resultsModel.count; i++) {
                if (resultsModel.get(i).name === pkgName) {
                    objs[pkgName] = {
                        "name": resultsModel.get(i).name,
                        "version": resultsModel.get(i).version,
                        "repo": resultsModel.get(i).repo,
                        "source": resultsModel.get(i).source,
                        "description": resultsModel.get(i).description,
                        "installed": resultsModel.get(i).installed
                    };
                    found = true;
                    break;
                }
            }
            if (!found) {
                for (let i = 0; i < root.allResults.length; i++) {
                    if (root.allResults[i].name === pkgName) {
                        objs[pkgName] = {
                            "name": root.allResults[i].name,
                            "version": root.allResults[i].version,
                            "repo": root.allResults[i].repo,
                            "source": root.allResults[i].source,
                            "description": root.allResults[i].description,
                            "installed": root.allResults[i].installed
                        };
                        found = true;
                        break;
                    }
                }
            }
        }
        root.selectedPackages = arr;
        root.selectedPackageObjects = objs;
        for (let i = 0; i < resultsModel.count; i++) {
            if (resultsModel.get(i).name === pkgName) {
                resultsModel.setProperty(i, "selected", idx === -1);
                break;
            }
        }
    }

    function executeBatch() {
        if (root.selectedPackages.length === 0)
            return ;

        let updateScript = Quickshell.env("HOME") + "/.config/quickshell/ii/Scripts/system_update.sh";
        if (root.actionMode === "remove") {
            removeProc.running = false;
            removeProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "bash", updateScript, "remove"].concat(root.selectedPackages);
            removeProc.startDetached();
        } else if (root.actionMode === "update") {
            if (!UpdateService.runSystemUpdate())
                return ;
        } else {
            installProc.running = false;
            installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "bash", updateScript, "install"].concat(root.selectedPackages);
            installProc.startDetached();
        }
        root.selectedPackages = [];
        focusKittyTimer.start();
        root.isOpen = false;
    }

    function installPackage(name) {
        root.installingPkg = name;
        installProc.running = false;
        installProc.command = ["sh", "-c", "kitty --class kitty-floating --hold -e bash $HOME/.config/quickshell/ii/Scripts/system_update.sh install " + name + " & sleep 0.2; hyprctl dispatch focuswindow class:kitty-floating"];
        installProc.startDetached();
        root.isOpen = false;
    }

    function removePackage(name) {
        root.installingPkg = name;
        removeProc.running = false;
        removeProc.command = ["sh", "-c", "kitty --class kitty-floating --hold -e bash $HOME/.config/quickshell/ii/Scripts/system_update.sh remove " + name + " & sleep 0.2; hyprctl dispatch focuswindow class:kitty-floating"];
        removeProc.startDetached();
        root.isOpen = false;
    }

    function handleKeyPress(event, fromSearch) {
        if (event.key === Qt.Key_Down) {
            if (pkgView.count > 0 && pkgView.currentIndex < pkgView.count - 1) {
                pkgView.currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (pkgView.currentIndex <= -1 && !fromSearch) {
                if (root.actionMode !== "update")
                    searchField.forceActiveFocus();

                pkgView.currentIndex = -1;
                event.accepted = true;
            } else if (pkgView.currentIndex > 0) {
                pkgView.currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            let idx = pkgView.currentIndex >= 0 ? pkgView.currentIndex : 0;
            if (root.selectedPackages.length === 0 && resultsModel.count > idx) {
                let pkg = resultsModel.get(idx);
                root.selectedPackages = [pkg.name];
            }
            root.executeBatch();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            if (event.modifiers & Qt.ControlModifier) {
                if (root.actionMode === "install")
                    root.actionMode = "remove";
                else if (root.actionMode === "remove")
                    root.actionMode = "update";
                else
                    root.actionMode = "install";
                root.selectedPackages = [];
                root.selectedPackageObjects = {
                };
                root.allResults = [];
                resultsModel.clear();
                searchField.text = "";
                root.searchText = "";
                root.doSearch("");
                focusTimer.start();
            } else {
                let idx = pkgView.currentIndex >= 0 ? pkgView.currentIndex : 0;
                if (resultsModel.count > idx) {
                    let pkg = resultsModel.get(idx);
                    root.toggleSelect(pkg.name);
                }
            }
            event.accepted = true;
        }
    }

    popupId: "packagemanager"
    preferredHeight: 520
    preferredWidth: 650
    onPopupOpened: {
        searchField.text = "";
        root.allResults = [];
        root.installingPkg = "";
        root.actionMode = SettingsService.packageManagerMode;
        root.selectedPackages = [];
        root.selectedPackageObjects = {
        };
        root.doSearch("");
        focusTimer.start();
    }
    onPopupClosed: {
        SettingsService.packageManagerMode = "install";
    }

    Timer {
        id: startSearchTimer

        property string nextCommand: ""

        interval: 10
        repeat: false
        onTriggered: {
            root.isSearching = true;
            root.accumulatedSearchOutput = "";
            searchProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/Scripts/search_packages.py", nextCommand];
            searchProc.running = true;
        }
    }

    ListModel {
        id: resultsModel
    }

    Timer {
        id: focusTimer

        interval: 50
        repeat: false
        onTriggered: {
            if (root.actionMode !== "update")
                searchField.forceActiveFocus();
            else if (pkgView.visible)
                pkgView.forceActiveFocus();
        }
    }

    Timer {
        id: focusKittyTimer

        interval: 300
        repeat: false
        onTriggered: {
            focusKittyProc.running = false;
            focusKittyProc.command = ["hyprctl", "dispatch", "focuswindow", "class:kitty-floating"];
            focusKittyProc.startDetached();
        }
    }

    Timer {
        id: debounceTimer

        interval: 300
        repeat: false
        onTriggered: {
            if (root.actionMode === "remove" || root.actionMode === "update")
                root.updateModel();
            else
                root.doSearch(root.searchText);
        }
    }

    Process {
        id: searchProc

        command: ["echo", ""]
        onExited: function(exitCode) {
            if (searchProc.running || startSearchTimer.running)
                return ;

            root.isSearching = false;
            if (exitCode === 0) {
                try {
                    root.allResults = JSON.parse(root.accumulatedSearchOutput);
                    root.updateModel();
                    if (root.actionMode === "update")
                        root.selectAllUpdateResults();
                } catch (e) {
                    console.error("PackageManager: Error parsing search results: " + e);
                    root.allResults = [];
                    resultsModel.clear();
                }
            }
            root.accumulatedSearchOutput = "";
            focusTimer.start();
        }

        stdout: SplitParser {
            onRead: (data) => {
                root.accumulatedSearchOutput += data;
            }
        }

    }

    Connections {
        target: UpdateService

        function onCachyUpdatesCountChanged() {
            root.refreshUpdateResults();
        }

        function onHomebrewUpdatesCountChanged() {
            root.refreshUpdateResults();
        }
    }

    Process {
        id: installProc


    }

    Process {
        id: removeProc
    }

    Process {
        id: copyNameProc
    }

    Process {
        id: focusKittyProc
    }

    ColumnLayout {
        spacing: Constants.sizeSm
        Layout.fillWidth: true
        Layout.fillHeight: true

        ThemedTabs {
            id: modeTabs

            Layout.fillWidth: true
            Layout.preferredHeight: 38
            activeValue: root.actionMode
            onTabSelected: (value) => {
                if (root.actionMode === value)
                    return ;

                root.actionMode = value;
                root.selectedPackages = [];
                root.selectedPackageObjects = {
                };
                root.allResults = [];
                resultsModel.clear();
                searchField.text = "";
                root.searchText = "";
                root.doSearch("");
                focusTimer.start();
            }

            ThemedTab {
                icon: "download"
                text: Translation.tr("Install")
                value: "install"
            }

            ThemedTab {
                icon: "trash"
                text: Translation.tr("Remove")
                value: "remove"
            }

            ThemedTab {
                icon: "update"
                text: Translation.tr("Update")
                value: "update"
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: Constants.sizeSm

            ThemedSearchBar {
                id: searchField

                Layout.fillWidth: true
                preferredHeight: 40
                visible: root.actionMode !== "update"
                placeholderText: root.actionMode === "remove" ? Translation.tr("Search to remove") : root.actionMode === "update" ? Translation.tr("Search updates") : Translation.tr("Search to install")
                onSearchRequested: (text) => {
                    root.searchText = text;
                    debounceTimer.restart();
                }
                textField.Keys.onPressed: function(event) {
                    root.handleKeyPress(event, true);
                }
            }

            Item {
                Layout.fillWidth: true
                visible: root.actionMode === "update"
            }

            ThemedText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.selectedPackages.length > 0
                text: root.selectedPackages.length + " " + Translation.tr("selected")
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: Theme.fg

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                visible: root.selectedPackages.length > 0
                width: execLabel.implicitWidth + Constants.size2Xl
                height: Constants.size2Xl
                radius: height / 2
                color: Theme.bgSecondary

                ThemedText {
                    id: execLabel

                    anchors.centerIn: parent
                    text: root.actionMode === "install" ? Translation.tr("Install") : root.actionMode === "update" ? Translation.tr("Update") : Translation.tr("Remove")
                    font.pixelSize: Constants.sizeXs + 2
                    font.bold: true
                    color: Theme.accent
                }

                HoverHandler {
                    id: execHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.executeBatch()
                }

            }

        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.actionMode === "install" && root.searchText.length < 2 && resultsModel.count === 0 && !root.isSearching

                SvgIcon {
                    icon: "download"
                    iconColor: Theme.muted
                    iconSize: 72
                    Layout.alignment: Qt.AlignHCenter
                }

                ThemedText {
                    text: Translation.tr("Search packages")
                    color: Theme.muted
                    font.pixelSize: Constants.sizeMd
                    Layout.alignment: Qt.AlignHCenter
                }

                ThemedText {
                    text: Translation.tr("Type at least 2 characters to search")
                    color: Theme.muted
                    font.pixelSize: Constants.sizeSm
                    Layout.alignment: Qt.AlignHCenter
                }

            }

            GhostEmptyState {
                anchors.centerIn: parent
                visible: resultsModel.count === 0 && !root.isSearching && !debounceTimer.running && !(root.actionMode === "install" && root.searchText.length < 2)
                icon: root.actionMode === "update" && root.updateCountsChecking ? "reload" : root.actionMode === "update" ? "check" : "ghost"
                iconColor: root.actionMode === "update" ? Theme.accent : Theme.muted
                text: {
                    if (root.actionMode !== "update")
                        return Translation.tr("No packages found");
                    if (root.updateCountsChecking)
                        return Translation.tr("Checking updates...");
                    if (root.hasPendingUpdates)
                        return root.cachyPendingCount + root.homebrewPendingCount + " " + Translation.tr("packages pending");
                    return Translation.tr("System is up to date");
                }
                isAnimating: visible && (root.actionMode !== "update" || root.updateCountsChecking)
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.isSearching

                SvgIcon {
                    icon: "reload"
                    iconColor: Theme.accent
                    iconSize: 36
                    flat: true
                    Layout.alignment: Qt.AlignHCenter

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.isSearching
                    }

                }

                ThemedText {
                    text: Translation.tr("Searching...")
                    color: Theme.muted
                    font.pixelSize: Constants.sizeMd
                    Layout.alignment: Qt.AlignHCenter
                }

            }

            ListView {
                id: pkgView

                anchors.fill: parent
                clip: true
                model: resultsModel
                spacing: Constants.sizeXs
                currentIndex: -1
                highlightResizeDuration: 0
                highlightMoveDuration: Constants.animNormal
                highlightFollowsCurrentItem: true
                visible: resultsModel.count > 0 && !root.isSearching
                Keys.onPressed: function(event) {
                    root.handleKeyPress(event, false);
                }

                highlight: Item {
                    width: pkgView.width
                    height: pkgView.currentItem ? pkgView.currentItem.height : 52
                    z: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 2
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            width: 3
                            radius: width / 2
                            color: Theme.accent

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutQuint
                                }

                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animNormal
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Constants.animNormal
                            }

                        }

                    }

                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: Constants.animFast
                    }

                }

                removeDisplaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Constants.animFast
                        easing.type: Easing.OutExpo
                    }

                }

                addDisplaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Constants.animNormal
                        easing.type: Easing.OutExpo
                    }

                }

                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Constants.animNormal
                        easing.type: Easing.OutExpo
                    }

                }

                populate: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

                delegate: Item {
                    id: delegateRoot

                    readonly property bool isCurrent: pkgView.currentIndex === index
                    readonly property bool isSelected: selected

                    width: pkgView.width
                    height: delegateContent.implicitHeight + Constants.sizeLg
                    z: 2

                    Rectangle {
                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                        visible: isSelected
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                        visible: delegateHover.hovered && !isCurrent
                    }

                    RowLayout {
                        id: delegateContent

                        anchors.fill: parent
                        anchors.leftMargin: Constants.sizeLg
                        anchors.rightMargin: Constants.sizeLg
                        spacing: Constants.sizeSm

                        SvgIconButton {
                            id: checkIcon

                            Layout.alignment: Qt.AlignVCenter
                            icon: isSelected ? "circle-check" : "circle-dashed-check"
                            iconSize: Constants.sizeLg
                            iconColor: isSelected ? Theme.accent : Theme.muted
                            flat: true
                            padding: 0
                            onClicked: {
                                root.toggleSelect(name);
                            }
                        }

                        ColumnLayout {
                            id: detailColumn

                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: Constants.sizeXs

                                ThemedText {
                                    text: name
                                    color: isSelected ? Theme.accent : (isCurrent ? Theme.accent : Theme.fg)
                                    font.pixelSize: Constants.sizeMd
                                    font.bold: true

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Constants.animNormal
                                            easing.type: Easing.OutQuint
                                        }

                                    }

                                }

                                ThemedText {
                                    text: version
                                    color: Theme.muted
                                    font.pixelSize: Constants.sizeXs + 2
                                    Layout.alignment: Qt.AlignBottom
                                    Layout.bottomMargin: 2
                                }

                            }

                            ThemedText {
                                text: description
                                color: isCurrent ? Theme.fg : Theme.muted
                                font.pixelSize: Constants.sizeSm
                                Layout.fillWidth: true
                                maximumLineCount: isCurrent ? 3 : 1
                                elide: Text.ElideRight
                                wrapMode: isCurrent ? Text.WordWrap : Text.NoWrap

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Constants.animNormal
                                        easing.type: Easing.OutQuint
                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            Layout.topMargin: 4

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 4

                                Rectangle {
                                    visible: installed
                                    width: instText.implicitWidth + 12
                                    height: 18
                                    radius: height / 2
                                    color: Theme.bgSecondary

                                    ThemedText {
                                        id: instText

                                        anchors.centerIn: parent
                                        text: Translation.tr("INSTALLED")
                                        font.pixelSize: Constants.sizeXs
                                        font.bold: true
                                        color: Theme.accent
                                    }

                                }

                                Rectangle {
                                    width: repoText.implicitWidth + 12
                                    height: 18
                                    radius: height / 2
                                    color: Theme.bgSecondary

                                    ThemedText {
                                        id: repoText

                                        anchors.centerIn: parent
                                        text: (source === "AUR" ? "AUR" : repo).toUpperCase()
                                        font.pixelSize: Constants.sizeXs
                                        font.bold: true
                                        color: Theme.accent
                                        textFormat: Text.PlainText
                                    }

                                }

                            }

                        }

                    }

                    HoverHandler {
                        id: delegateHover
                    }

                    TapHandler {
                        onTapped: {
                            pkgView.currentIndex = index;
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Constants.animNormal
                            easing.type: Easing.OutQuint
                        }

                    }

                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                    active: true
                }

            }

        }

    }

}
