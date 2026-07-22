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

    Popup {
        id: popup
        visible: root._open
        width: 280
        height: 200
        x: -popup.width / 2 + root.width / 2
        y: root.height

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: "Usage"
                font.bold: true
            }

            Text {
                text: "Weekly: " + (UsageTracker.weeklyRemainingPercent >= 0
                    ? Math.round(UsageTracker.weeklyRemainingPercent) + "%"
                    : "—")
            }

            Text {
                text: "Resets: " + (UsageTracker.weeklyResetDescription.length > 0
                    ? UsageTracker.weeklyResetDescription
                    : "—")
            }

            Text {
                text: "Last update: " + (UsageTracker.lastUpdatedText.length > 0
                    ? UsageTracker.lastUpdatedText
                    : "—")
            }
        }
    }
}
