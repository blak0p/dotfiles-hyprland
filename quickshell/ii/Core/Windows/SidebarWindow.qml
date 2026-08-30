import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Services

PanelWindow {
    id: root

    property string popupId: ""
    property bool isOpen: false
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    default property alias content: innerLayout.data
    property int _screenHeight: 1080
    property int _screenWidth: 1920
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : innerLayout.implicitWidth) + contentPadding * 2
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : innerLayout.implicitHeight) + contentPadding * 2
    property int targetHeight: Math.min(preferredHeight > 0 ? preferredHeight : popupHeight, _screenHeight > 0 ? _screenHeight - 64 - 8 : popupHeight)
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool _visible: false
    readonly property int overshootHeadroom: 20
    property real openProgress: root.isOpen ? 1 : 0
    property real bounceProgress: root.isOpen ? 1 : 0

    signal popupClosed()
    signal fullyClosed()

    onWidthChanged: {
        if (width > 0)
            _screenWidth = width;

    }
    onHeightChanged: {
        if (height > 0)
            _screenHeight = height;

    }
    visible: _visible
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    onIsOpenChanged: {
        if (popupId === "")
            return ;

        if (isOpen) {
            if (AppState.activePopup !== popupId)
                AppState.activePopup = popupId;

            closeDelayTimer.stop();
            _visible = true;
        } else {
            if (AppState.activePopup === popupId)
                AppState.activePopup = "";

            root.popupClosed();
            if (!HyprlandService.enableAnimations) {
                root._visible = false;
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
            }
        }
    }

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

        interval: root.animationDuration + 50
        repeat: false
        onTriggered: {
            if (!root.isOpen) {
                root._visible = false;
                root.fullyClosed();
            }
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: animContainer

            readonly property real closedX: _screenWidth > 0 ? _screenWidth + 20 : 3000
            readonly property real openX: _screenWidth > 0 ? _screenWidth - smoothWidth - 8 : 3000

            width: smoothWidth
            height: smoothHeight
            x: closedX + (openX - closedX) * bounceProgress
            y: 64
            opacity: openProgress

            MouseArea {
                anchors.fill: parent
            }

            Rectangle {
                id: bg

                anchors.fill: parent
                color: root.backgroundColor
                radius: root.cornerRadius
            }

            ColumnLayout {
                id: innerLayout

                x: root.contentPadding
                y: root.contentPadding
                width: smoothWidth - root.contentPadding * 2
                height: smoothHeight - root.contentPadding * 2
            }

        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: openProgressAnim

            duration: root.animationDuration
            easing.type: Easing.OutCubic
            onRunningChanged: {
                if (!running && !root.isOpen)
                    root._visible = false;

            }
        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.animationDuration + 100
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }

    }

}
