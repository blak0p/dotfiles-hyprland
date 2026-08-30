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

TopPopup {
    id: root

    popupId: "controlCenter"
    floating: true
    contentWidth: 400
    contentHeight: contentCol.implicitHeight
    autoCloseOnUnhover: false

    readonly property int contentHeightHint: 300

    // Nav: 0 Inicio, 1 Red, 2 Bluetooth, 3 Audio, 4 Widgets
    property int activeView: 0

    ColumnLayout {
        id: contentCol
        width: root.contentWidth
        spacing: 10

        // ===== Navigation header =====
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ThemedText {
                text: "Centro de control"
                font.pixelSize: Constants.sizeXl
                font.bold: true
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            SvgIcon {
                icon: "x"
                iconSize: Constants.sizeLg
                flat: true
                iconColor: closeHover.hovered ? Theme.fg : Theme.muted
                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.isOpen = false }
            }
        }

        ThemedTabs {
            activeValue: root.activeView
            Layout.fillWidth: true
            Layout.preferredHeight: 30

            ThemedTab { value: 0; text: "Inicio" }
            ThemedTab { value: 1; text: "Red" }
            ThemedTab { value: 2; text: "BT" }
            ThemedTab { value: 3; text: "Audio" }
            ThemedTab { value: 4; text: "Más" }

            onTabSelected: (v) => { root.activeView = v }
        }

        // ===== View content =====
        Flickable {
            Layout.fillWidth: true
            implicitHeight: viewLoader.implicitHeight
            contentHeight: viewLoader.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                visible: viewLoader.implicitHeight > height
            }

            Loader {
                id: viewLoader
                width: parent.width
                source: root.activeView === 0 ? Qt.resolvedUrl("HomeView.qml")
                    : root.activeView === 1 ? Qt.resolvedUrl("Sections/NetworkSection.qml")
                    : root.activeView === 2 ? Qt.resolvedUrl("Sections/BluetoothSection.qml")
                    : root.activeView === 3 ? Qt.resolvedUrl("Sections/AudioSection.qml")
                    : Qt.resolvedUrl("Sections/WidgetsSection.qml")

                onLoaded: {
                    if (item && item.hasOwnProperty("width"))
                        item.width = parent.width;
                    if (item && item.hasOwnProperty("contentHeightHint"))
                        item.contentHeightHint = root.contentHeightHint;
                }
            }
        }
    }
}
