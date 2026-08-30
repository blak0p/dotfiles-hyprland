import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

ColumnLayout {
    id: root

    property int audioSubTab: 0 // 0: Dispositivos, 1: Mezclador de Apps
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedTabs {
            activeValue: root.audioSubTab
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            ThemedTab { value: 0; text: "Dispositivos" }
            ThemedTab { value: 1; text: "Mezclador de Apps (" + Audio.outputAppNodes.length + ")" }

            onTabSelected: (v) => { root.audioSubTab = v }
        }
    }

    // ==========================================
    // VIEW 0: DISPOSITIVOS (Salidas y Entradas)
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.audioSubTab === 0
        spacing: 10

        // ---- Salidas de audio ----
        ThemedText {
            text: "Salidas de Audio"
            font.pixelSize: Constants.sizeSm
            font.bold: true
            color: Theme.muted
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Audio.outputDevices.length * 56, 170)
            clip: true
            spacing: 6
            model: Audio.outputDevices
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: sinkDelegate
                required property var modelData
                width: ListView.view.width
                implicitHeight: 50
                radius: Constants.sizeLg
                readonly property bool isDefault: modelData?.id === Pipewire.defaultAudioSink?.id
                color: isDefault
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    : (sinkHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                border.width: isDefault ? 1 : 0
                border.color: isDefault ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

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
                        font.pixelSize: Constants.sizeSm
                        font.bold: sinkDelegate.isDefault
                        color: sinkDelegate.isDefault ? Theme.accent : Theme.fg
                        elide: Text.ElideRight
                    }

                    ThemedSlider {
                        Layout.preferredWidth: 140
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: sinkDelegate.modelData?.audio?.volume ?? 0
                        onMoved: (val) => {
                            if (sinkDelegate.modelData && sinkDelegate.modelData.audio)
                                sinkDelegate.modelData.audio.volume = val;
                        }
                    }

                    SvgIcon {
                        icon: sinkDelegate.modelData?.audio?.muted ? "volume-off" : "volume"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: sinkDelegate.modelData?.audio?.muted ? "#ff6b6b" : Theme.muted
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
            text: "Entradas / Micrófonos"
            font.pixelSize: Constants.sizeSm
            font.bold: true
            color: Theme.muted
            Layout.topMargin: 4
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Audio.inputDevices.length * 56, 150)
            clip: true
            spacing: 6
            model: Audio.inputDevices
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: sourceDelegate
                required property var modelData
                width: ListView.view.width
                implicitHeight: 50
                radius: Constants.sizeLg
                readonly property bool isDefault: modelData?.id === Pipewire.defaultAudioSource?.id
                color: isDefault
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    : (srcHover.hovered ? Theme.bgTertiary : Theme.bgSecondary)
                border.width: isDefault ? 1 : 0
                border.color: isDefault ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

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
                        font.pixelSize: Constants.sizeSm
                        font.bold: sourceDelegate.isDefault
                        color: sourceDelegate.isDefault ? Theme.accent : Theme.fg
                        elide: Text.ElideRight
                    }

                    ThemedSlider {
                        Layout.preferredWidth: 140
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: sourceDelegate.modelData?.audio?.volume ?? 0
                        onMoved: (val) => {
                            if (sourceDelegate.modelData && sourceDelegate.modelData.audio)
                                sourceDelegate.modelData.audio.volume = val;
                        }
                    }

                    SvgIcon {
                        icon: sourceDelegate.modelData?.audio?.muted ? "microphone-off" : "microphone"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: sourceDelegate.modelData?.audio?.muted ? "#ff6b6b" : Theme.muted
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
            implicitHeight: 160
            radius: Constants.sizeLg
            color: Theme.bgSecondary
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
                    text: "No hay aplicaciones reproduciendo audio"
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Audio.outputAppNodes.length * 64, 380)
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
                implicitHeight: 56
                radius: Constants.sizeLg
                color: Theme.bgSecondary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignVCenter
                        source: {
                            let iconName = appStreamDelegate.modelData?.properties["application.icon-name"] || appStreamDelegate.modelData?.properties["node.name"] || "";
                            let guessed = AppSearch.guessIcon(iconName);
                            let path = Quickshell.iconPath(guessed, true);
                            if (path && path.length > 0) return path;
                            return "image://icon/application-x-executable";
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        ThemedText {
                            Layout.fillWidth: true
                            text: Audio.appNodeDisplayName(appStreamDelegate.modelData)
                            font.bold: true
                            font.pixelSize: Constants.sizeSm
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: appStreamDelegate.modelData?.properties["media.name"] || "Flujo de audio"
                            font.pixelSize: Constants.size2Xs + 1
                            color: Theme.muted
                            elide: Text.ElideRight
                        }
                    }

                    ThemedSlider {
                        Layout.preferredWidth: 160
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: appStreamDelegate.modelData?.audio?.volume ?? 0
                        onMoved: (val) => {
                            if (appStreamDelegate.modelData && appStreamDelegate.modelData.audio)
                                appStreamDelegate.modelData.audio.volume = val;
                        }
                    }

                    SvgIcon {
                        icon: appStreamDelegate.modelData?.audio?.muted ? "volume-off" : "volume"
                        iconSize: Constants.sizeLg
                        flat: true
                        iconColor: appStreamDelegate.modelData?.audio?.muted ? "#ff6b6b" : Theme.muted
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
