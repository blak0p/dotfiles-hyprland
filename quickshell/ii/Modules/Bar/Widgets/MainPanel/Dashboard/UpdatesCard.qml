import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Card {
    id: root

    readonly property string cachyUpdates: UpdateService.cachyUpdatesCount
    readonly property string homebrewUpdates: UpdateService.homebrewUpdatesCount
    readonly property bool countsReady: /^\d+$/.test(cachyUpdates) && /^\d+$/.test(homebrewUpdates)
    readonly property int totalUpdates: countsReady ? Number(cachyUpdates) + Number(homebrewUpdates) : 0
    property bool hasUpdates: countsReady && totalUpdates > 0
    readonly property bool isChecking: UpdateService.isCheckingUpdates || !countsReady
    readonly property bool isUpdating: UpdateService.isSystemUpdating

    function runUpdate() {
        UpdateService.runSystemUpdate();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: Translation.tr("System Updates")
                font.pixelSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.hasUpdates && !root.isUpdating && !root.isChecking
                color: Theme.bgSecondary
                radius: height / 2
                implicitWidth: updateCountText.implicitWidth + 12
                implicitHeight: 18

                ThemedText {
                    id: updateCountText

                    anchors.centerIn: parent
                    text: {
                        return root.totalUpdates + " NEW";
                    }
                    font.pixelSize: Constants.sizeXs
                    font.bold: true
                    color: Theme.accent
                }

            }

        }

        Divider {
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            RowLayout {
                spacing: Constants.sizeSm
                Layout.fillWidth: true

                SvgIcon {
                    id: statusIcon

                    icon: {
                        if (root.isUpdating || root.isChecking)
                            return "reload";

                        return root.hasUpdates ? "update" : "check";
                    }
                    flat: true
                    iconColor: {
                        if (root.isUpdating)
                            return Theme.accent;

                        if (root.isChecking)
                            return Theme.muted;

                        return Theme.accent;
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.isUpdating || root.isChecking
                        onRunningChanged: {
                            if (!running)
                                statusIcon.rotation = 0;

                        }
                    }

                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    ThemedText {
                        text: {
                            if (root.isUpdating)
                                return Translation.tr("Updating system...");

                            if (root.isChecking)
                                return Translation.tr("Checking updates...");

                            if (root.cachyUpdates === "..." || root.homebrewUpdates === "...")
                                return Translation.tr("Checking updates...");

                            let total = root.totalUpdates;
                            return total > 0 ? total + " " + Translation.tr("packages pending") : Translation.tr("System up to date");
                        }
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                    }

                    ThemedText {
                        text: {
                            if (root.isUpdating || root.isChecking || root.cachyUpdates === "..." || root.homebrewUpdates === "...")
                                return Translation.tr("Please wait");

                            if (root.totalUpdates > 0) {
                                return "CachyOS: " + (parseInt(root.cachyUpdates) || 0) + " · Homebrew: " + (parseInt(root.homebrewUpdates) || 0);
                            }

                            return Translation.tr("All packages are currently up to date");
                        }
                        font.pixelSize: Constants.sizeXs
                        color: Theme.muted
                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

            ThemedButton {
                id: updateButton

                text: root.hasUpdates && !root.isUpdating ? Translation.tr("Update") : Translation.tr("Check")
                enabled: !root.isChecking && !root.isUpdating
                onClicked: {
                    if (root.hasUpdates)
                        root.runUpdate();
                    else
                        UpdateService.checkUpdates();
                }

                SequentialAnimation on scale {
                    running: root.hasUpdates && !root.isUpdating
                    loops: Animation.Infinite

                    PropertyAnimation {
                        to: 1.04
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }

                    PropertyAnimation {
                        to: 1
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }

                }

            }

        }

    }

}
