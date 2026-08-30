import QtQuick
import qs.Core

Rectangle {
    id: root

    property int activeIndex: 0
    property int lastIndex: 0
    property int animOff: 0
    property var updateCallback: null
    default property alias content: contentContainer.data

    signal contentNeedsUpdate(int newIndex)

    function triggerTransition(direction, callback) {
        switchAnim.complete();
        root.animOff = 40 * direction;
        root.updateCallback = callback;
        switchAnim.start();
    }

    color: Theme.bgSecondary
    onActiveIndexChanged: {
        if (activeIndex === lastIndex)
            return ;

        switchAnim.complete();
        root.animOff = 40 * (root.activeIndex > root.lastIndex ? 1 : -1);
        switchAnim.start();
        root.lastIndex = root.activeIndex;
    }

    SequentialAnimation {
        id: switchAnim

        NumberAnimation {
            target: contentContainer
            property: "opacity"
            to: 0
            duration: Constants.animFast
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: {
                if (root.updateCallback) {
                    root.updateCallback();
                    root.updateCallback = null;
                } else {
                    root.contentNeedsUpdate(root.activeIndex);
                }
            }
        }

        PropertyAction {
            target: contentContainer
            property: "anchors.topMargin"
            value: root.animOff
        }

        PropertyAction {
            target: contentContainer
            property: "anchors.bottomMargin"
            value: -root.animOff
        }

        PropertyAction {
            target: contentContainer
            property: "scale"
            value: 0.95
        }

        ParallelAnimation {
            NumberAnimation {
                target: contentContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

            NumberAnimation {
                target: contentContainer
                properties: "anchors.topMargin,anchors.bottomMargin"
                to: 0
                duration: Constants.animSlow
                easing.type: Easing.OutBack
            }

            NumberAnimation {
                target: contentContainer
                property: "scale"
                to: 1
                duration: Constants.animSlow
                easing.type: Easing.OutBack
            }

        }

    }

    Rectangle {
        id: bgRect

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        anchors.leftMargin: 0
        color: Theme.bg
        radius: Constants.sizeLg

        Item {
            id: contentContainer

            anchors.fill: parent
            clip: true
        }

    }

}
