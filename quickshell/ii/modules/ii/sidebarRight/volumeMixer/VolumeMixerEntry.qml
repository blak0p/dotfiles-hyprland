import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property PwNode node
    PwObjectTracker {
        objects: [root.node]
    }

    implicitHeight: rowLayout.implicitHeight + 8

    RowLayout {
        id: rowLayout
        anchors {
            fill: parent
            topMargin: 4
            bottomMargin: 4
        }
        spacing: 10

        MouseArea {
            property real size: 40
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: size
            Layout.preferredHeight: size

            cursorShape: Qt.PointingHandCursor
            onClicked: root.node.audio.muted = !root.node.audio.muted

            hoverEnabled: true
            property bool hovered: containsMouse
            StyledToolTip {
                text: (root.node && root.node.audio && root.node.audio.muted) ? Translation.tr("Click to unmute") : Translation.tr("Click to mute")
            }

            StyledImage {
                id: iconImg
                anchors.fill: parent
                visible: false
                source: {
                    let icon;
                    icon = AppSearch.guessIcon((root.node && root.node.properties) ? (root.node.properties["application.icon-name"] || "") : "");
                    if (AppSearch.iconExists(icon))
                        return Quickshell.iconPath(icon, "image-missing");
                    icon = AppSearch.guessIcon((root.node && root.node.properties) ? (root.node.properties["node.name"] || "") : "");
                    return Quickshell.iconPath(icon, "image-missing");
                }
            }

            Desaturate {
                anchors.fill: iconImg
                source: iconImg
                desaturation: (root.node && root.node.audio && root.node.audio.muted) ? 1.0 : 0.0
                visible: iconImg.source !== ""
                opacity: (root.node && root.node.audio && root.node.audio.muted) ? 0.4 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Behavior on desaturation {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: Boolean(root.node && root.node.audio && root.node.audio.muted)
                text: (root.node && root.node.isSink) ? "volume_off" : "mic_off"
                iconSize: 24
                color: Appearance.colors.colOnLayer1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                id: titleText
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
                text: Audio.appNodeDisplayName(root.node)
            }

            StyledText {
                id: subtitleText
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                opacity: 0.85
                elide: Text.ElideRight
                visible: text.length > 0
                text: {
                    const media = (root.node && root.node.properties) ? root.node.properties["media.name"] : null;
                    if (!media) return "";
                    const trimmed = media.trim();
                    const lower = trimmed.toLowerCase();
                    const appName = Audio.appNodeDisplayName(root.node).trim().toLowerCase();
                    if (lower === "0" || lower === "1" || lower === "playback" || lower === appName) {
                        return "";
                    }
                    return trimmed;
                }
            }

            StyledSlider {
                id: slider
                Layout.fillWidth: true
                value: (root.node && root.node.audio) ? root.node.audio.volume : 0
                onMoved: {
                    if (root.node && root.node.audio)
                        root.node.audio.volume = value;
                }
                configuration: StyledSlider.Configuration.S
            }
        }
    }
}
