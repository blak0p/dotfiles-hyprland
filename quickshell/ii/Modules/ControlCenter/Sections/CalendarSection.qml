import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import "../CalendarHelper.js" as CalHelper

ColumnLayout {
    id: root

    property int monthShift: 0
    property var viewingDate: CalHelper.getDateInXMonthsTime(monthShift)
    property var gridData: CalHelper.getCalendarGrid(viewingDate, monthShift === 0)

    spacing: 8

    // Month header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: calPrevHover.containsMouse ? Theme.bgTertiary : Qt.rgba(1, 1, 1, 0.04)
            scale: calPrevHover.pressed ? 0.90 : (calPrevHover.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-left"
                iconSize: 12
                flat: true
                iconColor: calPrevHover.containsMouse ? Theme.accent : Theme.fg
            }

            MouseArea {
                id: calPrevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthShift--
            }
        }

        ThemedText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: {
                const monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                                    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
                const d = root.viewingDate;
                return d ? (monthNames[d.getMonth()] + " " + d.getFullYear()) : "";
            }
            font.bold: true
            font.pixelSize: Constants.sizeSm
            color: Theme.fg
        }

        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: calNextHover.containsMouse ? Theme.bgTertiary : Qt.rgba(1, 1, 1, 0.04)
            scale: calNextHover.pressed ? 0.90 : (calNextHover.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-right"
                iconSize: 12
                flat: true
                iconColor: calNextHover.containsMouse ? Theme.accent : Theme.fg
            }

            MouseArea {
                id: calNextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthShift++
            }
        }
    }

    // Wheel Handler for Month Scrolling
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                root.monthShift--;
            } else if (event.angleDelta.y < 0) {
                root.monthShift++;
            }
        }
    }

    // Week day headers
    RowLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: CalHelper.weekDays
            delegate: Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                ThemedText {
                    anchors.centerIn: parent
                    text: modelData.day
                    font.pixelSize: Constants.size3Xs + 3
                    font.bold: true
                    color: Theme.muted
                }
            }
        }
    }

    // Day grid 6x7
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: root.gridData

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                radius: 11

                readonly property var cell: modelData
                readonly property bool isToday: cell ? cell.isToday : false
                readonly property bool isCurrent: cell ? cell.isCurrentMonth : false

                color: isToday ? Theme.accent : "transparent"

                ThemedText {
                    anchors.centerIn: parent
                    text: cell ? cell.day : ""
                    font.pixelSize: Constants.size2Xs + 3
                    font.bold: isToday
                    color: isToday
                        ? (Theme.isDark ? "#000000" : "#ffffff")
                        : (isCurrent ? Theme.fg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.25))
                }
            }
        }
    }
}
