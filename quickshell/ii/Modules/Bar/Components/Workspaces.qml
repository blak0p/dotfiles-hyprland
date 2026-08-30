import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs
import qs.services
import qs.Core
import qs.Core.Services
import qs.modules.common

BarButton {
    id: root

    property bool transparentBg: false
    implicitWidth: transparentBg ? hLayout.implicitWidth + 8 : (hLayout.implicitWidth + 24)
    implicitHeight: 32
    color: transparentBg ? "transparent" : Theme.bgSecondary
    radius: height / 2
    border.width: transparentBg ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.08)

    readonly property int workspacesShown: Config.options?.bar.workspaces.shown ?? 10
    readonly property int activeWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - 1) / workspacesShown)

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch('hl.dsp.focus({workspace = "r+1"})');
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch('hl.dsp.focus({workspace = "r-1"})');
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    RowLayout {
        id: hLayout

        anchors.centerIn: parent
        spacing: Constants.sizeSm

        Repeater {
            model: root.workspacesShown

            Rectangle {
                id: wsItemH

                readonly property int wsId: root.workspaceGroup * root.workspacesShown + index + 1
                readonly property var workspace: Hyprland.workspaces.values.find((ws) => {
                    return ws.id === wsId;
                })
                readonly property bool isActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === wsId : false
                readonly property bool hasWindows: workspace !== undefined && (workspace.windows > 0 || workspace.id === wsId)
                readonly property string manualLabel: (Persistent.ready && Persistent.states?.workspaceLabels && (wsId - 1) < Persistent.states.workspaceLabels.length) ? (Persistent.states.workspaceLabels[wsId - 1] || "") : ""
                readonly property var mainWin: HyprlandData.biggestWindowForWorkspace(wsId)
                readonly property string appClass: mainWin?.class || ""
                readonly property string appIconName: appClass !== "" ? AppSearch.guessIcon(appClass) : ""
                readonly property bool hasAutoIcon: manualLabel === "" && appIconName !== ""
                readonly property string label: manualLabel

                implicitWidth: manualLabel !== ""
                    ? labelText.implicitWidth + (isActive ? 20 : 14)
                    : (hasAutoIcon
                        ? (isActive ? 26 : 20)
                        : (isActive ? 24 : (hasWindows ? 10 : 8)))
                implicitHeight: manualLabel !== ""
                    ? (isActive ? 20 : 16)
                    : (hasAutoIcon
                        ? (isActive ? 20 : 16)
                        : (isActive ? 12 : (hasWindows ? 10 : 8)))
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                radius: implicitHeight / 2

                color: (manualLabel !== "" || hasAutoIcon)
                    ? (mouseAreaH.containsMouse ? Theme.accent : Theme.fg)
                    : (mouseAreaH.containsMouse ? Theme.accent : (isActive ? Theme.fg : (hasWindows ? Theme.fg : Theme.muted)))
                scale: mouseAreaH.pressed ? 0.9 : (mouseAreaH.containsMouse ? 1.1 : 1)

                Text {
                    id: labelText
                    visible: manualLabel !== ""
                    anchors.centerIn: parent
                    text: manualLabel
                    font.pixelSize: isActive ? 11 : 10
                    font.bold: true
                    color: Theme.bg
                }

                IconImage {
                    id: appIcon
                    visible: manualLabel === "" && hasAutoIcon
                    anchors.centerIn: parent
                    source: hasAutoIcon ? Quickshell.iconPath(appIconName, "image-missing") : ""
                    implicitWidth: isActive ? 14 : 12
                    implicitHeight: isActive ? 14 : 12
                }

                MouseArea {
                    id: mouseAreaH

                    anchors.fill: parent
                    anchors.margins: -12
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({workspace=' + wsId + '})')
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Constants.animSlow
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Constants.animSlow
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
