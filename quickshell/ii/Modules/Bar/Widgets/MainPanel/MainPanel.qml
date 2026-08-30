import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Windows
import qs.Modules.Bar.Widgets.MainPanel.Dashboard as MainPanelDashboard
import qs.Modules.Bar.Widgets.MainPanel.Performance as MainPanelPerformance
import qs.services

TopPopup {
    id: mainPanelPopup

    property int activeTab: 0
    property int slideDistance: 100

    Connections {
        function onVisibleChanged() {
            if (mainPanelPopup.visible)
                mainPanelPopup.activeTab = 0;

        }

        function on_WindowVisibleChanged() {
            if (mainPanelPopup._windowVisible)
                mainPanelPopup.activeTab = 0;

        }

        target: mainPanelPopup
    }

    ColumnLayout {
        id: mainLayout

        implicitWidth: {
            if (mainPanelPopup.activeTab === 0)
                return dashboardTab.implicitWidth;
            else if (mainPanelPopup.activeTab === 1)
                return performanceTab.implicitWidth;
            else if (mainPanelPopup.activeTab === 2)
                return codexTab.implicitWidth;
            return 800;
        }
        spacing: Constants.sizeLg

        ThemedTabs {
            id: headerRowItem

            Layout.fillWidth: true
            Layout.preferredHeight: Constants.size5Xl
            activeValue: mainPanelPopup.activeTab
            onTabSelected: (value) => {
                return mainPanelPopup.activeTab = value;
            }

            ThemedTab {
                glyph: mainPanelPopup.activeTab === 0 ? "dashboard-filled" : "dashboard"
                text: Translation.tr("Dashboard")
                value: 0
            }

            ThemedTab {
                glyph: mainPanelPopup.activeTab === 1 ? "performance-filled" : "performance"
                text: Translation.tr("Performance")
                value: 1
            }

            ThemedTab {
                glyph: "code"
                text: Translation.tr("Codex")
                value: 2
            }

        }

        Item {
            id: tabContainer

            Layout.fillWidth: true
            implicitWidth: mainLayout.implicitWidth
            implicitHeight: {
                let h = 330;
                if (mainPanelPopup.activeTab === 0)
                    h = dashboardTab.implicitHeight;
                else if (mainPanelPopup.activeTab === 1)
                    h = performanceTab.implicitHeight;
                else if (mainPanelPopup.activeTab === 2)
                    h = codexTab.implicitHeight;
                return h > 0 ? h : 330;
            }
            clip: true

            TabItem {
                id: dashboardTab

                index: 0

                MainPanelDashboard.Dashboard {
                    anchors.fill: parent
                    widget: mainPanelPopup
                }

            }

            TabItem {
                id: performanceTab

                index: 1

                MainPanelPerformance.Performance {
                    anchors.fill: parent
                }

            }

            TabItem {
                id: codexTab

                index: 2

                MainPanelDashboard.CodexBarCard {
                    anchors.fill: parent
                    active: mainPanelPopup.activeTab === 2
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    component TabItem: Item {
        id: tabItemRoot

        property int index
        default property alias content: container.children

        implicitWidth: container.children.length > 0 ? container.children[0].implicitWidth : 0
        implicitHeight: container.children.length > 0 ? container.children[0].implicitHeight : 330
        visible: mainPanelPopup.activeTab === index || opacity > 0.01
        enabled: mainPanelPopup.activeTab === index
        opacity: mainPanelPopup.activeTab === index ? 1 : 0
        anchors.fill: parent

        Item {
            id: container

            anchors.fill: parent
        }

        transform: Translate {
            x: (index - mainPanelPopup.activeTab) * mainPanelPopup.slideDistance

            Behavior on x {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

}
