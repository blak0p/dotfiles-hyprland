import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    property string icon: ""
    property string title: ""
    property int usage: 0
    property color color: Theme.accent
    default property alias content: detailsContainer.data

    ColumnLayout {
        id: mainCol

        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            spacing: Constants.sizeSm
            Layout.fillWidth: true

            Rectangle {
                width: Constants.sizeXl + Constants.sizeXs
                height: width
                radius: Constants.sizeLg
                color: Theme.bgSecondary

                SvgIcon {
                    anchors.centerIn: parent
                    icon: root.icon
                    iconColor: root.color
                    flat: true
                }

            }

            ThemedText {
                text: root.title
                font.pixelSize: Constants.sizeMd
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            ThemedText {
                text: root.usage + "%"
                font.pixelSize: Constants.sizeLg
                font.bold: true
                color: root.color
            }

        }

        ColumnLayout {
            id: detailsContainer

            Layout.fillWidth: true
            spacing: Constants.sizeXs
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.bgSecondary

            Rectangle {
                width: parent.width * (root.usage / 100)
                height: parent.height
                radius: parent.radius
                color: root.color

                Behavior on width {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

        Item {
            Layout.fillHeight: true
        }

    }

}
