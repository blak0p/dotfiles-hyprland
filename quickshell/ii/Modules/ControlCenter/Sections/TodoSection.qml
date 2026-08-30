import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300

    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedText {
            text: "Tareas"
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        ThemedText {
            text: Todo.list.filter(t => !t.done).length + " pendientes"
            font.pixelSize: Constants.sizeSm
            color: Theme.muted
        }
    }

    // Add task
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextField {
            id: taskInput
            Layout.fillWidth: true
            implicitHeight: 32
            placeholderText: "Nueva tarea..."
            placeholderTextColor: Theme.muted
            color: Theme.fg
            background: Rectangle {
                color: Theme.bgSecondary
                radius: Constants.sizeXs
                border.color: Theme.border
            }
            onAccepted: addTask()
        }

        ThemedButton {
            text: "Añadir"
            onClicked: addTask()
        }
    }

    // Task list
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.contentHeightHint, 240)
        Layout.maximumHeight: 280
        clip: true
        spacing: 6
        model: Todo.list
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: taskRow
            required property var modelData
            required property int index

            width: ListView.view.width
            implicitHeight: 40
            radius: Constants.sizeLg
            color: modelData.done ? Theme.bgSecondary : (taskHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                SvgIcon {
                    icon: modelData.done ? "circle-check" : "circle-dashed-check"
                    iconSize: Constants.sizeLg
                    flat: true
                    iconColor: modelData.done ? Theme.accent : Theme.muted
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: modelData.done ? Todo.markUnfinished(index) : Todo.markDone(index)
                    }
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.content || ""
                    font.pixelSize: Constants.sizeSm
                    color: modelData.done ? Theme.muted : Theme.fg
                    elide: Text.ElideRight
                    font.strikeout: modelData.done
                }

                SvgIcon {
                    icon: "x"
                    iconSize: Constants.sizeSm
                    flat: true
                    iconColor: Theme.muted
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Todo.deleteItem(index) }
                }
            }

            HoverHandler { id: taskHover }
        }
    }

    function addTask(): void {
        if (taskInput.text.trim() !== "") {
            Todo.addTask(taskInput.text.trim());
            taskInput.text = "";
        }
    }
}
