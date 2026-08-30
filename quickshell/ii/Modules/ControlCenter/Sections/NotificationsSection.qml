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
            text: "Notificaciones"
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        ThemedButton {
            text: "Limpiar todo"
            disabled: Notifications.list.length === 0
            onClicked: Notifications.discardAllNotifications()
        }
    }

    // Empty state
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 120
        radius: Constants.sizeLg
        color: Theme.bgSecondary
        visible: Notifications.list.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "bell"
                iconSize: 26
                flat: true
                iconColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)
            }

            ThemedText {
                Layout.alignment: Qt.AlignHCenter
                text: "Sin notificaciones"
                font.pixelSize: Constants.sizeSm
                color: Theme.muted
            }
        }
    }

    // Feed
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.contentHeightHint, 240)
        Layout.maximumHeight: 280
        clip: true
        spacing: 8
        visible: Notifications.list.length > 0
        model: Notifications.list
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: notifCol.implicitHeight + 14
            radius: Constants.sizeLg
            color: Theme.bgSecondary

            ColumnLayout {
                id: notifCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ThemedText {
                        text: modelData.appName || "Sistema"
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillWidth: true }

                    ThemedText {
                        text: modelData.time ? Qt.formatDateTime(new Date(modelData.time), "HH:mm") : ""
                        font.pixelSize: Constants.size2Xs + 1
                        color: Theme.muted
                    }

                    SvgIcon {
                        icon: "x"
                        iconSize: Constants.sizeSm
                        flat: true
                        iconColor: Theme.muted
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Notifications.discardNotification(modelData.notificationId) }
                    }
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.summary || ""
                    font.pixelSize: Constants.sizeSm
                    font.bold: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: modelData.body || ""
                    font.pixelSize: Constants.size2Xs + 2
                    color: Theme.muted
                    elide: Text.ElideRight
                    textFormat: Text.RichText
                    visible: text !== ""
                }
            }
        }
    }
}
