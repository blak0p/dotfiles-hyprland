import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    property var widget: null
    property real wavePhase: 0
    property var cavaData: []

    Layout.fillWidth: true

    Process {
        id: cavaProc

        command: ["sh", "-c", "exec cava -p ~/.config/quickshell/Modules/Bar/Widgets/MainPanel/Dashboard/cava.conf"]
        running: MprisService.isPlaying

        onRunningChanged: {
            if (!running) {
                root.cavaData = [];
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.split(";");
                let vals = [];
                for (let i = 0; i < 36 && i < parts.length; i++) {
                    let val = parseInt(parts[i]);
                    if (!isNaN(val))
                        vals.push(val);
                    else
                        vals.push(0);
                }
                root.cavaData = vals;
            }
        }

    }

    Timer {
        running: MprisService.isPlaying
        interval: 16
        repeat: true
        onTriggered: root.wavePhase += 0.01
    }

    RowLayout {
        anchors.fill: parent

        Item {
            id: artSection

            property real size: Math.max(1, height)

            Layout.fillHeight: true
            Layout.preferredWidth: height > 0 ? height : 150
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 36

                Item {
                    required property int index
                    readonly property real angle: index * 360 / 36
                    readonly property real innerR: (artSection.size / 2) * 0.75
                    readonly property real barW: 3
                    readonly property real barH: {
                        if (!MprisService.isPlaying)
                            return 3;

                        if (root.cavaData && root.cavaData.length > index)
                            return 3 + (root.cavaData[index] / 100) * ((artSection.size / 2) * 0.25 - 3);

                        return 3;
                    }

                    x: artSection.width / 2
                    y: artSection.height / 2
                    width: 0
                    height: 0
                    rotation: angle

                    Rectangle {
                        x: -parent.barW / 2
                        y: -(parent.innerR + parent.barH)
                        width: parent.barW
                        height: parent.barH
                        radius: width / 2

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: MprisService.activePlayer ? Theme.accentComplementary : Theme.muted
                            }

                            GradientStop {
                                position: 1
                                color: MprisService.activePlayer ? Theme.accent : Theme.muted
                            }

                        }

                    }

                }

            }

            Item {
                anchors.centerIn: parent
                width: artSection.size * 0.72
                height: artSection.size * 0.72

                Image {
                    id: artImage

                    anchors.fill: parent
                    source: MprisService.activePlayer ? (MprisService.activePlayer.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: artMask

                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: artImage
                    maskSource: artMask
                    visible: artImage.status === Image.Ready && MprisService.activePlayer !== null
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.bgSecondary
                    border.width: 1
                    border.color: Theme.bgSecondary
                    visible: artImage.status !== Image.Ready || MprisService.activePlayer === null

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "music"
                        iconSize: artSection.size * 0.35
                        iconColor: Theme.accent
                        flat: true
                    }

                }

            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeXs

            Item {
                height: MprisService.activePlayerName !== "" ? 20 : 0
                implicitWidth: badgeRect.width

                Rectangle {
                    id: badgeRect

                    visible: MprisService.activePlayerName !== ""
                    color: Theme.bgSecondary
                    radius: Constants.sizeSm
                    height: 18
                    width: badgeLbl.implicitWidth + Constants.sizeMd

                    ThemedText {
                        id: badgeLbl

                        anchors.centerIn: parent
                        text: MprisService.activePlayerName
                        font.pixelSize: Constants.sizeXs + 2
                        font.bold: true
                        color: Theme.accent
                    }

                }

                Behavior on height {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuad
                    }

                }

            }

            ColumnLayout {
                spacing: 0

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackTitle || "Not Playing") : "No Music"
                    font.pixelSize: Constants.sizeMd
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackArtist || "Unknown Artist") : "Open a music player to get started"
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

            BaseSlider {
                id: progressBar

                Layout.fillWidth: true
                Layout.preferredHeight: 16
                from: 0
                to: MprisService.activePlayer && MprisService.activePlayer.length > 0 ? MprisService.activePlayer.length : 1
                value: MprisService.activePlayer ? (!progressBar.pressed ? MprisService.activePlayer.position : progressBar.value) : 0
                enabled: MprisService.activePlayer !== null && MprisService.activePlayer.canSeek
                color: Theme.accent
                animateChanges: !progressBar.pressed
                onMoved: {
                    if (MprisService.activePlayer && MprisService.activePlayer.canSeek)
                        MprisService.activePlayer.position = value;

                }
            }

            RowLayout {
                Layout.fillWidth: true

                ThemedText {
                    text: MprisService.formatTime(MprisService.activePlayer ? MprisService.activePlayer.position : 0)
                    font.pixelSize: Constants.sizeXs + 2
                    color: Theme.muted
                }

                Item {
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: MprisService.formatTime(MprisService.activePlayer ? MprisService.activePlayer.length : 0)
                    font.pixelSize: Constants.sizeXs + 2
                    color: Theme.muted
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                Item {
                    Layout.fillWidth: true
                }

                SvgIconButton {
                    icon: "player-shuffle"
                    iconSize: Constants.sizeSm
                    flat: true
                    isActive: MprisService.activePlayer !== null && MprisService.activePlayer.shuffle
                    iconColor: isActive ? Theme.accent : (MprisService.activePlayer?.shuffleSupported ? Theme.fg : Theme.muted)
                    disabled: MprisService.activePlayer === null || !MprisService.activePlayer.shuffleSupported
                    onClicked: {
                        if (MprisService.activePlayer && MprisService.activePlayer.shuffleSupported)
                            MprisService.activePlayer.shuffle = !MprisService.activePlayer.shuffle;

                    }
                }

                SvgIconButton {
                    icon: "player-previous"
                    iconSize: Constants.sizeMd
                    flat: true
                    iconColor: MprisService.activePlayer !== null ? Theme.fg : Theme.muted
                    disabled: MprisService.activePlayer === null
                    onClicked: {
                        if (MprisService.activePlayer)
                            MprisService.activePlayer.previous();

                    }
                }

                SvgIconButton {
                    id: playBtn

                    icon: MprisService.isPlaying ? "player-pause" : "player-play"
                    iconSize: Constants.sizeLg
                    iconColor: Theme.accent
                    scale: playHover.hovered ? 1.07 : 1
                    onClicked: (mouse) => {
                        if (MprisService.activePlayer !== null) {
                            if (mouse.button === Qt.LeftButton)
                                MprisService.activePlayer.togglePlaying();
                            else if (mouse.button === Qt.RightButton)
                                MprisService.killConfiguredPlayer();
                        } else {
                            playerLauncher.command = SettingsService.musicPlayerCommand.split(" ");
                            playerLauncher.running = true;
                        }
                    }

                    Process {
                        id: playerLauncher
                    }

                    HoverHandler {
                        id: playHover
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

                SvgIconButton {
                    icon: "player-next"
                    iconSize: Constants.sizeMd
                    flat: true
                    iconColor: MprisService.activePlayer !== null ? Theme.fg : Theme.muted
                    disabled: MprisService.activePlayer === null
                    onClicked: {
                        if (MprisService.activePlayer)
                            MprisService.activePlayer.next();

                    }
                }

                SvgIconButton {
                    icon: (MprisService.activePlayer && MprisService.activePlayer.loopState === MprisLoopState.Track) ? "player-loop-once" : "player-loop"
                    iconSize: Constants.sizeSm
                    flat: true
                    isActive: MprisService.activePlayer !== null && MprisService.activePlayer.loopState !== MprisLoopState.None
                    iconColor: isActive ? Theme.accent : (MprisService.activePlayer?.loopSupported ? Theme.fg : Theme.muted)
                    disabled: MprisService.activePlayer === null || !MprisService.activePlayer.loopSupported
                    onClicked: {
                        if (!MprisService.activePlayer || !MprisService.activePlayer.loopSupported)
                            return ;

                        if (MprisService.activePlayer.loopState === MprisLoopState.None)
                            MprisService.activePlayer.loopState = MprisLoopState.Track;
                        else if (MprisService.activePlayer.loopState === MprisLoopState.Track)
                            MprisService.activePlayer.loopState = MprisLoopState.Playlist;
                        else
                            MprisService.activePlayer.loopState = MprisLoopState.None;
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

            }

        }

    }

}
