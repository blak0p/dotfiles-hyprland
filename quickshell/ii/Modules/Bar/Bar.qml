import "Components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.SystemTray as STray
import qs.Modules.Bar.Widgets.DynamicIsland

Item {
    id: mainBar

    required property var notificationService
    required property var mainPanelWidget
    property bool clockHovered: false

    // 1. Left Island (Minflair Menu + Workspaces)
    Rectangle {
        id: leftIsland

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: hLeftGroup.implicitWidth + 32
        color: Theme.bg
        radius: height / 2
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
            id: hLeftGroup

            anchors.centerIn: parent
            spacing: Constants.sizeLg

            MinflairButton {
                widget: mainBar.mainPanelWidget
            }

            Workspaces {
            }
        }
    }

    // 2. Right Island (Control Center + SysTray + Power)
    Rectangle {
        id: rightIsland

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: hRightGroup.implicitWidth + 32
        color: Theme.bg
        radius: height / 2
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
            id: hRightGroup

            anchors.centerIn: parent
            spacing: Constants.sizeLg

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
