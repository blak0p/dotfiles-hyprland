// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A L E N D A R   C A R D                                              │
// │   integrated productivity · calendar, todo tasks & pomodoro timer        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma ComponentBehavior: Bound;

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.services
import qs.modules.common
import "../theme"
import "../services"
import "../components"

Card {
    id: root

    signal panelRequested(string panel)

    // 0: Calendario, 1: Por hacer, 2: Temporizador
    property int activeTab: 0

    // Pomodoro mode: 0 = Focus (Enfoque), 1 = Break (Descanso), 2 = Long Break (Descanso largo)
    readonly property int currentPomodoroMode: {
        if (!TimerService.pomodoroBreak) return 0;
        if (TimerService.pomodoroLongBreak) return 2;
        return 1;
    }

    // The day shown instead of the month, as a day key; "" for the month.
    property string picked: ""

    // Weeks start on Monday
    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    // Ticks at midnight; nothing here changes sooner.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date today: clock.date

    // Months away from the current one
    property int offsetMonths: 0

    readonly property date shown:
        new Date(root.today.getFullYear(), root.today.getMonth() + root.offsetMonths, 1)

    readonly property int year: root.shown.getFullYear()
    readonly property int month: root.shown.getMonth()

    readonly property int daysInMonth: new Date(root.year, root.month + 1, 0).getDate()
    readonly property int daysInPrevious: new Date(root.year, root.month, 0).getDate()

    // Column of the 1st, with Sunday moved to the end.
    readonly property int leadingBlanks: (new Date(root.year, root.month, 1).getDay() + 6) % 7

    readonly property bool showingThisMonth: root.offsetMonths === 0

    Component.onCompleted: root.offsetMonths = 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ── SUB-TABS HEADER ─────────────────────────────────────────────────
        Rectangle {
            id: tabsTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 14
            color: Theme.islandSurface || "#141414"
            border.color: Theme.border || Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            // Animated sliding pill indicator
            Rectangle {
                id: slidingPill
                y: 2
                height: tabsTrack.height - 4
                width: (tabsTrack.width - 4) / 3
                x: 2 + root.activeTab * width
                radius: 12
                color: "#f0f0f0"

                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 0

                // Tab 0: Calendario
                Item {
                    id: tab0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰃭"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: root.activeTab === 0 ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: Translation.tr("Calendar")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel || 11
                            font.weight: root.activeTab === 0 ? Font.DemiBold : Font.Normal
                            color: root.activeTab === 0 ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: mouse0
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = 0
                    }
                }

                // Tab 1: Tareas
                Item {
                    id: tab1
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄲"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: root.activeTab === 1 ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: Translation.tr("Tasks")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel || 11
                            font.weight: root.activeTab === 1 ? Font.DemiBold : Font.Normal
                            color: root.activeTab === 1 ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Badge count if pending
                        Rectangle {
                            visible: TasksService.pending > 0
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            radius: 7
                            color: root.activeTab === 1 ? "#000000" : (Theme.accent || "#f0f0f0")

                            Text {
                                anchors.centerIn: parent
                                text: TasksService.pending > 9 ? "9+" : TasksService.pending
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: root.activeTab === 1 ? "#ffffff" : "#000000"
                            }
                        }
                    }

                    MouseArea {
                        id: mouse1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = 1
                    }
                }

                // Tab 2: Pomodoro
                Item {
                    id: tab2
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰔛"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: root.activeTab === 2 ? "#000000" : (TimerService.pomodoroRunning ? Theme.indicatorGood : Theme.textMuted)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: Translation.tr("Pomodoro")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel || 11
                            font.weight: root.activeTab === 2 ? Font.DemiBold : Font.Normal
                            color: root.activeTab === 2 ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: mouse2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = 2
                    }
                }
            }
        }

        // ── TAB VIEWS CONTAINER ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ================================================================
            // VIEW 0: CALENDARIO
            // ================================================================
            Item {
                anchors.fill: parent
                visible: root.activeTab === 0

                // ── DAY DRILLDOWN ──
                ColumnLayout {
                    id: dayPage
                    anchors.fill: parent
                    visible: root.picked !== ""
                    spacing: 6

                    readonly property var date: TasksService.dateOf(root.picked)
                    readonly property var due: TasksService.on(root.picked)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        IconButton {
                            icon: "󰁍"
                            iconSize: 13
                            implicitWidth: 26
                            implicitHeight: 24
                            onClicked: root.picked = ""
                        }

                        Text {
                            Layout.fillWidth: true
                            text: dayPage.date ? Qt.formatDate(dayPage.date, "dddd d MMMM") : ""
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            text: {
                                const n = dayPage.due.length
                                const left = dayPage.due.filter(task => task.state !== "done").length
                                return n === 0 ? "" : `${left} / ${n}`
                            }
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLabel
                            color: Theme.textMuted
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.hairline
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: dayTaskCol.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: dayTaskCol
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: dayPage.due

                                TaskRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    task: modelData
                                    dated: false
                                    onOpened: {
                                        TasksService.open(modelData.key)
                                        root.panelRequested("board")
                                    }
                                }
                            }
                        }
                    }
                }

                // ── MONTH GRID ──
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.picked === ""
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.text
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: !root.showingThisMonth
                            Layout.preferredHeight: 22
                            implicitWidth: todayBtnText.implicitWidth + 14
                            radius: 11
                            color: todayBtnMouse.containsMouse ? Theme.surfaceHover : Theme.islandSurfaceHover

                            Text {
                                id: todayBtnText
                                anchors.centerIn: parent
                                text: Translation.tr("Today")
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.fg || "#ffffff"
                            }

                            MouseArea {
                                id: todayBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.offsetMonths = 0
                            }
                        }

                        IconButton {
                            icon: "󰅁"
                            iconSize: 13
                            implicitWidth: 26
                            implicitHeight: 24
                            onClicked: root.offsetMonths -= 1
                        }

                        IconButton {
                            icon: "󰅂"
                            iconSize: 13
                            implicitWidth: 26
                            implicitHeight: 24
                            onClicked: root.offsetMonths += 1
                        }
                    }

                    GridLayout {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 2
                        columnSpacing: 2

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                root.offsetMonths += event.angleDelta.y < 0 ? 1 : -1
                            }
                        }

                        Repeater {
                            model: root.weekdays

                            Text {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 16
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.textMuted
                            }
                        }

                        Repeater {
                            model: 42

                            Item {
                                id: cell
                                required property int index

                                readonly property int offset: cell.index - root.leadingBlanks
                                readonly property bool inMonth: cell.offset >= 0 && cell.offset < root.daysInMonth
                                readonly property int day: {
                                    if (cell.offset < 0)
                                        return root.daysInPrevious + cell.offset + 1
                                    if (cell.offset >= root.daysInMonth)
                                        return cell.offset - root.daysInMonth + 1
                                    return cell.offset + 1
                                }
                                readonly property bool isToday: cell.inMonth
                                    && root.showingThisMonth
                                    && cell.day === root.today.getDate()

                                readonly property string key: cell.inMonth
                                    ? TasksService.dayKey(new Date(root.year, root.month, cell.day)) : ""
                                readonly property int tasks: cell.key !== "" ? TasksService.countOn(cell.key) : 0
                                readonly property int pending: cell.key !== "" ? TasksService.pendingOn(cell.key) : 0

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height, 28)
                                    height: width
                                    radius: width / 2
                                    color: cell.isToday ? "#ffffff" : (cellMouse.containsMouse && cell.tasks > 0 ? Theme.surfaceHover : "transparent")

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: cell.tasks > 0 ? -1 : 0
                                        text: cell.day
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: cell.isToday
                                        color: {
                                            if (cell.isToday)
                                                return "#000000"
                                            return cell.inMonth ? (Theme.text || "#ffffff") : (Theme.textMuted || "#555555")
                                        }
                                        opacity: cell.inMonth ? 1.0 : 0.35
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        visible: cell.tasks > 0
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: cell.isToday ? "#000000" : (cell.pending > 0 ? "#f0f0f0" : Theme.textMuted)
                                    }

                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        enabled: cell.tasks > 0
                                        hoverEnabled: true
                                        cursorShape: cell.tasks > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (cell.tasks > 0)
                                                root.picked = cell.key
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================================================================
            // VIEW 1: POR HACER (TODO TASKS)
            // ================================================================
            ColumnLayout {
                anchors.fill: parent
                visible: root.activeTab === 1
                spacing: 6

                // Top Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: TasksService.pending === 0
                            ? (TasksService.count === 0 ? Translation.tr("No tasks yet") : Translation.tr("All done!"))
                            : `${TasksService.pending} ${Translation.tr("pending")}`
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall || 12
                        font.weight: Font.DemiBold
                        color: Theme.fg || "#ffffff"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredHeight: 22
                        implicitWidth: openBoardText.implicitWidth + 14
                        radius: 11
                        color: openBoardMouse.containsMouse ? Theme.surfaceHover : Theme.islandSurfaceHover

                        Text {
                            id: openBoardText
                            anchors.centerIn: parent
                            text: Translation.tr("Open Board")
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }

                        MouseArea {
                            id: openBoardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                TasksService.open("")
                                root.panelRequested("board")
                            }
                        }
                    }
                }

                // Tasks List
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: taskListCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: taskListCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: TasksService.queue.slice(0, 8)

                            Rectangle {
                                id: taskCard
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: taskCardMouse.containsMouse ? Theme.islandSurfaceHover : Theme.islandSurface
                                border.color: Theme.border || Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Checkbox Button
                                    Rectangle {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        radius: 8
                                        color: taskCard.modelData.state === "done" ? "#f0f0f0" : "transparent"
                                        border.color: taskCard.modelData.state === "done" ? "#f0f0f0" : Theme.textMuted
                                        border.width: 1.5

                                        Text {
                                            anchors.centerIn: parent
                                            visible: taskCard.modelData.state === "done"
                                            text: "󰄲"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            color: "#000000"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TasksService.toggle(taskCard.modelData.key)
                                        }
                                    }

                                    // Task Text
                                    Text {
                                        Layout.fillWidth: true
                                        text: taskCard.modelData.text || ""
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.strikeout: taskCard.modelData.state === "done"
                                        color: taskCard.modelData.state === "done" ? Theme.textMuted : (Theme.fg || "#ffffff")
                                    }

                                    // Due Date Pill
                                    Rectangle {
                                        visible: Boolean(taskCard.modelData.due)
                                        Layout.preferredHeight: 16
                                        implicitWidth: dueLabelText.implicitWidth + 8
                                        radius: 8
                                        color: TasksService.isOverdue(taskCard.modelData) ? Qt.rgba(1, 0.27, 0.23, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                                        Text {
                                            id: dueLabelText
                                            anchors.centerIn: parent
                                            text: TasksService.dueLabel(taskCard.modelData.due)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: TasksService.isOverdue(taskCard.modelData) ? Theme.red : Theme.textMuted
                                        }
                                    }

                                    // Delete action on hover
                                    Text {
                                        visible: taskCardMouse.containsMouse
                                        text: "󰅖"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: delMouse.containsMouse ? Theme.red : Theme.textMuted

                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TasksService.remove(taskCard.modelData.key)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: taskCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                    onClicked: {
                                        TasksService.open(taskCard.modelData.key)
                                        root.panelRequested("board")
                                    }
                                }
                            }
                        }

                        // Empty State
                        Item {
                            visible: TasksService.queue.length === 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰄲"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 20
                                    color: Theme.textMuted
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Translation.tr("All tasks complete!")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }
                }

                // Quick Add Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 15
                    color: Theme.islandSurface || "#141414"
                    border.color: addInput.activeFocus ? "#f0f0f0" : (Theme.border || Qt.rgba(1, 1, 1, 0.1))
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "+"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: addInput.text !== "" ? "#f0f0f0" : Theme.textMuted
                        }

                        TextField {
                            id: addInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: Translation.tr("Add task... (e.g. Call client @today)")
                            placeholderTextColor: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.fg || "#ffffff"
                            background: null
                            leftPadding: 0
                            rightPadding: 0

                            onAccepted: {
                                if (text.trim() !== "") {
                                    const parsed = TasksService.split(text)
                                    TasksService.add(parsed.text, parsed.due, "todo")
                                    text = ""
                                }
                            }
                        }

                        IconButton {
                            visible: addInput.text !== ""
                            icon: "󰌑"
                            iconSize: 12
                            implicitWidth: 20
                            implicitHeight: 20
                            onClicked: {
                                if (addInput.text.trim() !== "") {
                                    const parsed = TasksService.split(addInput.text)
                                    TasksService.add(parsed.text, parsed.due, "todo")
                                    addInput.text = ""
                                }
                            }
                        }
                    }
                }
            }

            // ================================================================
            // VIEW 2: TEMPORIZADOR (POMODORO TIMER)
            // ================================================================
            ColumnLayout {
                anchors.fill: parent
                visible: root.activeTab === 2
                spacing: 8

                // Mode Chips Row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    // Enfoque (Focus)
                    Rectangle {
                        Layout.preferredHeight: 26
                        implicitWidth: focusChipText.implicitWidth + 22
                        radius: 13
                        color: (root.currentPomodoroMode === 0) ? "#ffffff" : (focusMouse.containsMouse ? (Theme.surfaceHover || "#222222") : (Theme.islandSurface || "#161616"))
                        border.color: (root.currentPomodoroMode === 0) ? "#ffffff" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        scale: focusMouse.pressed ? 0.94 : (focusMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text {
                            id: focusChipText
                            anchors.centerIn: parent
                            text: Translation.tr("Focus")
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: (root.currentPomodoroMode === 0) ? Font.DemiBold : Font.Normal
                            color: (root.currentPomodoroMode === 0) ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: focusMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.setModeFocus()
                        }
                    }

                    // Descanso (Break)
                    Rectangle {
                        Layout.preferredHeight: 26
                        implicitWidth: breakChipText.implicitWidth + 22
                        radius: 13
                        color: (root.currentPomodoroMode === 1) ? "#ffffff" : (breakMouse.containsMouse ? (Theme.surfaceHover || "#222222") : (Theme.islandSurface || "#161616"))
                        border.color: (root.currentPomodoroMode === 1) ? "#ffffff" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        scale: breakMouse.pressed ? 0.94 : (breakMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text {
                            id: breakChipText
                            anchors.centerIn: parent
                            text: Translation.tr("Break")
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: (root.currentPomodoroMode === 1) ? Font.DemiBold : Font.Normal
                            color: (root.currentPomodoroMode === 1) ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: breakMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.setModeBreak()
                        }
                    }

                    // Descanso largo (Long break)
                    Rectangle {
                        Layout.preferredHeight: 26
                        implicitWidth: longBreakChipText.implicitWidth + 22
                        radius: 13
                        color: (root.currentPomodoroMode === 2) ? "#ffffff" : (longBreakMouse.containsMouse ? (Theme.surfaceHover || "#222222") : (Theme.islandSurface || "#161616"))
                        border.color: (root.currentPomodoroMode === 2) ? "#ffffff" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        scale: longBreakMouse.pressed ? 0.94 : (longBreakMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text {
                            id: longBreakChipText
                            anchors.centerIn: parent
                            text: Translation.tr("Long break")
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: (root.currentPomodoroMode === 2) ? Font.DemiBold : Font.Normal
                            color: (root.currentPomodoroMode === 2) ? "#000000" : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: longBreakMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.setModeLongBreak()
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Big Digital Countdown Display
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const total = Math.max(0, TimerService.pomodoroSecondsLeft)
                            const minutes = Math.floor(total / 60).toString().padStart(2, "0")
                            const seconds = (total % 60).toString().padStart(2, "0")
                            return `${minutes}:${seconds}`
                        }
                        font.family: Theme.fontMono || "monospace"
                        font.pixelSize: 38
                        font.bold: true
                        color: Theme.fg || "#ffffff"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const modeName = TimerService.pomodoroLongBreak
                                ? Translation.tr("Long break")
                                : (TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"));
                            return `${Translation.tr("Cycle")} ${TimerService.pomodoroCycle + 1} / ${TimerService.cyclesBeforeLongBreak || 4} · ${modeName}`
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillHeight: true }

                // Timer Controls Buttons Row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    // Play/Pause Primary Action Button
                    Rectangle {
                        Layout.preferredHeight: 36
                        implicitWidth: playBtnRow.implicitWidth + 32
                        radius: 18
                        color: playMouse.pressed ? "#d8d8d8" : (playMouse.containsMouse ? "#f5f5f5" : "#ffffff")
                        scale: playMouse.pressed ? 0.94 : (playMouse.containsMouse ? 1.04 : 1.0)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: playBtnRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: TimerService.pomodoroRunning ? "󰏤" : "󰐊"
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: "#000000"
                            }

                            Text {
                                text: TimerService.pomodoroRunning
                                    ? Translation.tr("Pause")
                                    : (TimerService.pomodoroSecondsLeft === TimerService.pomodoroLapDuration
                                        ? Translation.tr("Start")
                                        : Translation.tr("Resume"))
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: "#000000"
                            }
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.togglePomodoro()
                        }
                    }

                    // Reset Secondary Action Button
                    Rectangle {
                        Layout.preferredHeight: 36
                        implicitWidth: resetBtnRow.implicitWidth + 28
                        radius: 18
                        color: resetMouse.pressed ? Qt.rgba(1, 1, 1, 0.18) : (resetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        scale: resetMouse.pressed ? 0.94 : (resetMouse.containsMouse ? 1.04 : 1.0)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: resetBtnRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰜉"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: Theme.fg || "#ffffff"
                            }

                            Text {
                                text: Translation.tr("Reset")
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.fg || "#ffffff"
                            }
                        }

                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.resetPomodoro()
                        }
                    }
                }
            }
        }
    }
}
