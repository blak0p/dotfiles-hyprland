import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    spacing: 4

    // ---- Volume ----
    ThemedSlider {
        Layout.fillWidth: true
        icon: (Audio.sink && Audio.sink.audio && Audio.sink.audio.muted) || ((Audio.sink && Audio.sink.audio ? Audio.sink.audio.volume : 0) === 0) ? "volume-off" : "volume"
        label: Translation.tr("Volume")
        from: 0
        to: Audio.hardMaxValue
        stepSize: 0.02
        value: (Audio.sink && Audio.sink.audio) ? Audio.sink.audio.volume : 0
        suffix: "%"
        decimals: 0
        onIconClicked: Audio.toggleMute()
        onMoved: (val) => {
            if (Audio.sink && Audio.sink.audio) {
                Audio.sink.audio.volume = Math.min(Audio.hardMaxValue, Math.max(0.0, val));
                if (Audio.sink.audio.muted && val > 0)
                    Audio.sink.audio.muted = false;
            }
        }
    }

    // ---- Mic ----
    ThemedSlider {
        Layout.fillWidth: true
        icon: Audio.source?.audio?.muted ? "microphone-off" : "microphone"
        label: Translation.tr("Microphone")
        from: 0
        to: Audio.hardMaxValue
        stepSize: 0.02
        value: Audio.source?.audio?.volume ?? 0
        suffix: "%"
        decimals: 0
        onIconClicked: Audio.toggleMicMute()
        onMoved: (val) => {
            if (Audio.source && Audio.source.audio) {
                Audio.source.audio.volume = Math.min(Audio.hardMaxValue, Math.max(0.0, val));
                if (Audio.source.audio.muted && val > 0)
                    Audio.source.audio.muted = false;
            }
        }
    }

    // ---- Brightness ----
    ThemedSlider {
        Layout.fillWidth: true
        icon: "sun"
        label: Translation.tr("Brightness")
        from: 0
        to: 1
        stepSize: 0.01
        value: bMonitor && bMonitor.ready ? bMonitor.multipliedBrightness : 0
        suffix: "%"
        decimals: 0
        onMoved: (val) => {
            if (bMonitor && bMonitor.ready)
                bMonitor.setBrightness(val);
        }
    }

    readonly property var bMonitor: Brightness.monitors.length > 0 ? Brightness.monitors[0] : null
}
