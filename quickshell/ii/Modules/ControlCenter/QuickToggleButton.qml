import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services

// A compact toggle card for Control Center quick actions.
// Supports quick toggle on card/icon + optional detail arrow to drill down into networks/devices.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool toggled: false
    property bool hasDetail: false

    signal clicked()
    signal detailClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 64

    radius: Constants.sizeLg
    color: toggled
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
        : (btnHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
    border.width: toggled ? 1 : 0
    border.color: toggled
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
        : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Icon Pill
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 10
            color: toggled
                ? Theme.accent
                : (btnHover.hovered ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))

            SvgIcon {
                anchors.centerIn: parent
                icon: root.icon
                iconSize: 16
                flat: true
                iconColor: toggled
                    ? (Theme.isDark ? "#000000" : "#ffffff")
                    : Theme.muted
            }

            TapHandler {
                onTapped: root.clicked()
            }
        }

        // Text labels
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            ThemedText {
                text: root.label
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: toggled ? Theme.accent : Theme.fg
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            ThemedText {
                text: root.sublabel
                font.pixelSize: Constants.size2Xs + 1
                color: Theme.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Optional Drilldown Chevron
        Rectangle {
            visible: root.hasDetail
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: detailHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-right"
                iconSize: 14
                flat: true
                iconColor: toggled ? Theme.accent : Theme.muted
            }

            HoverHandler {
                id: detailHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.detailClicked()
            }
        }
    }

    HoverHandler {
        id: btnHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: Constants.animFast }
    }
}
