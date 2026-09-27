pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 1.50 // Capped to 150% (1.5)
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        if (Audio.sink && Audio.sink.audio) {
            Audio.sink.audio.muted = !Audio.sink.audio.muted;
        }
    }

    function toggleMicMute() {
        if (Audio.source && Audio.source.audio) {
            Audio.source.audio.muted = !Audio.source.audio.muted;
        }
    }

    function setVolume(volume) {
        if (Audio.sink && Audio.sink.audio) {
            const clamped = Math.max(0.0, Math.min(root.hardMaxValue, volume));
            Audio.sink.audio.volume = clamped;
            if (Audio.sink.audio.muted && clamped > 0) {
                Audio.sink.audio.muted = false;
            }
        }
    }

    function setMicVolume(volume) {
        if (Audio.source && Audio.source.audio) {
            const clamped = Math.max(0.0, Math.min(root.hardMaxValue, volume));
            Audio.source.audio.volume = clamped;
            if (Audio.source.audio.muted && clamped > 0) {
                Audio.source.audio.muted = false;
            }
        }
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        if (Audio.sink && Audio.sink.audio) {
            Audio.sink.audio.volume = Math.min(root.hardMaxValue, Audio.sink.audio.volume + step);
        }
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        if (Audio.sink && Audio.sink.audio) {
            Audio.sink.audio.volume = Math.max(0.0, Audio.sink.audio.volume - step);
        }
    }

    function volumeUp() {
        incrementVolume();
    }

    function volumeDown() {
        decrementVolume();
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    onSinkChanged: {
        if (sink && sink.audio && sink.audio.volume > root.hardMaxValue) {
            sink.audio.volume = root.hardMaxValue;
        }
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!sink || !sink.audio) return;
            if (sink.audio.volume > root.hardMaxValue) {
                sink.audio.volume = root.hardMaxValue;
            }
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Math.min(root.hardMaxValue, Config.options.audio.protection.maxAllowed / 100);

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (ffplay will just fail silently if file doesn't exist)
        command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            oggPath
        ];
        Quickshell.execDetached(command);
    }
}
