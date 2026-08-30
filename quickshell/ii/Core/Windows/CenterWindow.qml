import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

PanelWindow {
    id: root

    property string popupId: ""
    property bool isOpen: false
    default property alias content: innerLayout.data
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animExpressive : 0
    property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    readonly property var easeCurve: [0.25, 0.1, 0.25, 1, 1, 1]
    readonly property var overshotCurve: [0.13, 0.99, 0.29, 1.05, 1, 1]
    property color backgroundColor: Theme.bg
    property int preferredWidth: 600
    property int preferredHeight: 500
    property bool _windowVisible: false

    signal popupOpened()
    signal popupClosed()
    signal fullyClosed()

    surfaceFormat.opaque: false
    onIsOpenChanged: {
        if (popupId === "")
            return ;

        if (isOpen) {
            if (AppState.activePopup !== popupId)
                AppState.activePopup = popupId;

            closeDelayTimer.stop();
            _windowVisible = true;
            root.popupOpened();
        } else {
            if (AppState.activePopup === popupId)
                AppState.activePopup = "";

            closeDelayTimer.start();
            root.popupClosed();
        }
    }
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    visible: _windowVisible

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.isOpen = false
    }

    Timer {
        id: closeDelayTimer

        interval: root.fadeDuration
        repeat: false
        onTriggered: {
            root._windowVisible = false;
            root.fullyClosed();
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: container

            width: root.preferredWidth
            height: root.preferredHeight
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Center
            focus: root.isOpen
            Keys.onEscapePressed: root.isOpen = false
            layer.enabled: true
            y: root.height > 0 ? (root.isOpen ? (root.height - root.preferredHeight) / 2 : root.height + Constants.size5Xl) : 3000
            opacity: 1
            scale: 1

            MouseArea {
                anchors.fill: parent
            }

            Rectangle {
                anchors.fill: parent
                color: root.backgroundColor
                radius: Constants.sizeLg * 2
                border.width: 2
                border.color: Theme.border
                clip: true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Constants.sizeLg
                spacing: Constants.sizeLg

                ColumnLayout {
                    id: innerLayout

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Constants.sizeLg
                }

            }

            Behavior on y {
                enabled: root.height > 0

                NumberAnimation {
                    duration: root.isOpen ? root.animationDuration : root.fadeDuration
                    easing.type: root.isOpen ? Easing.BezierSpline : Easing.Linear
                    easing.bezierCurve: root.isOpen ? root.overshotCurve : root.easeCurve
                }

            }

        }

    }

}
