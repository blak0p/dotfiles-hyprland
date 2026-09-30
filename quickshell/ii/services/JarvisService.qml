pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    // Jarvis states: "idle" | "listening" | "transcribing" | "thinking" | "speaking"
    property string status: "idle"
    property bool dictationActive: false

    readonly property bool isListening: status === "listening"
    readonly property bool isTranscribing: status === "transcribing"
    readonly property bool isThinking: status === "thinking"
    readonly property bool isSpeaking: status === "speaking"
    readonly property bool isBusy: status !== "idle"

    function setListening(): void {
        status = "listening";
    }

    function setTranscribing(): void {
        status = "transcribing";
    }

    function setThinking(): void {
        status = "thinking";
    }

    function setSpeaking(): void {
        status = "speaking";
    }

    function setDictating(active: var): void {
        if (typeof active === "string") {
            dictationActive = (active === "true" || active === "1");
        } else {
            dictationActive = Boolean(active);
        }
    }

    function setIdle(): void {
        status = "idle";
    }
}
