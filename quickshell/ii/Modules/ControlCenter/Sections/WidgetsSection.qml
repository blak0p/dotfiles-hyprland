import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services
import "../CalendarHelper.js" as CalHelper

ColumnLayout {
    id: root

    property int widgetSubTab: 0 // 0: Calendario, 1: Tareas, 2: Foco
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedTabs {
            activeValue: root.widgetSubTab
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            ThemedTab { value: 0; text: "Calendario" }
            ThemedTab { value: 1; text: "Tareas (" + Todo.list.filter(t => !t.done).length + ")" }
            ThemedTab { value: 2; text: "Foco" }

            onTabSelected: (v) => { root.widgetSubTab = v }
        }
    }

    // ==========================================
    // 1. CALENDARIO
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.widgetSubTab === 0
        spacing: 8

        property int monthShift: 0
        property var viewingDate: CalHelper.getDateInXMonthsTime(monthShift)
        property var gridData: CalHelper.getCalendarGrid(viewingDate, monthShift === 0)

        // Month Header
        RowLayout {
            Layout.fillWidth: true

            ThemedText {
                text: {
                    const monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                                        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
                    return monthNames[parent.parent.viewingDate.getMonth()] + " " + parent.parent.viewingDate.getFullYear();
                }
                font.bold: true
                font.pixelSize: Constants.sizeMd
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ThemedButton {
                text: "Hoy"
                visible: parent.parent.monthShift !== 0
                onClicked: parent.parent.monthShift = 0
            }

            SvgIcon {
                icon: "chevron-left"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: Theme.fg
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: parent.parent.monthShift-- }
            }

            SvgIcon {
                icon: "chevron-right"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: Theme.fg
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: parent.parent.monthShift++ }
            }
        }

        // Weekdays Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: CalHelper.weekDays
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    ThemedText {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: Constants.size2Xs + 1
                        font.bold: true
                        color: Theme.muted
                    }
                }
            }
        }

        // Days Grid (6x7 = 42)
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 3
            columnSpacing: 3

            Repeater {
                model: parent.parent.gridData

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 17

                    readonly property var cell: modelData
                    readonly property bool isToday: cell ? cell.isToday : false
                    readonly property bool isCurrent: cell ? cell.isCurrentMonth : false

                    color: isToday ? Theme.accent : "transparent"

                    ThemedText {
                        anchors.centerIn: parent
                        text: cell ? cell.day : ""
                        font.pixelSize: Constants.sizeSm
                        font.bold: isToday
                        color: isToday
                            ? (Theme.isDark ? "#000000" : "#ffffff")
                            : (isCurrent ? Theme.fg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.25))
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. TAREAS (TODO)
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.widgetSubTab === 1
        spacing: 10

        // Add task input
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: taskInputField
                Layout.fillWidth: true
                implicitHeight: 36
                placeholderText: "Escribí una nueva tarea y presioná Enter..."
                placeholderTextColor: Theme.muted
                color: Theme.fg
                font.family: Constants.fontFamily
                background: Rectangle {
                    color: Theme.bgSecondary
                    radius: Constants.sizeSm
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                }
                onAccepted: {
                    if (text.trim() !== "") {
                        Todo.addTask(text.trim());
                        text = "";
                    }
                }
            }

            ThemedButton {
                text: "Añadir"
                onClicked: {
                    if (taskInputField.text.trim() !== "") {
                        Todo.addTask(taskInputField.text.trim());
                        taskInputField.text = "";
                    }
                }
            }
        }

        // Tasks list
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            spacing: 6
            model: Todo.list
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: taskItem
                required property var modelData
                required property int index

                width: ListView.view.width
                implicitHeight: 44
                radius: Constants.sizeLg
                color: modelData?.done ? Qt.rgba(Theme.bgSecondary.r, Theme.bgSecondary.g, Theme.bgSecondary.b, 0.5) : (taskHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    SvgIcon {
                        icon: taskItem.modelData?.done ? "check" : "circle"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: taskItem.modelData?.done ? Theme.accent : Theme.muted
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: taskItem.modelData?.done ? Todo.markUnfinished(taskItem.index) : Todo.markDone(taskItem.index)
                        }
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: taskItem.modelData?.content || ""
                        font.pixelSize: Constants.sizeSm
                        color: taskItem.modelData?.done ? Theme.muted : Theme.fg
                        elide: Text.ElideRight
                        font.strikeout: taskItem.modelData?.done
                    }

                    SvgIcon {
                        icon: "x"
                        iconSize: Constants.sizeSm
                        flat: true
                        iconColor: Theme.muted
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Todo.deleteItem(taskItem.index) }
                    }
                }

                HoverHandler { id: taskHover }
            }
        }

        // Empty state when no tasks
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: Constants.sizeLg
            color: Theme.bgSecondary
            visible: Todo.list.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No tenés tareas pendientes"
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }
    }

    // ==========================================
    // 3. FOCO (POMODORO & CRONÓMETRO)
    // ==========================================
    ColumnLayout {
        id: pomoSection
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.widgetSubTab === 2
        spacing: 14

        property int pomoMode: 0 // 0 = Pomodoro, 1 = Cronómetro
        property int remainingSecs: 25 * 60
        property int elapsedSecs: 0
        property bool isRunning: false
        property int sessionsCompleted: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ThemedText {
                text: pomoSection.pomoMode === 0 ? "Temporizador Pomodoro" : "Cronómetro"
                font.bold: true
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
            }

            Item { Layout.fillWidth: true }

            ThemedButton {
                text: pomoSection.pomoMode === 0 ? "Cambiar a Cronómetro" : "Cambiar a Pomodoro"
                onClicked: {
                    pomoSection.pomoMode = pomoSection.pomoMode === 0 ? 1 : 0;
                    pomoSection.isRunning = false;
                }
            }
        }

        // Big Digital Clock Display
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: Constants.sizeLg
            color: Theme.bgSecondary

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: pomoSection.pomoMode === 0 ? pomoSection.fmtPomo() : pomoSection.fmtStopwatch()
                    font.pixelSize: 48
                    font.bold: true
                    color: Theme.fg
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: pomoSection.pomoMode === 0
                        ? (pomoSection.isRunning ? ("Sesión #" + (pomoSection.sessionsCompleted + 1) + " • En foco") : "25 minutos de concentración")
                        : (pomoSection.isRunning ? "Cronómetro en marcha..." : "Listo para iniciar")
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            ThemedButton {
                text: pomoSection.isRunning ? "Pausar" : "Iniciar"
                onClicked: pomoSection.isRunning = !pomoSection.isRunning
            }

            ThemedButton {
                text: "Reiniciar"
                onClicked: {
                    pomoSection.isRunning = false;
                    pomoSection.remainingSecs = 25 * 60;
                    pomoSection.elapsedSecs = 0;
                }
            }

            ThemedButton {
                text: "+5 min"
                visible: pomoSection.pomoMode === 0
                onClicked: pomoSection.remainingSecs += 5 * 60
            }
        }

        Timer {
            interval: 1000
            running: pomoSection.isRunning
            repeat: true
            onTriggered: {
                if (pomoSection.pomoMode === 0) {
                    pomoSection.remainingSecs--;
                    if (pomoSection.remainingSecs <= 0) {
                        pomoSection.remainingSecs = 25 * 60;
                        pomoSection.sessionsCompleted++;
                        pomoSection.isRunning = false;
                        Quickshell.execDetached(["notify-send", "Pomodoro completado", "¡Buen trabajo! Tomate un descanso.", "-a", "Quickshell"]);
                    }
                } else {
                    pomoSection.elapsedSecs++;
                }
            }
        }

        function fmtPomo(): string {
            const m = Math.floor(pomoSection.remainingSecs / 60);
            const s = pomoSection.remainingSecs % 60;
            return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
        }

        function fmtStopwatch(): string {
            const h = Math.floor(pomoSection.elapsedSecs / 3600);
            const m = Math.floor((pomoSection.elapsedSecs % 3600) / 60);
            const s = pomoSection.elapsedSecs % 60;
            return (h > 0 ? h + ":" : "") + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
        }
    }
}
