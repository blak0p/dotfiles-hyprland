pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Windows
import qs.Core.Services
import qs.services

import "Sections" as Sections

TopPopup {
    id: root

    popupId: "controlCenter"
    floating: true
    contentWidth: 360
    contentHeight: (root.activeView === "home" ? homeView.implicitHeight : networkSection.implicitHeight) + 32
    autoCloseOnUnhover: false

    readonly property int contentHeightHint: 300

    // "home" | "network"
    property string activeView: "home"

    onIsOpenChanged: {
        if (!isOpen)
            activeView = "home";
    }

    Item {
        id: contentWrapper
        implicitWidth: root.contentWidth
        implicitHeight: root.contentHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ==========================================
            // 1. HOME VIEW: ONLY WI-FI
            // ==========================================
            ColumnLayout {
                id: homeView
                visible: root.activeView === "home"
                Layout.fillWidth: true
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ThemedText {
                        text: Translation.tr("Control Center")
                        font.pixelSize: Constants.sizeLg
                        font.bold: true
                        color: Theme.fg
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 12
                        color: closeMouse.containsMouse ? Theme.bgTertiary : "transparent"

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "x"
                            iconSize: Constants.sizeSm
                            flat: true
                            iconColor: closeMouse.containsMouse ? Theme.fg : Theme.muted
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.activePopup = ""
                        }
                    }
                }

            // ONLY Wi-Fi toggle
            QuickToggleButton {
                icon: Network.wifiEnabled ? "wifi" : "wifi-off"
                label: Translation.tr("Wi-Fi")
                sublabel: Network.wifiEnabled ? (Network.networkName ? Network.networkName : Translation.tr("Connected")) : Translation.tr("Disconnected")
                toggled: Network.wifiEnabled
                hasDetail: true
                onClicked: Network.toggleWifi()
                onDetailClicked: root.activeView = "network"
            }
        }

        // ==========================================
        // 2. NETWORK SUB-PANEL
        // ==========================================
        Sections.NetworkSection {
            id: networkSection
            visible: root.activeView === "network"
            Layout.fillWidth: true
            canGoBack: true
            contentHeightHint: root.contentHeightHint
            onBack: root.activeView = "home"
        }
    }
}
}





