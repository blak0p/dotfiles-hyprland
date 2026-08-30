import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

FocusScope {
    id: root

    property alias text: searchInput.text
    property string placeholderText: "Search..."
    property int preferredHeight: Constants.size4Xl
    property bool showClearButton: true
    property alias textField: searchInput

    signal searchRequested(string text)
    signal accepted()

    Layout.fillWidth: true
    Layout.preferredHeight: preferredHeight

    Rectangle {
        id: bgRect

        anchors.fill: parent
        color: Theme.bgSecondary
        radius: height / 2
        border.color: searchInput.activeFocus ? Theme.accent : Theme.border
        border.width: 1

        Behavior on border.color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: Constants.sizeLg

        SvgIcon {
            icon: "search"
            iconColor: Theme.muted
            iconSize: Constants.sizeLg
            flat: true
        }

        TextField {
            id: searchInput

            focus: true
            Layout.fillWidth: true
            placeholderText: root.placeholderText
            placeholderTextColor: Theme.muted
            font.family: Constants.fontFamily
            font.pixelSize: Constants.sizeMd
            color: Theme.fg
            selectByMouse: true
            background: null
            onTextChanged: root.searchRequested(text)
            onAccepted: root.accepted()
        }

        SvgIconButton {
            id: clearButton

            visible: root.showClearButton && searchInput.text !== ""
            icon: "x"
            iconColor: Theme.muted
            iconSize: Constants.sizeMd
            flat: true
            onClicked: {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

    }

}
