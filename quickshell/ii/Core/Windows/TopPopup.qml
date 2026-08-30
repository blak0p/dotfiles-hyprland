import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property bool isOpen: false
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    default property alias content: innerLayout.data
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : innerLayout.implicitWidth) + (contentPadding + cornerRadius) * 2
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : innerLayout.implicitHeight) + contentPadding * 2
    property int targetHeight: preferredHeight > 0 ? preferredHeight : popupHeight
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool _visible: false
    readonly property int verticalOffset: Constants.sizeLg
    readonly property int overshootHeadroom: 20
    property real openProgress: 0
    property real bounceProgress: 0

    signal popupClosed()

    implicitWidth: smoothWidth + 2 * overshootHeadroom
    implicitHeight: smoothHeight + verticalOffset + 100
    visible: _visible
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
            if (!HyprlandService.enableAnimations)
                root._visible = false;

        }
    }
    state: root.isOpen ? "open" : "closed"
    states: [
        State {
            name: "open"

            PropertyChanges {
                target: root
                openProgress: 1
                bounceProgress: 1
            }

        },
        State {
            name: "closed"

            PropertyChanges {
                target: root
                openProgress: 0
                bounceProgress: 0
            }

        }
    ]
    transitions: [
        Transition {
            from: "closed"
            to: "open"
            enabled: HyprlandService.enableAnimations

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "openProgress"
                    duration: root.animationDuration
                    easing.type: Easing.OutExpo
                }

                NumberAnimation {
                    target: root
                    property: "bounceProgress"
                    duration: root.animationDuration
                    easing.type: Easing.OutExpo
                }

            }

        },
        Transition {
            from: "open"
            to: "closed"
            enabled: HyprlandService.enableAnimations
            onRunningChanged: {
                if (!running && !root.isOpen)
                    root._visible = false;

            }

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "openProgress"
                    duration: root.animationDuration
                    easing.type: Easing.InExpo
                }

                NumberAnimation {
                    target: root
                    property: "bounceProgress"
                    duration: root.animationDuration
                    easing.type: Easing.InExpo
                }

            }

        }
    ]

    Connections {
        function onActivePopupChanged() {
            if (popupId !== "" && AppState.activePopup !== popupId)
                root.isOpen = false;

        }

        function onTogglePopup(id) {
            if (popupId !== "" && id === popupId)
                root.isOpen = !root.isOpen;

        }

        function onOpenPopup(id) {
            if (popupId !== "" && id === popupId)
                root.isOpen = true;

        }

        target: AppState
    }

    Timer {
        id: closeDelayTimer

        interval: root.animationDuration + 50
        repeat: false
        onTriggered: {
            if (!root.isOpen)
                root._visible = false;

        }
    }

    Timer {
        id: autoCloseTimer

        interval: Constants.animExpressive
        repeat: false
        onTriggered: {
            screenshotCheckProc.running = true;
        }
    }

    Process {
        id: screenshotCheckProc

        command: ["pgrep", "-x", "slurp"]
        onExited: (code) => {
            if (code === 0)
                autoCloseTimer.start();
            else
                delayCheckProc.running = true;
        }
    }

    Process {
        id: delayCheckProc

        command: ["pgrep", "-f", "screenshot.sh"]
        onExited: (code) => {
            if (code === 0)
                autoCloseTimer.start();
            else
                root.isOpen = false;
        }
    }

    Item {
        id: animContainer

        width: smoothWidth
        height: smoothHeight
        x: root.overshootHeadroom
        y: 0
        opacity: openProgress
        scale: bounceProgress
        transformOrigin: Item.Top

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    autoCloseTimer.stop();
                else if (root.isOpen)
                    autoCloseTimer.start();
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Shape {
            id: bg

            property color shapeColor: root.backgroundColor
            readonly property real r: root.cornerRadius
            readonly property real w: width
            readonly property real h: height

            width: parent.width
            height: parent.height
            x: 0
            y: 0

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bg.shapeColor
                startX: 0
                startY: 0

                PathArc {
                    x: bg.r
                    y: bg.r
                    radiusX: bg.r
                    radiusY: bg.r
                    direction: PathArc.Clockwise
                }

                PathLine {
                    x: bg.r
                    y: bg.h - bg.r
                }

                PathQuad {
                    x: 2 * bg.r
                    y: bg.h
                    controlX: bg.r
                    controlY: bg.h
                }

                PathLine {
                    x: bg.w - 2 * bg.r
                    y: bg.h
                }

                PathQuad {
                    x: bg.w - bg.r
                    y: bg.h - bg.r
                    controlX: bg.w - bg.r
                    controlY: bg.h
                }

                PathLine {
                    x: bg.w - bg.r
                    y: bg.r
                }

                PathArc {
                    x: bg.w
                    y: 0
                    radiusX: bg.r
                    radiusY: bg.r
                    direction: PathArc.Clockwise
                }

                PathLine {
                    x: 0
                    y: 0
                }

            }

        }

        ColumnLayout {
            id: innerLayout

            x: root.contentPadding + root.cornerRadius
            y: root.contentPadding
            width: smoothWidth - (root.contentPadding + root.cornerRadius) * 2
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutExpo
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutExpo
        }

    }

}
