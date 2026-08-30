import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Item {
    id: root

    property string icon: ""
    property string glyph: ""
    property string text: ""
    property var value
    property color activeColor: Theme.accent
    property bool isActive: false

    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + Constants.sizeLg * 2
    implicitHeight: rowLayout.implicitHeight + Constants.sizeSm * 2

    RowLayout {
        id: rowLayout

        anchors.centerIn: parent
        spacing: Constants.sizeXs

        SvgIcon {
            id: svgIcon

            visible: root.icon !== ""
            icon: root.icon
            iconSize: Constants.sizeSm
            flat: true
            iconColor: root.isActive ? root.activeColor : (mouseArea.containsMouse ? Theme.fg : Theme.muted)

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        SvgIcon {
            id: svgGlyph

            visible: root.glyph !== ""
            icon: root.glyph
            iconSize: Constants.sizeLg
            flat: true
            iconColor: root.isActive ? root.activeColor : (mouseArea.containsMouse ? Theme.fg : Theme.muted)

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            text: root.text
            font.pixelSize: Constants.sizeSm
            font.weight: root.isActive ? Font.Bold : Font.Normal
            color: root.isActive ? root.activeColor : (mouseArea.containsMouse ? Theme.fg : Theme.muted)

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
            var p = root.parent;
            while (p) {
                if (p.hasOwnProperty("activeValue")) {
                    p.tabSelected(root.value);
                    break;
                }
                p = p.parent;
            }
        }
    }

}
