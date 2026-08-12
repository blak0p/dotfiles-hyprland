import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int effectiveActiveWorkspaceId: monitor?.activeWorkspace?.id ?? 1

    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / root.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (effectiveActiveWorkspaceId - 1) % root.workspacesShown

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            showNumbersTimer.stop()
        }
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: root.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * root.workspacesShown + i + 1);
        })
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }
    onWorkspaceGroupChanged: {
        updateWorkspaceOccupied();
    }

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (workspacesGrid.implicitWidth + root.widgetPadding * 2)
    implicitHeight: root.vertical ? (workspacesGrid.implicitHeight + root.widgetPadding * 2) : Appearance.sizes.barHeight

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`hl.dsp.workspace.toggle_special("special")`);
            }
        }
    }

    // Rename the active workspace via fuzzel prompt
    function renameActiveWorkspace(): void {
        var currentId = root.effectiveActiveWorkspaceId;
        var idx = currentId - 1;
        var currentLabel = (Persistent.ready && Persistent.states?.workspaceLabels && idx >= 0 && idx < Persistent.states.workspaceLabels.length) ? (Persistent.states.workspaceLabels[idx] || "") : "";
        renameProcess.command = ["bash", "-c", `
            LABEL="${currentLabel.replace(/"/g, '\\"')}"
            PROMPT="Nombre workspace ${currentId}: "
            if command -v rofi >/dev/null 2>&1; then
                printf '%s' "$LABEL" | rofi -dmenu -p "$PROMPT"
            elif command -v fuzzel >/dev/null 2>&1; then
                printf '%s' "$LABEL" | fuzzel --dmenu --prompt "$PROMPT"
            fi
        `];
        renameProcess.running = true;
    }

    GlobalShortcut {
        name: "renameWorkspace"
        description: "Rename active workspace"

        onPressed: {
            root.renameActiveWorkspace();
        }
    }

    Process {
        id: renameProcess
        running: false
        stdout: StdioCollector {
            id: renameCollector
            onStreamFinished: {
                var newLabel = renameCollector.text.replace(/\n/g, "").trim();
                var idx = root.effectiveActiveWorkspaceId - 1;
                var labels = Array.from(Persistent.states.workspaceLabels || []);
                while (labels.length < 10) labels.push("");
                if (idx >= 0 && idx < 10) {
                    labels[idx] = newLabel;
                    Persistent.states.workspaceLabels = labels;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("renameWorkspace fuzzel exited with code:", exitCode);
            }
        }
    }

    Grid {
        id: workspacesGrid
        anchors.centerIn: parent

        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1
        columnSpacing: root.vertical ? 12 : 4
        rowSpacing: root.vertical ? 4 : 12

        Repeater {
            model: root.workspacesShown

            Button {
                id: button
                property int workspaceValue: workspaceGroup * root.workspacesShown + index + 1
                readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(button.workspaceValue)
                readonly property string manualLabel: (Persistent.ready && Persistent.states?.workspaceLabels && (button.workspaceValue - 1) < Persistent.states.workspaceLabels.length) ? (Persistent.states.workspaceLabels[button.workspaceValue - 1] || "") : ""
                readonly property string autoLabel: {
                    if (!biggestWindow || !biggestWindow.title) return "";
                    var titleStr = biggestWindow.title.trim();
                    if (titleStr.length > 20) {
                        return titleStr.substring(0, 18) + "…";
                    }
                    return titleStr;
                }
                property string label: manualLabel !== "" ? manualLabel : autoLabel
                readonly property real pillWidth: labelText.implicitWidth + root.workspaceButtonWidth
                readonly property bool isActive: root.effectiveActiveWorkspaceId == button.workspaceValue
                readonly property bool isOccupied: workspaceOccupied[index]
                readonly property bool showingNumber: root.showNumbers
                    || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !button.biggestWindow || root.showNumbers))
                    || (root.showNumbers && !Config.options?.bar.workspaces.showAppIcons))

                implicitHeight: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
                implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (button.label ? button.pillWidth : root.workspaceButtonWidth)
                onPressed: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceValue}})`)
                width: vertical ? undefined : button.implicitWidth
                height: vertical ? root.workspaceButtonWidth : undefined

                background: Item {
                    id: workspaceButtonBackground
                    anchors.fill: parent
                    property var biggestWindow: button.biggestWindow
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    Rectangle { // Base pill / active & occupied highlight
                        id: wsBasePill
                        anchors.centerIn: parent
                        width: button.label ? button.pillWidth - 4
                            : button.isActive ? root.workspaceButtonWidth * 0.86 : root.workspaceButtonWidth * 0.62
                        height: button.label ? root.workspaceButtonWidth - 6 : width
                        radius: height / 2
                        color: button.isActive
                            ? (button.label ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colPrimary)
                            : (button.label
                                ? ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, button.isOccupied ? 0.45 : 0.65)
                                : (button.isOccupied
                                    ? ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.45)
                                    : "transparent"))

                        Behavior on radius {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                        Behavior on color {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                    }

                    // Named workspace label
                    StyledText {
                        id: labelText
                        visible: !!button.label
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: Appearance.font.pixelSize.small - ((button.label.length - 1) * (button.label.length <= 4) * 2)
                            bold: true
                        }
                        text: button.label
                        elide: Text.ElideRight
                        color: button.isActive
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : (button.label ? Appearance.m3colors.m3onSecondaryContainer : (button.isOccupied ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1Inactive))
                    }

                    // Workspace number text
                    StyledText {
                        opacity: !button.label && (button.showingNumber || root.showNumbers) ? 1 : 0
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                            family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                        }
                        text: Config.options?.bar.workspaces.numberMap[button.workspaceValue - 1] || button.workspaceValue
                        elide: Text.ElideRight
                        color: button.isActive
                            ? Appearance.m3colors.m3onPrimary
                            : (button.isOccupied ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    Rectangle { // Dot instead of ws number
                        id: wsDot
                        opacity: button.label ? 0 :
                            (Config.options?.bar.workspaces.alwaysShowNumbers
                            || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                            ) ? 0 : 1
                        visible: opacity > 0
                        anchors.centerIn: parent
                        width: root.workspaceButtonWidth * (button.isActive ? 0.18 : 0.13)
                        height: width
                        radius: width / 2
                        color: button.isActive
                            ? Appearance.colors.colPrimary
                            : (button.isOccupied ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1Inactive)

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on width {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    Item { // Main app icon
                        anchors.centerIn: parent
                        width: root.workspaceButtonWidth
                        height: root.workspaceButtonWidth
                        opacity: button.label ? 0 :
                            !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (workspaceButtonBackground.biggestWindow && !root.showNumbers) ?
                            1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0
                            visible: opacity > 0

                        IconImage {
                            id: mainAppIcon
                            anchors.centerIn: parent
                            source: workspaceButtonBackground.mainAppIconSource
                            implicitSize: workspaceIconSize

                            Behavior on anchors.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on implicitSize {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }

                        Loader {
                            active: Config.options.bar.workspaces.monochromeIcons
                            anchors.fill: mainAppIcon
                            sourceComponent: Item {
                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false // There's already color overlay
                                    anchors.fill: parent
                                    source: mainAppIcon
                                    desaturation: 0.8
                                }
                                ColorOverlay {
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(wsDot.color, 0.9)
                                }
                            }
                        }
                    }
                }

            }

        }

    }

}