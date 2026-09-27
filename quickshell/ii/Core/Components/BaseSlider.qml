import QtQuick
import QtQuick.Controls
import qs.Core
import qs.Core.Services

Slider {
    id: root

    property color color: Theme.accent
    property bool animateChanges: true

    topPadding: Constants.sizeSm
    bottomPadding: Constants.sizeSm

    HoverHandler {
        id: sliderHover

        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: root.hovered || root.pressed ? 6 : 4
        color: Theme.bgSecondary
        radius: height / 2

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: root.color
            radius: height / 2

            Behavior on width {
                enabled: HyprlandService.enableAnimations && root.animateChanges && !root.pressed

                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }
        }
    }

    handle: Item {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 14
        height: 14

        Rectangle {
            anchors.centerIn: parent
            width: root.hovered || root.pressed ? 14 : 0
            height: width
            radius: width / 2
            color: root.color
            scale: root.pressed ? 1.15 : (root.hovered ? 1.05 : 1.0)

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }
            }
        }

        Behavior on x {
            enabled: HyprlandService.enableAnimations && root.animateChanges && !root.pressed

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }
        }
    }

}
