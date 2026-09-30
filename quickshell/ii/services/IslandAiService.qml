pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.services

Singleton {
    id: root

    property bool running: false
    property string prompt: ""
    property string status: ""
    property string activeTool: ""
    property string toolDetail: ""
    property string response: ""
    property string error: ""
    property var toolHistory: []
    property bool speakVoice: false
    readonly property string script: Quickshell.shellPath("scripts/island_ai.py")

    function ask(userQuery, reset = false) {
        if (running) {
            cancel();
        }
        prompt = userQuery;
        response = "";
        error = "";
        status = Translation.tr("Thinking...");
        activeTool = "";
        toolDetail = "";
        toolHistory = [];
        
        const win = Hyprland.focusedToplevel ? (Hyprland.focusedToplevel.title || Hyprland.focusedToplevel.class || "") : "";
        let cmd = ["python3", root.script, "--prompt", userQuery];
        if (win) {
            cmd.push("--context", "Active window: " + win);
        }
        if (reset) {
            cmd.push("--reset");
        }
        aiProcess.command = cmd;
        aiProcess.running = true;
        running = true;
    }

    function cancel() {
        aiProcess.running = false;
        running = false;
        status = "";
        speakVoice = false;
    }

    function warmup() {
        if (!running) {
            aiProcess.command = ["python3", root.script, "--warmup"];
            aiProcess.running = true;
            running = true;
        }
    }

    function clearSession() {
        cancel();
        prompt = "";
        response = "";
        error = "";
        toolHistory = [];
        Quickshell.execDetached(["python3", root.script, "--clear"]);
    }

    Process {
        id: aiProcess
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line || line.trim().length === 0) return;
                try {
                    const ev = JSON.parse(line.trim());
                    if (ev.type === "already_loaded") {
                        root.running = false;
                        root.status = "";
                    } else if (ev.type === "warmed_up") {
                        root.running = false;
                        root.status = "";
                    } else if (ev.type === "warmup_error") {
                        root.running = false;
                        root.status = "";
                    } else if (ev.type === "status") {
                        root.status = Translation.tr(ev.message);
                    } else if (ev.type === "tool_start") {
                        root.activeTool = ev.name;
                        root.toolDetail = ev.args ? (ev.args.query || ev.args.path || "") : "";
                        if (ev.name === "web_search") {
                            root.status = Translation.tr("Searching web: \"%1\"").arg(root.toolDetail);
                        } else if (ev.name === "read_file") {
                            root.status = Translation.tr("Reading: %1").arg(root.toolDetail);
                        } else if (ev.name === "list_dir") {
                            root.status = Translation.tr("Listing: %1").arg(root.toolDetail);
                        } else if (ev.name === "list_desktop_apps") {
                            root.status = Translation.tr("Listing applications: %1").arg(root.toolDetail || "all");
                        } else {
                            root.status = Translation.tr("Running: %1").arg(ev.name);
                        }
                        let h = root.toolHistory ? [...root.toolHistory] : [];
                        h.push({
                            id: h.length,
                            name: ev.name,
                            detail: root.toolDetail,
                            status: "running",
                            preview: ""
                        });
                        root.toolHistory = h;
                    } else if (ev.type === "tool_done") {
                        let h = root.toolHistory ? [...root.toolHistory] : [];
                        if (h.length > 0) {
                            h[h.length - 1].status = "done";
                            h[h.length - 1].preview = ev.preview || "";
                        }
                        root.toolHistory = h;
                        root.activeTool = "";
                        root.toolDetail = "";
                        root.status = Translation.tr("Generating response...");
                    } else if (ev.type === "token") {
                        root.status = "";
                        root.response += ev.content;
                    } else if (ev.type === "done") {
                        root.running = false;
                        root.status = "";
                        root.activeTool = "";
                        if (root.speakVoice && root.response && root.response.trim().length > 0) {
                            let cleanText = root.response.replace(/[*_#`\[\]]/g, "").replace(/\n+/g, " ").trim();
                            Quickshell.execDetached(["python3", Quickshell.shellPath("scripts/jarvis_tts.py"), cleanText]);
                            root.speakVoice = false;
                        } else if (root.speakVoice) {
                            JarvisService.setIdle();
                            root.speakVoice = false;
                        }
                    } else if (ev.type === "error") {
                        root.running = false;
                        root.error = ev.message;
                        root.status = "";
                        if (root.speakVoice) {
                            JarvisService.setIdle();
                            root.speakVoice = false;
                        }
                    }
                } catch (e) {
                    console.warn("[IslandAiService] parse error:", line, e);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.running = false;
            if (exitCode !== 0 && root.response.length === 0 && root.error.length === 0) {
                root.error = Translation.tr("Error running local agent (%1)").arg(exitCode);
            }
        }
    }
}
