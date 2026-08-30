import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: hyprlandService

    property bool enableAnimations: true
    property real animationSpeedFactor: 1
    property bool nightLightActive: false
    property bool caffeineActive: false
    property bool gameModeActive: false
    property string keyboardLayout: "us"
    property bool wpAutoShuffle: false
    property int wpShuffleInterval: 10
    property bool wpEnableTransitions: true
    property string wpTransitionType: "grow"
    property string wpTransitionPos: "center"
    property int wpTransitionStep: 120
    property int wpTransitionFps: 60
    property int wpTransitionAngle: 30
    property bool hyprBlur: true
    property int hyprRounding: 32
    property int hyprActiveOpacity: 100
    property int hyprInactiveOpacity: 100
    property int hyprBlurSize: 6
    property int hyprBlurPasses: 4
    property int hyprGapsIn: 4
    property int hyprGapsOut: 8
    property int hyprBorderSize: 2
    property bool hyprShadow: false
    property int hyprShadowRange: 4
    property int hyprShadowRenderPower: 3

    function applyNightLight(state) {
        if (state) {
            nightLightProc.command = ["hyprsunset", "-t", "4500"];
            nightLightProc.running = false;
            nightLightProc.running = true;
        } else {
            nightLightProc.running = false;
            pkillSunsetProc.running = false;
            pkillSunsetProc.running = true;
        }
    }

    function applyCaffeine(state) {
        caffeineProc.running = false;
        if (state)
            caffeineProc.running = true;

    }

    function applyHyprlandSettings() {
        applySettingsTimer.restart();
    }

    function setPowerSaverMode(enabled) {
        animationsProc.running = false;
        if (enabled) {
            let jsonArgs = {
                "animations": {
                    "enabled": false
                },
                "decoration": {
                    "rounding": 0,
                    "blur": {
                        "enabled": false
                    },
                    "shadow": {
                        "enabled": false
                    }
                }
            };
            animationsProc.command = ["sh", "-c", "python3 ~/.config/quickshell/Scripts/update_hypr_prefs.py '" + JSON.stringify(jsonArgs) + "'"];
            animationsProc.running = true;
        } else {
            applyHyprlandSettings();
        }
    }

    function startupAnimations() {
        applyHyprlandSettings();
    }

    function triggerStartupTimer() {
        startupApplyTimer.start();
    }

    onEnableAnimationsChanged: {
        if (SettingsService.settingsLoaded) {
            animationsProc.running = false;
            animationsProc.command = ["hyprctl", "eval", "hl.config({ animations = { enabled = " + (enableAnimations ? "true" : "false") + " } })"];
            animationsProc.running = true;
            let jsonArgs = {
                "animations": {
                    "enabled": enableAnimations
                }
            };
            patchUserPrefsProc.command = ["sh", "-c", "python3 ~/.config/quickshell/Scripts/update_hypr_prefs.py '" + JSON.stringify(jsonArgs) + "'"];
            patchUserPrefsProc.running = false;
            patchUserPrefsProc.running = true;
        }
    }
    onNightLightActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyNightLight(nightLightActive);
    }
    onCaffeineActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyCaffeine(caffeineActive);
    }
    onGameModeActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        if (gameModeActive) {
            hyprlandService.enableAnimations = false;
            hyprlandService.hyprBlur = false;
            hyprlandService.caffeineActive = true;
        } else {
            hyprlandService.enableAnimations = true;
            hyprlandService.hyprBlur = true;
            hyprlandService.caffeineActive = false;
        }
    }
    onAnimationSpeedFactorChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpAutoShuffleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpShuffleIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpEnableTransitionsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionTypeChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionPosChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionStepChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionFpsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionAngleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onKeyboardLayoutChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            changeLayoutProc.command = ["hyprctl", "eval", "hl.config({ input = { kb_layout = '" + keyboardLayout + "' } })"];
            changeLayoutProc.running = false;
            changeLayoutProc.running = true;
        }
    }
    onHyprBlurChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprRoundingChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprActiveOpacityChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprInactiveOpacityChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprBlurSizeChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprBlurPassesChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprGapsInChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprGapsOutChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprBorderSizeChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprShadowChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprShadowRangeChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    onHyprShadowRenderPowerChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            applyHyprlandSettings();
        }
    }
    Component.onCompleted: {
        readHyprPrefsProc.running = true;
    }

    Timer {
        id: applySettingsTimer

        interval: 50
        repeat: false
        onTriggered: {
            let ao = (hyprActiveOpacity / 100).toFixed(2);
            let io = (hyprInactiveOpacity / 100).toFixed(2);
            let jsonArgs = {
                "animations": {
                    "enabled": enableAnimations
                },
                "general": {
                    "gaps_in": hyprGapsIn,
                    "gaps_out": hyprGapsOut,
                    "border_size": hyprBorderSize
                },
                "decoration": {
                    "rounding": hyprRounding,
                    "active_opacity": parseFloat(ao),
                    "inactive_opacity": parseFloat(io),
                    "blur": {
                        "enabled": hyprBlur,
                        "size": hyprBlurSize,
                        "passes": hyprBlurPasses
                    },
                    "shadow": {
                        "enabled": hyprShadow,
                        "range": hyprShadowRange,
                        "render_power": hyprShadowRenderPower
                    }
                }
            };
            patchUserPrefsProc.command = ["sh", "-c", "python3 ~/.config/quickshell/Scripts/update_hypr_prefs.py '" + JSON.stringify(jsonArgs) + "'"];
            patchUserPrefsProc.running = false;
            patchUserPrefsProc.running = true;
        }
    }

    Timer {
        id: startupApplyTimer

        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            startupAnimations();
            changeLayoutProc.command = ["hyprctl", "eval", "hl.config({ input = { kb_layout = '" + hyprlandService.keyboardLayout + "' } })"];
            changeLayoutProc.running = false;
            changeLayoutProc.running = true;
        }
    }

    Process {
        id: animationsProc
    }

    Process {
        id: changeLayoutProc
    }

    Process {
        id: nightLightProc
    }

    Process {
        id: pkillSunsetProc

        command: ["pkill", "hyprsunset"]
    }

    Process {
        id: caffeineProc

        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Keep screen active", "--mode=block", "sleep", "infinity"]
    }

    Process {
        id: setHyprlandOptionProc
    }

    Process {
        id: patchUserPrefsProc
    }

    Connections {
        function onRawEvent(event) {
            if (event.name === "activelayout")
                activeLayoutProc.running = true;

        }

        target: Hyprland
    }

    Process {
        id: activeLayoutProc

        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let raw = data.trim();
                let code = "us";
                if (raw.includes("Spanish"))
                    code = "latam";
                else if (raw.includes("English"))
                    code = "us";
                else
                    code = raw;
                if (hyprlandService.keyboardLayout !== code)
                    hyprlandService.keyboardLayout = code;

            }
        }

    }

    Process {
        id: readHyprPrefsProc

        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/Scripts/read_hypr_prefs.py"]

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    try {
                        let prefs = JSON.parse(data.trim());
                        if (prefs["decoration:blur:enabled"] !== undefined)
                            hyprBlur = prefs["decoration:blur:enabled"];

                        if (prefs["decoration:rounding"] !== undefined)
                            hyprRounding = prefs["decoration:rounding"];

                        if (prefs["decoration:active_opacity"] !== undefined)
                            hyprActiveOpacity = Math.round(prefs["decoration:active_opacity"] * 100);

                        if (prefs["decoration:inactive_opacity"] !== undefined)
                            hyprInactiveOpacity = Math.round(prefs["decoration:inactive_opacity"] * 100);

                        if (prefs["decoration:blur:size"] !== undefined)
                            hyprBlurSize = prefs["decoration:blur:size"];

                        if (prefs["decoration:blur:passes"] !== undefined)
                            hyprBlurPasses = prefs["decoration:blur:passes"];

                        if (prefs["general:gaps_in"] !== undefined)
                            hyprGapsIn = prefs["general:gaps_in"];

                        if (prefs["general:gaps_out"] !== undefined)
                            hyprGapsOut = prefs["general:gaps_out"];

                        if (prefs["general:border_size"] !== undefined)
                            hyprBorderSize = prefs["general:border_size"];

                        if (prefs["decoration:shadow:enabled"] !== undefined)
                            hyprShadow = prefs["decoration:shadow:enabled"];

                        if (prefs["decoration:shadow:range"] !== undefined)
                            hyprShadowRange = prefs["decoration:shadow:range"];

                        if (prefs["decoration:shadow:render_power"] !== undefined)
                            hyprShadowRenderPower = prefs["decoration:shadow:render_power"];

                        if (prefs["animations:enabled"] !== undefined)
                            enableAnimations = prefs["animations:enabled"];

                    } catch (e) {
                        console.error("Error parsing hypr prefs: " + e);
                    }
                }
            }
        }

    }

}
