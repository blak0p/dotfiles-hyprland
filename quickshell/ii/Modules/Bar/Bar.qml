import "Components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.SystemTray as STray

Item {
    id: mainBar

    required property var notificationService
    required property var mainPanelWidget
    property bool clockHovered: false

    Rectangle {
        id: barContent

        anchors.fill: parent
        color: Theme.bg
        radius: Constants.size2Xl

        RowLayout {
            id: hLeftGroup

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: Constants.sizeLg
            anchors.leftMargin: 16

            MinflairButton {
                widget: mainBar.mainPanelWidget
            }

            Workspaces {
            }

        }

        Item {
            id: centerClockArea

            anchors.centerIn: parent
            width: centerClock.implicitWidth
            height: mainBar.height

            ClockButton {
                id: centerClock

                anchors.centerIn: parent
            }

            MouseArea {
                id: clockHoverArea

                anchors.fill: parent
                hoverEnabled: true
                onEntered: mainBar.clockHovered = true
                onExited: mainBar.clockHovered = false
            }

        }

        RowLayout {
            id: hRightGroup

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: Constants.sizeLg
            anchors.rightMargin: 16

            ControlCenterButton {
                notificationService: mainBar.notificationService
            }

            Rectangle {
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 150 + Constants.sizeSm * 2
                Layout.preferredWidth: trayRow.implicitWidth > 0 ? Math.min(trayRow.implicitWidth + Constants.sizeSm * 2, Layout.maximumWidth) : 0
                color: Theme.bgSecondary
                radius: height / 2
                visible: trayRow.implicitWidth > 0

                Flickable {
                    id: trayFlick

                    anchors.fill: parent
                    anchors.leftMargin: Constants.sizeSm
                    anchors.rightMargin: Constants.sizeSm
                    contentWidth: trayRow.implicitWidth
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: (wheel) => {
                            trayFlick.contentX = Math.max(0, Math.min(trayFlick.contentX - (wheel.angleDelta.y / 2), trayFlick.contentWidth - trayFlick.width));
                        }
                    }

                    RowLayout {
                        id: trayRow

                        height: parent.height
                        spacing: Constants.sizeSm

                        Repeater {
                            model: SystemTray.items

                            delegate: STray.TrayItem {
                                trayItem: modelData
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (modelData.menu)
                                            AppState.togglePopup("systemTray_" + index);
                                        else if (modelData.secondaryActivate)
                                            modelData.secondaryActivate();
                                    }
                                }
                            }

                        }

                    }

                }

            }

            PowerButton {
            }

        }

    }

}
