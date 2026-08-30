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
    property int contentPadding: floating ? 0 : Constants.sizeLg
    default property alias content: innerLayout.data
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    property bool floating: true
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : innerLayout.implicitWidth) + (floating ? contentPadding * 2 : (contentPadding + cornerRadius) * 2)
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : innerLayout.implicitHeight) + contentPadding * 2
    property int targetHeight: preferredHeight > 0 ? preferredHeight : popupHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothHeight: 48
    property real smoothWidth: 160
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool _visible: false
    readonly property int verticalOffset: Constants.sizeLg
    readonly property int overshootHeadroom: 20
    property real openProgress: 0
    property real bounceProgress: 0
    property bool autoCloseOnUnhover: true

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
            closeDelayTimer.restart();
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
                smoothWidth: root.targetWidth
                smoothHeight: root.targetHeight
            }
        },
        State {
            name: "closed"

            PropertyChanges {
                target: root
                openProgress: 0
                bounceProgress: 0
                smoothWidth: 160
                smoothHeight: 48
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
                    property: "smoothWidth"
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.12
                }

                NumberAnimation {
                    target: root
                    property: "smoothHeight"
                    duration: 320
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: root
                    property: "openProgress"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "open"
            to: "closed"
            enabled: HyprlandService.enableAnimations

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "smoothWidth"
                    duration: 220
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: root
                    property: "smoothHeight"
                    duration: 220
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: root
                    property: "openProgress"
                    duration: 180
                    easing.type: Easing.InCubic
                }
            }
        }
    ]

    Connections {
        function onActivePopupChanged() {
            if (popupId !== "") {
                if (AppState.activePopup === popupId)
                    root.isOpen = true;
                else
                    root.isOpen = false;
            }
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

        command: ["pgrep", "-f", "grimblast"]
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
        transformOrigin: Item.Top
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (!root.autoCloseOnUnhover)
                    return;
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
            visible: !root.floating

            layer.enabled: true
            layer.samples: 4
            layer.smooth: true
            preferredRendererType: Shape.CurveRenderer

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
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
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

        Rectangle {
            id: floatingBg
            visible: root.floating
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.backgroundColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }

        ColumnLayout {
            id: innerLayout

            x: root.floating ? 0 : (root.contentPadding + root.cornerRadius)
            y: root.floating ? 0 : root.contentPadding
            width: smoothWidth - (root.floating ? 0 : (root.contentPadding + root.cornerRadius) * 2)
            opacity: openProgress

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }
    }
}
