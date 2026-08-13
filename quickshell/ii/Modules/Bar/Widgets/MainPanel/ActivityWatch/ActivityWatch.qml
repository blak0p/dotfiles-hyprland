import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.services

RowLayout {
    id: root

    property string totalTimeStr: "0m"
    property int totalTimeSec: 0
    property bool isOnline: true
    property var topApps: []
    property int selectedDayOffset: 0
    property var weeklySeconds: [0, 0, 0, 0, 0, 0, 0]
    property int maxWeeklySeconds: 0
    property var weeklyLabels: ["", "", "", "", "", "", ""]
    property string awResponseRaw: ""
    property string awHourlyResponseRaw: ""
    property var appIconMap: ({
    })
    property int lastSelectedDayOffset: 0
    property int slideDirection: 1
    property real contentOpacity: 1
    property real contentTranslateX: 0
    property bool dayChangedRecently: false
    property bool isResetting: false
    property real lastRefreshTime: 0
    readonly property int selectedDayIndex: {
        let now = new Date();
        let selectedDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + root.selectedDayOffset);
        let dayOfWeek = selectedDay.getDay();
        return dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    }

    function formatDuration(sec) {
        if (sec < 60)
            return Math.round(sec) + "s";

        let min = Math.round(sec / 60);
        if (min < 60)
            return min + "m";

        let hr = Math.floor(min / 60);
        let remMin = min % 60;
        if (remMin === 0)
            return hr + "h";

        return hr + "h " + remMin + "m";
    }

    function formatYLabel(sec) {
        if (sec <= 0)
            return "0";

        if (sec < 60)
            return Math.round(sec) + "s";

        let min = Math.round(sec / 60);
        if (min < 60)
            return min + "m";

        let hr = Math.floor(min / 60);
        let remMin = min % 60;
        if (remMin === 0)
            return hr + "h";

        return hr + "h " + remMin + "m";
    }

    function getDayLabel(offset) {
        if (offset === 0)
            return "Today";

        if (offset === -1)
            return "Yesterday";

        let now = new Date();
        let d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
    }

    function getMondayOffset(offset) {
        let now = new Date();
        let d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
        let dayOfWeek = d.getDay();
        let diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        return offset + diffToMonday;
    }

    function getWeekRangeLabel(offset) {
        let now = new Date();
        let selectedDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
        let dayOfWeek = selectedDay.getDay();
        let diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        let monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset + diffToMonday);
        let sunday = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset + diffToMonday + 6);
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        if (monday.getMonth() === sunday.getMonth())
            return months[monday.getMonth()] + " " + monday.getDate() + " - " + sunday.getDate();
        else
            return months[monday.getMonth()] + " " + monday.getDate() + " - " + months[sunday.getMonth()] + " " + sunday.getDate();
    }

    function refresh() {
        root.lastRefreshTime = Date.now();
        let now = new Date();
        let dayDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + root.selectedDayOffset, 0, 0, 0);
        let startStr = dayDate.toISOString();
        let endStr = new Date(dayDate.getFullYear(), dayDate.getMonth(), dayDate.getDate(), 23, 59, 59).toISOString();
        let todayPayload = {
            "timeperiods": [startStr + "/" + endStr],
            "query": ["window_events = query_bucket(find_bucket(\"aw-watcher-window_\"));", "merged = merge_events_by_keys(window_events, [\"app\"]);", "RETURN = sort_by_duration(merged);"]
        };
        fetchAWStats.command = ["curl", "-s", "-f", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify(todayPayload), "http://localhost:5600/api/0/query/"];
        root.awResponseRaw = "";
        fetchAWStats.running = false;
        fetchAWStats.running = true;
        let selectedDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + root.selectedDayOffset);
        let dayOfWeek = selectedDay.getDay();
        let diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        let periods = [];
        let labels = [];
        for (let i = 0; i < 7; i++) {
            let d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + root.selectedDayOffset + diffToMonday + i, 0, 0, 0);
            let start = d.toISOString();
            let end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59).toISOString();
            periods.push(start + "/" + end);
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            labels.push(days[d.getDay()]);
        }
        root.weeklyLabels = labels;
        let weeklyPayload = {
            "timeperiods": periods,
            "query": ["window_events = query_bucket(find_bucket(\"aw-watcher-window_\"));", "RETURN = sum_durations(window_events);"]
        };
        fetchHourlyStats.command = ["curl", "-s", "-f", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify(weeklyPayload), "http://localhost:5600/api/0/query/"];
        root.awHourlyResponseRaw = "";
        fetchHourlyStats.running = false;
        fetchHourlyStats.running = true;
    }

    implicitHeight: 380
    spacing: Constants.sizeLg
    Component.onCompleted: {
        loadAppsProc.running = true;
        root.refresh();
    }
    onSelectedDayOffsetChanged: {
        if (selectedDayOffset > lastSelectedDayOffset)
            slideDirection = -1;
        else
            slideDirection = 1;
        let oldMonday = getMondayOffset(lastSelectedDayOffset);
        let newMonday = getMondayOffset(selectedDayOffset);
        let weekChanged = (oldMonday !== newMonday);
        lastSelectedDayOffset = selectedDayOffset;
        if (!root.isResetting) {
            if (weekChanged) {
                root.dayChangedRecently = true;
                transitionAnim.restart();
            } else {
                root.dayChangedRecently = false;
                root.refresh();
            }
        }
    }
    onVisibleChanged: {
        if (visible) {
            let needsRefresh = false;
            if (root.selectedDayOffset !== 0) {
                root.isResetting = true;
                root.selectedDayOffset = 0;
                root.isResetting = false;
                needsRefresh = true;
            }
            if (Date.now() - root.lastRefreshTime > 30000)
                needsRefresh = true;

            if (needsRefresh)
                root.refresh();

            if (Object.keys(root.appIconMap).length === 0)
                loadAppsProc.running = true;

        } else {
            root.dayChangedRecently = false;
        }
    }

    Process {
        id: fetchAWStats

        onExited: (code) => {
            if (code === 0) {
                try {
                    let text = awOutput.text.trim();
                    if (text === "")
                        return ;

                    let result = JSON.parse(text);
                    if (result && result.length > 0) {
                        root.isOnline = true;
                        let events = result[0];
                        let sum = 0;
                        let validEvents = [];
                        for (let i = 0; i < events.length; i++) {
                            let appName = events[i].data.app ? events[i].data.app.toLowerCase() : "unknown";
                            if (appName !== "unknown") {
                                sum += events[i].duration;
                                validEvents.push(events[i]);
                            }
                        }
                        root.totalTimeSec = Math.round(sum);
                        root.totalTimeStr = formatDuration(sum);
                        let count = Math.min(validEvents.length, 5);
                        let appsList = [];
                        for (let i = 0; i < count; i++) {
                            let ev = validEvents[i];
                            let pct = sum > 0 ? (ev.duration / sum) : 0;
                            appsList.push({
                                "app": ev.data.app,
                                "durationStr": formatDuration(ev.duration),
                                "percentage": pct
                            });
                        }
                        root.topApps = appsList;
                    } else {
                        root.isOnline = true;
                        root.totalTimeSec = 0;
                        root.totalTimeStr = "0m";
                        root.topApps = [];
                    }
                } catch (e) {
                    console.error("fetchAWStats error: " + e);
                    root.isOnline = false;
                }
            } else {
                root.awResponseRaw = "";
                root.isOnline = false;
            }
        }

        stdout: StdioCollector {
            id: awOutput
        }

    }

    Process {
        id: fetchHourlyStats

        onExited: (code) => {
            if (code === 0) {
                try {
                    let text = awHourlyOutput.text.trim();
                    if (text === "")
                        return ;

                    let result = JSON.parse(text);
                    if (Array.isArray(result) && result.length === 7) {
                        root.weeklySeconds = result;
                        let maxVal = 0;
                        for (let i = 0; i < result.length; i++) {
                            if (result[i] > maxVal)
                                maxVal = result[i];

                        }
                        root.maxWeeklySeconds = Math.round(maxVal);
                    }
                } catch (e) {
                    console.error("fetchHourlyStats error: " + e);
                }
            } else {
                root.awHourlyResponseRaw = "";
            }
        }

        stdout: StdioCollector {
            id: awHourlyOutput
        }

    }

    Process {
        id: loadAppsProc

        command: ["python3", Quickshell.shellDir + "/Scripts/get_apps.py"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    let apps = JSON.parse(appFetcherOutput.text);
                    let map = {
                    };
                    for (let i = 0; i < apps.length; i++) {
                        let app = apps[i];
                        if (app.icon) {
                            if (app.exec) {
                                let execName = app.exec.split('/').pop().split(' ')[0].toLowerCase();
                                map[execName] = app.icon;
                            }
                            if (app.name)
                                map[app.name.toLowerCase()] = app.icon;

                        }
                    }
                    root.appIconMap = map;
                } catch (e) {
                    console.error("Error parsing apps JSON in ActivityWatch: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: appFetcherOutput
        }

    }

    SequentialAnimation {
        id: transitionAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 0
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: root
                property: "contentTranslateX"
                to: root.slideDirection * 20
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

        ScriptAction {
            script: {
                root.refresh();
                root.contentTranslateX = -root.slideDirection * 20;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 1
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "contentTranslateX"
                to: 0
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

    Timer {
        id: refreshTimer

        interval: 30000
        running: root.visible
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Constants.sizeMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            ThemedText {
                text: root.totalTimeStr
                font.pixelSize: Constants.size2Xl + 8
                font.bold: true
                color: Theme.fg
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: 180
                height: Constants.size3Xl
                implicitWidth: 180
                implicitHeight: Constants.size3Xl
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.preferredWidth: 180
                Layout.preferredHeight: Constants.size3Xl
                radius: height / 2
                color: Theme.bgSecondary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 0

                    SvgIconButton {
                        icon: "chevron-left"
                        iconSize: Constants.sizeSm
                        bgColor: "transparent"
                        onClicked: root.selectedDayOffset -= 7
                    }

                    ThemedText {
                        text: root.getWeekRangeLabel(root.selectedDayOffset)
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        opacity: root.contentOpacity

                        transform: Translate {
                            x: root.contentTranslateX * 0.5
                        }

                    }

                    SvgIconButton {
                        icon: "chevron-right"
                        iconSize: Constants.sizeSm
                        bgColor: "transparent"
                        disabled: getMondayOffset(root.selectedDayOffset) === getMondayOffset(0)
                        onClicked: {
                            if (getMondayOffset(root.selectedDayOffset) < getMondayOffset(0))
                                root.selectedDayOffset += 7;

                        }
                    }

                }

            }

        }

        ActivityChart {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            visible: root.isOnline
            dataValues: root.weeklySeconds
            xLabels: root.weeklyLabels
            maxValue: root.maxWeeklySeconds
            activeIndex: root.selectedDayIndex
            opacity: root.contentOpacity
            animateHeight: root.opacity > 0.99 && !root.isResetting && root.dayChangedRecently
            onBarClicked: (index) => {
                let now = new Date();
                let selectedDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + root.selectedDayOffset);
                let dayOfWeek = selectedDay.getDay();
                let diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
                let newOffset = root.selectedDayOffset + diffToMonday + index;
                if (newOffset <= 0 && newOffset !== root.selectedDayOffset)
                    root.selectedDayOffset = newOffset;

            }

            transform: Translate {
                x: root.contentTranslateX
            }

        }

        ColumnLayout {
            visible: !root.isOnline
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeSm
            opacity: root.contentOpacity

            Item {
                Layout.preferredHeight: Constants.sizeLg
            }

            ThemedText {
                text: Translation.tr("ActivityWatch is not running")
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: Theme.muted
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

            transform: Translate {
                x: root.contentTranslateX
            }

        }

    }

    TopAppsList {
        topApps: root.topApps
        isOnline: root.isOnline
        appIconMap: root.appIconMap
        dateStr: root.getDayLabel(root.selectedDayOffset)
        Layout.preferredWidth: 280
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

}
