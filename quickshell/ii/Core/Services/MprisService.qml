import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: root

    property var managedPlayers: []
    property var activePlayer: null
    readonly property bool isPlaying: root.activePlayer !== null && (root.activePlayer.playbackState === 1 || root.activePlayer.playbackState === Mpris.Playing || String(root.activePlayer.playbackState).toLowerCase().includes("playing"))
    readonly property string activePlayerName: {
        if (!root.activePlayer)
            return "Offline";

        let id = (root.activePlayer.identity || "").toLowerCase();
        if (id.includes("spotify"))
            return "Spotify";

        if (id.includes("youtube"))
            return "YouTube Music";

        if (id.includes("kew"))
            return "Kew";

        return root.activePlayer.identity || "";
    }

    function isPlayerRunning(name) {
        for (let i = 0; i < root.managedPlayers.length; i++) {
            let p = root.managedPlayers[i];
            if (!p)
                continue;

            let id = (p.identity || "").toLowerCase();
            if (id.includes(name))
                return true;

        }
        return false;
    }

    function updatePlayer() {
        let players = managedPlayers;
        let selected = null, playing = null;
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (!p)
                continue;

            let id = (p.identity || "").toLowerCase();
            if (!id.includes("brave") && (id.includes("spotify") || id.includes("youtube") || id.includes("kew"))) {
                let active = p.playbackState === 1 || p.playbackState === Mpris.Playing || String(p.playbackState).toLowerCase().includes("playing");
                if (active) {
                    playing = p;
                    break;
                }
                if (!selected)
                    selected = p;

            }
        }
        let n = playing || selected || null;
        if (root.activePlayer !== n)
            root.activePlayer = n;

    }

    function registerPlayer(p) {
        let list = managedPlayers;
        if (list.indexOf(p) === -1) {
            list.push(p);
            managedPlayers = list;
            updatePlayer();
        }
    }

    function unregisterPlayer(p) {
        let list = managedPlayers, idx = list.indexOf(p);
        if (idx !== -1) {
            list.splice(idx, 1);
            managedPlayers = list;
            updatePlayer();
        }
    }

    function formatTime(s) {
        if (isNaN(s) || s < 0)
            return "0:00";

        let m = Math.floor(s / 60), sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function killConfiguredPlayer() {
        let cmd = SettingsService.musicPlayerCommand;
        if (!cmd)
            return ;

        let name = cmd.includes("kew") ? "kew" : cmd.includes("spotify") ? "spotify" : cmd.includes("youtube-music") ? "youtube-music" : cmd.trim().split(" ")[0];
        killProc.command = ["killall", "-9", name];
        killProc.running = true;
    }

    Process {
        id: killProc
    }

    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();

        }
    }

    Instantiator {
        model: Mpris.players

        delegate: QtObject {
            property var p: modelData
            property var state: p.playbackState
            property var title: p.trackTitle

            onStateChanged: root.updatePlayer()
            onTitleChanged: root.updatePlayer()
            Component.onCompleted: root.registerPlayer(p)
            Component.onDestruction: root.unregisterPlayer(p)
        }

    }

}
