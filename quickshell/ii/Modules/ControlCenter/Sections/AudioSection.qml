import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.modules.common
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int contentHeightHint: 300
    property bool canGoBack: false
    signal back()

    property int audioSubTab: 0 // 0: Dispositivos, 1: Mezclador de Apps
    spacing: 10

    function resolveStreamIcon(node) {
        if (!node) return "";
        const props = node.properties || {};
        const candidates = [
            props["application.icon-name"],
            props["application.icon_name"],
            props["application.process.binary"],
            props["application.name"],
            props["node.name"]
        ];

        for (let i = 0; i < candidates.length; i++) {
            const raw = candidates[i];
            if (!raw || typeof raw !== "string" || raw.trim() === "") continue;
            const name = raw.trim();

            if (name.startsWith("file://") || name.startsWith("http://") || name.startsWith("https://") || name.startsWith("image://"))
                return name;
            if (name.startsWith("/"))
                return "file://" + name;

            let path = Quickshell.iconPath(name, true);
            if (path && path.length > 0) return path;

            let lower = name.toLowerCase();
            path = Quickshell.iconPath(lower, true);
            if (path && path.length > 0) return path;

            let entry = DesktopEntries.byId(lower) || DesktopEntries.byId(name);
            if (entry && entry.icon) {
                let ep = Quickshell.iconPath(entry.icon, true);
                if (ep && ep.length > 0) return ep;
            }

            if (typeof DesktopEntries.heuristicLookup === "function") {
                let heuristic = DesktopEntries.heuristicLookup(lower);
                if (heuristic && heuristic.icon) {
                    let hp = Quickshell.iconPath(heuristic.icon, true);
                    if (hp && hp.length > 0) return hp;
                }
            }
        }
        return "";
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            visible: root.canGoBack
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.bgTertiary : "transparent"
            scale: backMouse.pressed ? 0.88 : (backMouse.containsMouse ? 1.12 : 1.0)

            Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "chevron-left"
                iconSize: 14
                iconColor: backMouse.containsMouse ? Theme.accent : Theme.fg
                flat: true
                Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        ThemedText {
            text: Translation.tr("Audio & Sound")
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedTabs {
            activeValue: root.audioSubTab
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            ThemedTab { value: 0; text: Translation.tr("Devices") }
            ThemedTab { value: 1; text: Translation.tr("App Mixer") + " (" + Audio.outputAppNodes.length + ")" }

            onTabSelected: (v) => { root.audioSubTab = v }
        }
    }

    // ==========================================
    // VIEW 0: DISPOSITIVOS (Salidas y Entradas)
    // ==========================================
    Flickable {
        id: devFlickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.audioSubTab === 0
        clip: true
        contentWidth: width
        contentHeight: devContentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: devContentCol
            width: devFlickable.width
            spacing: 8

            // ---- Salidas de audio ----
            ThemedText {
                text: Translation.tr("Audio output")
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: Theme.muted
            }

            Repeater {
                model: Audio.outputDevices
                delegate: Rectangle {
                    id: sinkDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 50
                    radius: Constants.sizeLg
                    readonly property bool isDefault: Boolean(sinkDelegate.modelData && Pipewire.defaultAudioSink && sinkDelegate.modelData.id === Pipewire.defaultAudioSink.id)
                    color: sinkDelegate.isDefault
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                        : (sinkHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                    border.width: sinkDelegate.isDefault ? 1 : 0
                    border.color: sinkDelegate.isDefault ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

                    Behavior on color { ColorAnimation { duration: Constants.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                    PwObjectTracker {
                        objects: [sinkDelegate.modelData]
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: sinkDelegate.isDefault ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)

                            SvgIcon {
                                anchors.centerIn: parent
                                icon: sinkDelegate.isDefault ? "check" : "volume"
                                iconSize: 14
                                flat: true
                                iconColor: sinkDelegate.isDefault ? (Theme.isDark ? "#000000" : "#ffffff") : Theme.muted
                            }
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(sinkDelegate.modelData)
                            font.pixelSize: Constants.sizeSm + 2
                            font.bold: sinkDelegate.isDefault
                            color: sinkDelegate.isDefault ? Theme.accent : Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedSlider {
                            Layout.preferredWidth: 120
                            from: 0
                            to: Audio.hardMaxValue
                            stepSize: 0.01
                            suffix: "%"
                            value: (sinkDelegate.modelData && sinkDelegate.modelData.audio) ? sinkDelegate.modelData.audio.volume : 0
                            onMoved: (val) => {
                                if (sinkDelegate.modelData && sinkDelegate.modelData.audio)
                                    sinkDelegate.modelData.audio.volume = Math.min(Audio.hardMaxValue, Math.max(0.0, val));
                            }
                        }

                        SvgIcon {
                            icon: (sinkDelegate.modelData && sinkDelegate.modelData.audio && sinkDelegate.modelData.audio.muted) ? "volume-off" : "volume"
                            iconSize: Constants.sizeLg
                            flat: true
                            iconColor: (sinkDelegate.modelData && sinkDelegate.modelData.audio && sinkDelegate.modelData.audio.muted) ? "#ff6b6b" : Theme.muted
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (sinkDelegate.modelData && sinkDelegate.modelData.audio)
                                        sinkDelegate.modelData.audio.muted = !sinkDelegate.modelData.audio.muted;
                                }
                            }
                        }
                    }

                    HoverHandler { id: sinkHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: Audio.setDefaultSink(sinkDelegate.modelData)
                    }
                }
            }

            // ---- Entradas de audio (Micrófonos) ----
            ThemedText {
                text: Translation.tr("Audio input")
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: Theme.muted
                Layout.topMargin: 4
            }

            Repeater {
                model: Audio.inputDevices
                delegate: Rectangle {
                    id: sourceDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 50
                    radius: Constants.sizeLg
                    readonly property bool isDefault: Boolean(sourceDelegate.modelData && Pipewire.defaultAudioSource && sourceDelegate.modelData.id === Pipewire.defaultAudioSource.id)
                    color: sourceDelegate.isDefault
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                        : (srcHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                    border.width: sourceDelegate.isDefault ? 1 : 0
                    border.color: sourceDelegate.isDefault ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

                    Behavior on color { ColorAnimation { duration: Constants.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Constants.animFast } }

                    PwObjectTracker {
                        objects: [sourceDelegate.modelData]
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: sourceDelegate.isDefault ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)

                            SvgIcon {
                                anchors.centerIn: parent
                                icon: sourceDelegate.isDefault ? "check" : "microphone"
                                iconSize: 14
                                flat: true
                                iconColor: sourceDelegate.isDefault ? (Theme.isDark ? "#000000" : "#ffffff") : Theme.muted
                            }
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(sourceDelegate.modelData)
                            font.pixelSize: Constants.sizeSm + 2
                            font.bold: sourceDelegate.isDefault
                            color: sourceDelegate.isDefault ? Theme.accent : Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedSlider {
                            Layout.preferredWidth: 120
                            from: 0
                            to: Audio.hardMaxValue
                            stepSize: 0.01
                            suffix: "%"
                            value: (sourceDelegate.modelData && sourceDelegate.modelData.audio) ? sourceDelegate.modelData.audio.volume : 0
                            onMoved: (val) => {
                                if (sourceDelegate.modelData && sourceDelegate.modelData.audio)
                                    sourceDelegate.modelData.audio.volume = Math.min(Audio.hardMaxValue, Math.max(0.0, val));
                            }
                        }

                        SvgIcon {
                            icon: (sourceDelegate.modelData && sourceDelegate.modelData.audio && sourceDelegate.modelData.audio.muted) ? "microphone-off" : "microphone"
                            iconSize: Constants.sizeLg
                            flat: true
                            iconColor: (sourceDelegate.modelData && sourceDelegate.modelData.audio && sourceDelegate.modelData.audio.muted) ? "#ff6b6b" : Theme.muted
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (sourceDelegate.modelData && sourceDelegate.modelData.audio)
                                        sourceDelegate.modelData.audio.muted = !sourceDelegate.modelData.audio.muted;
                                }
                            }
                        }
                    }

                    HoverHandler { id: srcHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: Audio.setDefaultSource(sourceDelegate.modelData)
                    }
                }
            }
        }
    }

    // ==========================================
    // VIEW 1: MEZCLADOR DE APLICACIONES
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.audioSubTab === 1
        spacing: 8

        // Empty state
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Constants.sizeLg
            color: "transparent"
            visible: Audio.outputAppNodes.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                SvgIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "volume"
                    iconSize: 28
                    flat: true
                    iconColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No apps playing audio")
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            visible: Audio.outputAppNodes.length > 0
            model: Audio.outputAppNodes
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: appStreamDelegate
                required property var modelData
                width: ListView.view.width
                implicitHeight: 60
                radius: Constants.sizeLg
                color: appStreamHover.hovered ? Theme.bgTertiary : Theme.bgSecondary

                Behavior on color { ColorAnimation { duration: Constants.animFast } }

                PwObjectTracker {
                    objects: [appStreamDelegate.modelData]
                }

                HoverHandler { id: appStreamHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // App Icon Container (36x36 squircle)
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        radius: 10
                        color: Qt.rgba(Theme.overlayBase.r, Theme.overlayBase.g, Theme.overlayBase.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        clip: true

                        readonly property string streamIcon: root.resolveStreamIcon(appStreamDelegate.modelData)

                        Image {
                            id: streamImg
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            sourceSize.width: 24
                            sourceSize.height: 24
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            source: parent.streamIcon
                            visible: parent.streamIcon !== "" && status === Image.Ready
                        }

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "music"
                            iconSize: 18
                            flat: true
                            iconColor: Theme.fg
                            visible: !streamImg.visible
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        ThemedText {
                            Layout.fillWidth: true
                            text: Audio.appNodeDisplayName(appStreamDelegate.modelData)
                            font.bold: true
                            font.pixelSize: 15
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: (appStreamDelegate.modelData && appStreamDelegate.modelData.properties && appStreamDelegate.modelData.properties["media.name"]) || Translation.tr("Audio stream")
                            font.pixelSize: 12
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.85)
                            elide: Text.ElideRight
                        }
                    }

                    ThemedSlider {
                        Layout.preferredWidth: 120
                        from: 0
                        to: Audio.hardMaxValue
                        stepSize: 0.01
                        suffix: "%"
                        value: (appStreamDelegate.modelData && appStreamDelegate.modelData.audio) ? appStreamDelegate.modelData.audio.volume : 0
                        onMoved: (val) => {
                            if (appStreamDelegate.modelData && appStreamDelegate.modelData.audio)
                                appStreamDelegate.modelData.audio.volume = Math.min(Audio.hardMaxValue, Math.max(0.0, val));
                        }
                    }

                    SvgIcon {
                        icon: (appStreamDelegate.modelData && appStreamDelegate.modelData.audio && appStreamDelegate.modelData.audio.muted) ? "volume-off" : "volume"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: (appStreamDelegate.modelData && appStreamDelegate.modelData.audio && appStreamDelegate.modelData.audio.muted) ? "#ff6b6b" : Theme.muted
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (appStreamDelegate.modelData && appStreamDelegate.modelData.audio)
                                    appStreamDelegate.modelData.audio.muted = !appStreamDelegate.modelData.audio.muted;
                            }
                        }
                    }
                }
            }
        }
    }
}

