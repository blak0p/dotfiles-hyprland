// UsageTrackerWidget.qml — Public bar widget that displays usage data
// from the UsageTracker service.
//
// This is the GENERIC, brand-free version. It renders whatever the
// public UsageTracker service exposes: compact text in the bar, a popup
// with the basic numbers.
//
// If you want branded styling, custom layout, or extra fields, drop
// a UsageTrackerWidget override in your private custom layer. The public
// version is here as a sensible default so the bar always renders
// something even without a custom layer deployed.

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: false
    property bool _open: false

    onClicked: root._open = !root._open

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        Text {
            text: UsageTracker.compactText
            color: Appearance.colors.colOnLayer0
        }
    }

    PanelWindow {
        id: popupWindow
        visible: root._open
        color: "transparent"
        width: 280
        height: 200

        anchors.top: Config.options.bar.vertical ? undefined : root.QsWindow?.window?.top
        anchors.left: Config.options.bar.vertical ? root.QsWindow?.window?.left : undefined

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: "Usage"
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    text: "Weekly: " + (UsageTracker.weeklyRemainingPercent >= 0
                        ? Math.round(UsageTracker.weeklyRemainingPercent) + "%"
                        : "—")
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    text: "Resets: " + (UsageTracker.weeklyResetDescription.length > 0
                        ? UsageTracker.weeklyResetDescription
                        : "—")
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    text: "Last update: " + (UsageTracker.lastUpdatedText.length > 0
                        ? UsageTracker.lastUpdatedText
                        : "—")
                    color: Appearance.colors.colOnSurface
                }
            }
        }
    }
}
