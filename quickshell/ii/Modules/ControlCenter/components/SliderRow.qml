import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Core
import qs.Core.Components

Item {
    id: root

    property string icon: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property bool available: true
    property bool dimmed: false
    property bool highlightIcon: false
    property bool showChevron: false

    signal moved(int value)
    signal iconClicked()
    signal chevronClicked()

    implicitHeight: 48
    implicitWidth: 320

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium || 14
        color: Theme.bgSecondary || "#141414"
        border.color: Theme.border || Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        opacity: root.available ? 1 : 0.45

        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: root.showChevron ? 10 : 14
            spacing: 10

            // Left icon squircle
            Rectangle {
                id: iconContainer
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 10
                color: (!root.dimmed && root.highlightIcon)
                    ? (iconMouse.containsMouse ? "#f0f0f0" : "#ffffff")
                    : (iconMouse.containsMouse ? (Theme.bgHover || "#333333") : (Theme.bgTertiary || "#262626"))

                Behavior on color { ColorAnimation { duration: 140 } }

                ThemedText {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Theme.fontMono || "monospace"
                    font.pixelSize: 16
                    color: (!root.dimmed && root.highlightIcon)
                        ? "#000000"
                        : (root.dimmed ? (Theme.muted || "#8e8e93") : (Theme.fg || "#ffffff"))

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.available
                    onClicked: root.iconClicked()
                }
            }

            // Central Slider
            Slider {
                id: slider
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                from: root.from
                to: root.to
                stepSize: root.stepSize
                value: root.value
                enabled: root.available
                leftPadding: 3
                rightPadding: 3
                topPadding: 0
                bottomPadding: 0
                padding: 0

                background: Rectangle {
                    id: trackBg
                    x: slider.leftPadding
                    y: slider.topPadding + (slider.availableHeight - height) / 2
                    width: slider.availableWidth
                    height: 26
                    radius: height / 2
                    color: Theme.bgTertiary || "#262626"
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: slider.visualPosition <= 0 ? 0 : Math.min(trackBg.width, Math.max(20, slider.visualPosition * (trackBg.width - 20) + 20))
                        radius: parent.radius
                        color: root.dimmed
                            ? (Theme.bgTertiary || "#3a3a3a")
                            : (sliderHover.hovered || slider.pressed ? "#757575" : "#666666")

                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                handle: Rectangle {
                    id: thumb
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + (slider.availableHeight - height) / 2
                    width: 20
                    height: 20
                    radius: width / 2
                    color: root.dimmed ? (Theme.muted || "#8e8e93") : "#ffffff"
                    scale: slider.pressed ? 1.08 : (sliderHover.hovered ? 1.04 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                HoverHandler {
                    id: sliderHover
                    cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse
                    enabled: root.available
                    onWheel: event => {
                        const direction = event.angleDelta.y > 0 ? 2 : -2;
                        root.moved(Math.min(root.to, Math.max(root.from, root.value + direction)));
                    }
                }

                onMoved: root.moved(Math.round(slider.value))
            }

            // Percentage value
            ThemedText {
                id: percentLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: `${root.value}%`
                font.pixelSize: Theme.fontSizeSmall || 13
                font.bold: true
                color: root.dimmed ? (Theme.muted || "#8e8e93") : (Theme.fg || "#ffffff")
            }

            // Optional right chevron
            Item {
                id: chevronButton
                visible: root.showChevron
                Layout.preferredWidth: 18
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter

                ThemedText {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Theme.fontMono || "monospace"
                    font.pixelSize: 14
                    color: chevronMouse.containsMouse ? (Theme.fg || "#ffffff") : (Theme.muted || "#8e8e93")

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: chevronMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.available && root.showChevron
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chevronClicked()
                }
            }
        }

        Binding {
            target: slider
            property: "value"
            value: root.value
            when: !slider.pressed
            restoreMode: Binding.RestoreBindingOrValue
        }
    }
}
