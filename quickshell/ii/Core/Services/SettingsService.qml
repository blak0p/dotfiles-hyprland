import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: settingsService

    property bool settingsLoaded: false
    property string packageManagerMode: "install"
    property int clipboardMaxItems: 100
    property string githubUsername: ""
    property string githubToken: ""
    property string musicPlayer: "spotify"
    property string musicPlayerCommand: "spotify"
    property bool isSettingsLoading: settingsLoader.running
    property string quoteCategory: "All"
    property string fontFamily: "Geist"

    function saveSettings() {
        saveTimer.restart();
    }

    function load() {
        if (!settingsLoaded && !isSettingsLoading)
            settingsLoader.running = true;

    }

    Component.onCompleted: {
        load();
    }
    onClipboardMaxItemsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubUsernameChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubTokenChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerCommandChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onQuoteCategoryChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onFontFamilyChanged: {
        if (settingsLoaded)
            saveSettings();

    }

    Timer {
        id: saveTimer

        interval: 100
        repeat: false
        onTriggered: {
            let data = {
                "performanceInterval": SystemInfoService.performanceInterval,
                "powerProfile": SystemInfoService.powerProfile,
                "packageManagerChecksEnabled": UpdateService.packageManagerChecksEnabled,
                "packageManagerCheckInterval": UpdateService.packageManagerCheckInterval,
                "clipboardMaxItems": settingsService.clipboardMaxItems,
                "animationSpeedFactor": HyprlandService.animationSpeedFactor,
                "githubUsername": settingsService.githubUsername,
                "githubToken": settingsService.githubToken,
                "musicPlayer": settingsService.musicPlayer,
                "musicPlayerCommand": settingsService.musicPlayerCommand,
                "nightLightActive": HyprlandService.nightLightActive,
                "caffeineActive": HyprlandService.caffeineActive,
                "gameModeActive": HyprlandService.gameModeActive,
                "keyboardLayout": HyprlandService.keyboardLayout,
                "wpAutoShuffle": HyprlandService.wpAutoShuffle,
                "wpShuffleInterval": HyprlandService.wpShuffleInterval,
                "wpEnableTransitions": HyprlandService.wpEnableTransitions,
                "wpTransitionType": HyprlandService.wpTransitionType,
                "wpTransitionPos": HyprlandService.wpTransitionPos,
                "wpTransitionStep": HyprlandService.wpTransitionStep,
                "wpTransitionFps": HyprlandService.wpTransitionFps,
                "wpTransitionAngle": HyprlandService.wpTransitionAngle,
                "micMuted": AudioService.micMuted,
                "micVolume": AudioService.micVolume,
                "quoteCategory": settingsService.quoteCategory,
                "fontFamily": settingsService.fontFamily
            };
            settingsSaver.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell && cat << 'EOF' > ~/.cache/quickshell/settings_prefs.json\n" + JSON.stringify(data) + "\nEOF"];
            settingsSaver.running = true;
        }
    }

    Process {
        id: settingsLoader

        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/settings_prefs.json"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                SystemInfoService.applyProfile("balanced");
                settingsService.saveSettings();
                settingsService.settingsLoaded = true;
                HyprlandService.triggerStartupTimer();
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    try {
                        let prefs = JSON.parse(data.trim());
                        if (prefs.powerProfile !== undefined) {
                            SystemInfoService.powerProfile = prefs.powerProfile;
                            SystemInfoService.applyProfile(prefs.powerProfile);
                        } else {
                            SystemInfoService.applyProfile("balanced");
                        }
                        if (prefs.performanceInterval !== undefined)
                            SystemInfoService.performanceInterval = prefs.performanceInterval;

                        if (prefs.packageManagerChecksEnabled !== undefined)
                            UpdateService.packageManagerChecksEnabled = prefs.packageManagerChecksEnabled;

                        if (prefs.packageManagerCheckInterval !== undefined)
                            UpdateService.packageManagerCheckInterval = prefs.packageManagerCheckInterval;

                        if (prefs.clipboardMaxItems !== undefined)
                            settingsService.clipboardMaxItems = prefs.clipboardMaxItems;

                        if (prefs.animationSpeedFactor !== undefined)
                            HyprlandService.animationSpeedFactor = prefs.animationSpeedFactor;

                        if (prefs.githubUsername !== undefined)
                            settingsService.githubUsername = prefs.githubUsername;

                        if (prefs.githubToken !== undefined)
                            settingsService.githubToken = prefs.githubToken;

                        if (prefs.musicPlayer !== undefined)
                            settingsService.musicPlayer = prefs.musicPlayer;

                        if (prefs.musicPlayerCommand !== undefined)
                            settingsService.musicPlayerCommand = prefs.musicPlayerCommand;

                        if (prefs.nightLightActive !== undefined)
                            HyprlandService.nightLightActive = prefs.nightLightActive;

                        if (prefs.caffeineActive !== undefined)
                            HyprlandService.caffeineActive = prefs.caffeineActive;

                        if (prefs.gameModeActive !== undefined)
                            HyprlandService.gameModeActive = prefs.gameModeActive;

                        if (prefs.keyboardLayout !== undefined)
                            HyprlandService.keyboardLayout = prefs.keyboardLayout;

                        if (prefs.wpAutoShuffle !== undefined)
                            HyprlandService.wpAutoShuffle = prefs.wpAutoShuffle;

                        if (prefs.wpShuffleInterval !== undefined)
                            HyprlandService.wpShuffleInterval = prefs.wpShuffleInterval;

                        if (prefs.wpEnableTransitions !== undefined)
                            HyprlandService.wpEnableTransitions = prefs.wpEnableTransitions;

                        if (prefs.wpTransitionType !== undefined)
                            HyprlandService.wpTransitionType = prefs.wpTransitionType;

                        if (prefs.wpTransitionPos !== undefined)
                            HyprlandService.wpTransitionPos = prefs.wpTransitionPos;

                        if (prefs.wpTransitionStep !== undefined)
                            HyprlandService.wpTransitionStep = prefs.wpTransitionStep;

                        if (prefs.wpTransitionFps !== undefined)
                            HyprlandService.wpTransitionFps = prefs.wpTransitionFps;

                        if (prefs.wpTransitionAngle !== undefined)
                            HyprlandService.wpTransitionAngle = prefs.wpTransitionAngle;

                        HyprlandService.startupAnimations();
                        if (prefs.micVolume !== undefined) {
                            AudioService.micVolume = AudioService.hasPhysicalMic ? prefs.micVolume : 0;
                            if (AudioService.hasPhysicalMic)
                                AudioService.setMicVolume(prefs.micVolume);

                        }
                        if (prefs.micMuted !== undefined) {
                            AudioService.micMuted = AudioService.hasPhysicalMic ? prefs.micMuted : true;
                            if (AudioService.hasPhysicalMic)
                                AudioService.setMicMuted(prefs.micMuted);

                        }
                        if (prefs.quoteCategory !== undefined)
                            settingsService.quoteCategory = prefs.quoteCategory;

                        if (prefs.fontFamily !== undefined)
                            settingsService.fontFamily = prefs.fontFamily;

                    } catch (e) {
                        console.error("Error loading settings: " + e);
                        SystemInfoService.applyProfile("balanced");
                    }
                }
                settingsService.settingsLoaded = true;
                HyprlandService.triggerStartupTimer();
            }
        }

    }

    Process {
        id: settingsSaver
    }

}
