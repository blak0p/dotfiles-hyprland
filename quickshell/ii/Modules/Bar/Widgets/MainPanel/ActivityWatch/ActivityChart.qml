import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components

RowLayout {
    id: chartRoot

    property var dataValues: [0, 0, 0, 0, 0, 0, 0]
    property var xLabels: ["", "", "", "", "", "", ""]
    property int maxValue: 0
    property bool animateHeight: true
    property int activeIndex: 6
    property int barWidth: 18
    property int colWidth: 30
    property int barSpacing: 12

    signal barClicked(int index)

    function formatDuration(sec) {
        if (sec < 60)
            return Math.round(sec) + "s";

        let min = Math.round(sec / 60);
        if (min < 60)
            return min + "m";

        let hr = Math.floor(min / 60);
        let remMin = min % 60;
        if (remMin === 0)
            return hr + "h";

        return hr + "h " + remMin + "m";
    }

    function formatYLabel(sec) {
        if (sec <= 0)
            return "0";

        if (sec < 60)
            return Math.round(sec) + "s";

        let min = Math.round(sec / 60);
        if (min < 60)
            return min + "m";

        let hr = Math.floor(min / 60);
        let remMin = min % 60;
        if (remMin === 0)
            return hr + "h";

        return hr + "h " + remMin + "m";
    }

    implicitWidth: yAxisLabelsContainer.width + spacing + (colWidth * 7) + (barSpacing * 6)
    spacing: Constants.sizeMd

    Item {
        id: yAxisLabelsContainer

        width: Constants.size3Xl
        Layout.fillHeight: true

        ThemedText {
            text: chartRoot.formatYLabel(chartRoot.maxValue)
            font.pixelSize: Constants.sizeXs
            color: Theme.muted
            anchors.right: parent.right
            y: -height / 2
        }

        ThemedText {
            text: chartRoot.formatYLabel(chartRoot.maxValue / 2)
            font.pixelSize: Constants.sizeXs
            color: Theme.muted
            anchors.right: parent.right
            y: (parent.height - 24) / 2 - height / 2
        }

        ThemedText {
            text: "0"
            font.pixelSize: Constants.sizeXs
            color: Theme.muted
            anchors.right: parent.right
            y: (parent.height - 24) - height / 2
        }

    }

    ColumnLayout {
        Layout.preferredWidth: (chartRoot.colWidth * 7) + (chartRoot.barSpacing * 6)
        Layout.fillHeight: true
        spacing: Constants.sizeXs

        Item {
            id: barsContainer

            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                y: 0
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                y: Math.round(parent.height / 2)
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                y: parent.height
            }

            RowLayout {
                anchors.fill: parent
                spacing: chartRoot.barSpacing

                Repeater {
                    model: chartRoot.dataValues

                    delegate: Item {
                        width: chartRoot.colWidth
                        Layout.preferredWidth: chartRoot.colWidth
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: chartRoot.barWidth
                            height: (parent && chartRoot.maxValue > 0) ? (parent.height * (modelData / chartRoot.maxValue)) : 0
                            color: Theme.accent
                            opacity: barHover.hovered ? 1 : (index === chartRoot.activeIndex ? 1 : 0.6)
                            radius: Constants.sizeXs

                            Behavior on height {
                                enabled: chartRoot.animateHeight

                                NumberAnimation {
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutCubic
                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Constants.animFast
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        HoverHandler {
                            id: barHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: chartRoot.barClicked(index)
                        }

                        ToolTip {
                            visible: barHover.hovered && modelData > 0
                            delay: 50

                            contentItem: ThemedText {
                                text: (chartRoot.xLabels[index] || "Day") + "  •  " + chartRoot.formatDuration(modelData)
                                font.pixelSize: Constants.sizeSm
                                font.bold: true
                                color: Theme.fg
                            }

                            background: Rectangle {
                                color: Theme.bgSecondary
                                border.color: Theme.border
                                border.width: 1
                                radius: Constants.sizeSm
                            }

                        }

                    }

                }

            }

        }

        RowLayout {
            Layout.fillWidth: true
            spacing: chartRoot.barSpacing

            Repeater {
                model: chartRoot.xLabels

                delegate: Item {
                    width: chartRoot.colWidth
                    Layout.preferredWidth: chartRoot.colWidth
                    Layout.preferredHeight: 16

                    ThemedText {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Constants.sizeXs
                        font.weight: index === chartRoot.activeIndex ? Font.Bold : Font.Normal
                        color: index === chartRoot.activeIndex ? Theme.accent : Theme.muted
                    }

                }

            }

        }

    }

}
