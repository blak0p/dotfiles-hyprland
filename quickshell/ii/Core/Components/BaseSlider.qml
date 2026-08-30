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
                enabled: HyprlandService.enableAnimations && root.animateChanges

                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on height {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

    }

    handle: Item {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 12
        height: 12

        Rectangle {
            anchors.centerIn: parent
            width: root.hovered || root.pressed ? 12 : 0
            height: width
            radius: width / 2
            color: root.color

            Behavior on width {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutQuad
                }

            }

        }

        Behavior on x {
            enabled: HyprlandService.enableAnimations && root.animateChanges

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

}
