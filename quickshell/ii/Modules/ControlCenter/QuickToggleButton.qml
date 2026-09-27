import QtQuick
import QtQuick.Layouts
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services

// A compact toggle card for Control Center quick actions.
// Supports quick toggle on card/icon + optional detail arrow to drill down into networks/devices.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool toggled: false
    property bool hasDetail: false

    onToggledChanged: {
        if (!toggled) {
            turnOffAnim.restart();
        } else {
            turnOnAnim.restart();
        }
    }

    signal clicked()
    signal detailClicked()

    implicitWidth: 200
    implicitHeight: 68
    Layout.fillWidth: true
    Layout.preferredHeight: 68

    radius: Constants.sizeLg
    color: toggled
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
        : (btnMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
    border.width: toggled ? 1 : 0
    border.color: toggled
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
        : "transparent"

    scale: btnMouse.pressed ? 0.95 : (btnMouse.containsMouse ? 1.02 : 1)
    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

    // Icon Container with animated slash and spring physics
    Rectangle {
        id: iconContainer
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 12
        color: toggled
            ? Theme.accent
            : (btnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
        clip: false

        scale: btnMouse.pressed ? 0.94 : (btnMouse.containsMouse ? 1.05 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
        Behavior on color {
            ColorAnimation { duration: Constants.animFast }
        }

        // Subtle pulse ripple when turning on
        Rectangle {
            id: rippleRing
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
            opacity: 0
            scale: 1.0

            ParallelAnimation {
                id: rippleAnim
                NumberAnimation { target: rippleRing; property: "scale"; from: 1.0; to: 1.6; duration: 320; easing.type: Easing.OutCubic }
                NumberAnimation { target: rippleRing; property: "opacity"; from: 0.8; to: 0; duration: 320; easing.type: Easing.OutCubic }
            }
        }

        // Base Icon: Wi-Fi
        SvgIcon {
            id: baseIcon
            anchors.centerIn: parent
            icon: root.icon.replace("-off", "")
            iconSize: 18
            flat: true
            iconColor: toggled
                ? (Theme.isDark ? "#000000" : "#ffffff")
                : Theme.fg
            transformOrigin: Item.Center
            scale: 1.0
        }

        // 360-Degree Orbital Comet Trail & Contracting Slash Canvas
        Item {
            id: orbitalCanvas
            anchors.centerIn: parent
            width: 36
            height: 36
            visible: (root.icon.indexOf("wifi") !== -1 || root.icon.indexOf("bluetooth") !== -1)

            // Motion Trail Ghost 3 (Furthest comet tail)
            Rectangle {
                id: trailGhost3
                anchors.centerIn: parent
                width: 2.0
                height: 28
                radius: 1.0
                color: Theme.accent
                opacity: 0
                rotation: -54
                transformOrigin: Item.Center
            }

            // Motion Trail Ghost 2 (Mid comet tail)
            Rectangle {
                id: trailGhost2
                anchors.centerIn: parent
                width: 2.2
                height: 30
                radius: 1.1
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.45)
                opacity: 0
                rotation: -36
                transformOrigin: Item.Center
            }

            // Motion Trail Ghost 1 (Immediate comet trail)
            Rectangle {
                id: trailGhost1
                anchors.centerIn: parent
                width: 2.4
                height: 32
                radius: 1.2
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.75)
                opacity: 0
                rotation: -18
                transformOrigin: Item.Center
            }

            // Main Comet Beam & Final Backslash \
            Rectangle {
                id: mainBeam
                anchors.centerIn: parent
                width: 2.5
                height: toggled ? 34 : 22
                radius: 1.25
                color: toggled
                    ? (Theme.isDark ? "#000000" : "#ffffff")
                    : (Theme.isDark ? "#ffffff" : "#000000")
                opacity: toggled ? 0 : 1
                rotation: toggled ? -315 : 45
                scale: toggled ? 0 : 1
                transformOrigin: Item.Center
            }
        }

        // TapHandler
        TapHandler {
            onTapped: root.clicked()
        }
    }

    // 360-Degree Orbital Sweep & Contracting Slash Animation (Toggled OFF)
    ParallelAnimation {
        id: turnOffAnim

        // 1. Main Beam: 360° full orbit (-315° to 45°) while gradually contracting in length (34px -> 22px)
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: mainBeam; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutQuad }
                NumberAnimation { target: mainBeam; property: "scale"; from: 0.5; to: 1.15; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { target: mainBeam; property: "rotation"; from: -315; to: 55; duration: 440; easing.type: Easing.OutCubic }
                NumberAnimation { target: mainBeam; property: "height"; from: 34; to: 22; duration: 440; easing.type: Easing.OutCubic }

                // Trail Ghost 1: orbital arc with -18° lag, contracting in length
                SequentialAnimation {
                    NumberAnimation { target: trailGhost1; property: "opacity"; from: 0; to: 0.75; duration: 140 }
                    ParallelAnimation {
                        NumberAnimation { target: trailGhost1; property: "rotation"; from: -333; to: 32; duration: 400; easing.type: Easing.OutCubic }
                        NumberAnimation { target: trailGhost1; property: "height"; from: 32; to: 20; duration: 400; easing.type: Easing.OutCubic }
                    }
                    NumberAnimation { target: trailGhost1; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutQuad }
                }

                // Trail Ghost 2: orbital arc with -36° lag, contracting in length
                SequentialAnimation {
                    NumberAnimation { target: trailGhost2; property: "opacity"; from: 0; to: 0.5; duration: 140 }
                    ParallelAnimation {
                        NumberAnimation { target: trailGhost2; property: "rotation"; from: -351; to: 14; duration: 380; easing.type: Easing.OutCubic }
                        NumberAnimation { target: trailGhost2; property: "height"; from: 30; to: 18; duration: 380; easing.type: Easing.OutCubic }
                    }
                    NumberAnimation { target: trailGhost2; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutQuad }
                }

                // Trail Ghost 3: orbital arc with -54° lag, contracting in length
                SequentialAnimation {
                    NumberAnimation { target: trailGhost3; property: "opacity"; from: 0; to: 0.3; duration: 140 }
                    ParallelAnimation {
                        NumberAnimation { target: trailGhost3; property: "rotation"; from: -369; to: -4; duration: 360; easing.type: Easing.OutCubic }
                        NumberAnimation { target: trailGhost3; property: "height"; from: 28; to: 16; duration: 360; easing.type: Easing.OutCubic }
                    }
                    NumberAnimation { target: trailGhost3; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutQuad }
                }
            }

            // Final lock at backslash 45°
            ParallelAnimation {
                NumberAnimation { target: mainBeam; property: "rotation"; to: 45; duration: 100; easing.type: Easing.OutCubic }
                NumberAnimation { target: mainBeam; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
            }
        }

        // 2. Icon Impact Shudder
        SequentialAnimation {
            PauseAnimation { duration: 280 }
            NumberAnimation { target: baseIcon; property: "scale"; from: 1.0; to: 0.86; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { target: baseIcon; property: "scale"; from: 0.86; to: 1.06; duration: 140; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: baseIcon; property: "scale"; to: 1.0; duration: 70; easing.type: Easing.OutCubic }
        }
    }

    // Connect Animation (Toggled ON - Expand, Orbit Out & Radiant Wave Pulse)
    ParallelAnimation {
        id: turnOnAnim

        // Beam elongates and spins away outward
        ParallelAnimation {
            NumberAnimation { target: mainBeam; property: "opacity"; from: 1; to: 0; duration: 180 }
            NumberAnimation { target: mainBeam; property: "height"; from: 22; to: 34; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: mainBeam; property: "rotation"; from: 45; to: 225; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: mainBeam; property: "scale"; from: 1.0; to: 0.2; duration: 220; easing.type: Easing.InBack }
        }

        // Icon Radiant Wave Pop
        SequentialAnimation {
            NumberAnimation { target: baseIcon; property: "scale"; from: 0.8; to: 1.3; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            NumberAnimation { target: baseIcon; property: "scale"; from: 1.3; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }

        // Trigger accent ripple ring
        ScriptAction {
            script: rippleAnim.restart()
        }
    }

    // Text labels
    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        ThemedText {
            text: root.label
            font.pixelSize: 13
            font.bold: true
            color: toggled ? Theme.accent : Theme.fg
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        ThemedText {
            text: root.sublabel
            font.pixelSize: 11
            color: toggled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.9) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.65)
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Optional Drilldown Chevron
    Rectangle {
        id: detailBtnRect
        visible: root.hasDetail
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: 12
        color: detailMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
        scale: detailMouse.pressed ? 0.88 : (detailMouse.containsMouse ? 1.12 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
        Behavior on color {
            ColorAnimation { duration: Constants.animFast }
        }

        SvgIcon {
            anchors.centerIn: parent
            icon: "chevron-right"
            iconSize: 14
            flat: true
            iconColor: toggled ? Theme.accent : (detailMouse.containsMouse ? Theme.fg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.6))
            Behavior on iconColor {
                ColorAnimation { duration: Constants.animFast }
            }
        }

        MouseArea {
            id: detailMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailClicked()
        }
    }
}

Behavior on color {
    ColorAnimation { duration: Constants.animFast }
}

Behavior on border.color {
    ColorAnimation { duration: Constants.animFast }
}
}

