import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

FocusScope {
    id: root

    property alias text: textInput.text
    property string label: ""
    property string placeholderText: ""
    property bool isPassword: false
    property bool revealPassword: false
    property alias textField: textInput

    signal editingFinished()

    Layout.fillWidth: true
    Layout.preferredHeight: (label !== "" ? 20 + Constants.sizeXs : 0) + 36

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeXs

        ThemedText {
            text: root.label
            font.pixelSize: Constants.sizeSm
            font.bold: true
            color: Theme.fg
            visible: root.label !== ""
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Theme.bg
            radius: Constants.sizeSm
            border.color: textInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeSm
                anchors.rightMargin: Constants.sizeSm
                spacing: Constants.sizeXs

                TextField {
                    id: textInput

                    focus: true
                    Layout.fillWidth: true
                    placeholderText: root.placeholderText
                    placeholderTextColor: Theme.muted
                    font.family: Constants.fontFamily
                    font.pixelSize: Constants.sizeSm
                    color: Theme.fg
                    selectByMouse: true
                    echoMode: (root.isPassword && !root.revealPassword) ? TextInput.Password : TextInput.Normal
                    background: null
                    onEditingFinished: root.editingFinished()
                }

                SvgIconButton {
                    icon: root.revealPassword ? "eye" : "eye-off"
                    iconColor: Theme.muted
                    hoverColor: Theme.accent
                    flat: true
                    visible: root.isPassword
                    onClicked: root.revealPassword = !root.revealPassword
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
