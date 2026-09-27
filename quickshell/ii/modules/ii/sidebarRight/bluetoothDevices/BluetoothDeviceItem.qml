import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    
    component PillActionButton: Rectangle {
        id: pillBtn
        property string iconName: ""
        property string text: ""
        property color textColor: Appearance.colors.colOnPrimary
        property color iconColor: textColor
        property color baseColor: Appearance.colors.colPrimary
        property color hoverColor: baseColor
        property alias containsMouse: pillMouse.containsMouse
        signal clicked()

        implicitHeight: 30
        implicitWidth: pillContentRow.implicitWidth + 28
        radius: height / 2
        color: pillMouse.containsMouse ? hoverColor : baseColor
        scale: pillMouse.pressed ? 0.92 : (pillMouse.containsMouse ? 1.05 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutBack }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        RowLayout {
            id: pillContentRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                visible: pillBtn.iconName !== ""
                text: pillBtn.iconName
                iconSize: 14
                color: pillBtn.iconColor
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: pillBtn.text
                font.pixelSize: 12
                font.bold: true
                color: pillBtn.textColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillBtn.clicked()
        }
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device ? root.device.icon || "" : "")
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: (root.device ? root.device.name || "" : "") || Translation.tr("Unknown device")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: Boolean(root.device && (root.device.connected || root.device.paired))
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        if (!root.device || !root.device.paired) return "";
                        let statusText = root.device.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (!root.device.batteryAvailable) return statusText;
                        statusText += " • " + Math.round(root.device.battery * 100) + "%";
                        return statusText;
                    }
                }
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer3
                rotation: root.expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.topMargin: 8
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            PillActionButton {
                visible: Boolean(root.device && root.device.paired)
                baseColor: Qt.rgba(1, 0.35, 0.35, 0.1)
                hoverColor: Qt.rgba(1, 0.35, 0.35, 0.2)
                textColor: "#ff6b6b"
                iconColor: "#ff6b6b"
                iconName: "delete"
                text: Translation.tr("Forget")
                onClicked: {
                    if (root.device && typeof root.device.forget === "function") {
                        root.device.forget();
                    }
                }
            }

            PillActionButton {
                visible: Boolean(root.device && !root.device.paired && !root.device.connected)
                baseColor: Appearance.colors.colPrimary
                hoverColor: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colOnPrimary, 0.88)
                textColor: Appearance.colors.colOnPrimary
                iconColor: Appearance.colors.colOnPrimary
                iconName: "add"
                text: Translation.tr("Pair")
                onClicked: {
                    if (root.device && typeof root.device.pair === "function") {
                        root.device.pair();
                    }
                }
            }

            PillActionButton {
                readonly property bool isConnected: Boolean(root.device && root.device.connected)
                baseColor: isConnected ? Qt.rgba(1, 1, 1, 0.08) : Appearance.colors.colPrimary
                hoverColor: isConnected ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) : ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colOnPrimary, 0.88)
                textColor: isConnected ? Appearance.colors.colOnSurface : Appearance.colors.colOnPrimary
                iconColor: isConnected ? Appearance.colors.colOnSurface : Appearance.colors.colOnPrimary
                iconName: isConnected ? "link_off" : "link"
                text: isConnected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (!root.device) return;
                    if (root.device.connected) {
                        if (typeof root.device.disconnect === "function") {
                            root.device.disconnect();
                        } else {
                            root.device.connected = false;
                        }
                    } else {
                        if (typeof root.device.connect === "function") {
                            root.device.connect();
                        } else {
                            root.device.connected = true;
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
