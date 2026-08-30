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

        ThemedText {
            text: {
                const monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                                    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
                return monthNames[root.viewingDate.getMonth()] + " " + root.viewingDate.getFullYear();
            }
            font.bold: true
            font.pixelSize: Constants.sizeSm
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        SvgIcon {
            icon: "chevron-left"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: Theme.fg
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.monthShift-- }
        }

        SvgIcon {
            icon: "chevron-right"
            iconSize: Constants.sizeLg
            flat: true
            iconColor: Theme.fg
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.monthShift++ }
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
