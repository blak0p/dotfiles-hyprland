import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.services

Card {
    id: topAppsCard

    property var topApps: []
    property bool isOnline: false
    property var appIconMap: ({
    })
    property string dateStr: ""
    readonly property var displayModel: {
        if (!isOnline)
            return [];

        if (topApps && topApps.length > 0)
            return topApps;

        return [{
            "app": "Empty slot",
            "isEmpty": true,
            "percentage": 0,
            "durationStr": "0m"
        }, {
            "app": "Empty slot",
            "isEmpty": true,
            "percentage": 0,
            "durationStr": "0m"
        }, {
            "app": "Empty slot",
            "isEmpty": true,
            "percentage": 0,
            "durationStr": "0m"
        }, {
            "app": "Empty slot",
            "isEmpty": true,
            "percentage": 0,
            "durationStr": "0m"
        }, {
            "app": "Empty slot",
            "isEmpty": true,
            "percentage": 0,
            "durationStr": "0m"
        }];
    }

    backgroundColor: Theme.bgSecondary

    ColumnLayout {
        id: columnLayout

        anchors.fill: parent
        spacing: Constants.sizeLg

        ColumnLayout {
            spacing: 2

            ThemedText {
                text: Translation.tr("Top Apps")
                font.pixelSize: Constants.sizeLg
                font.bold: true
                color: Theme.fg
            }

            ThemedText {
                text: topAppsCard.dateStr
                font.pixelSize: Constants.sizeXs + 2
                color: Theme.muted
                visible: topAppsCard.dateStr !== ""
            }

        }

        ColumnLayout {
            visible: !topAppsCard.isOnline
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeSm

            Item {
                Layout.fillHeight: true
            }

            ThemedText {
                text: Translation.tr("ActivityWatch is not running")
                font.pixelSize: Constants.sizeSm
                font.bold: true
                color: Theme.muted
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

        }

        ColumnLayout {
            visible: topAppsCard.isOnline
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeLg

            Repeater {
                model: topAppsCard.displayModel

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeMd

                    Rectangle {
                        width: 28
                        height: 28
                        radius: width / 2
                        color: "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        SvgIcon {
                            anchors.fill: parent
                            icon: "rocket"
                            iconSize: modelData.isEmpty ? Constants.sizeMd : Constants.sizeXl
                            flat: true
                            iconColor: Theme.muted
                            visible: modelData.isEmpty || !appIcon.visible
                        }

                        Image {
                            id: appIcon

                            anchors.fill: parent
                            visible: !modelData.isEmpty && status === Image.Ready
                            source: {
                                if (modelData.isEmpty || !modelData.app)
                                    return "";

                                let app = modelData.app.toLowerCase();
                                let iconName = topAppsCard.appIconMap[app];
                                if (!iconName) {
                                    let base = app.split('/').pop().split(' ')[0];
                                    iconName = topAppsCard.appIconMap[base];
                                }
                                if (!iconName) {
                                    for (let key in topAppsCard.appIconMap) {
                                        if (app.includes(key) || key.includes(app)) {
                                            iconName = topAppsCard.appIconMap[key];
                                            break;
                                        }
                                    }
                                }
                                if (!iconName)
                                    iconName = app;

                                if (iconName.startsWith("/") || iconName.startsWith("file://"))
                                    return iconName.startsWith("file://") ? iconName : "file://" + iconName;

                                let resolved = Quickshell.iconPath(iconName, true);
                                if (resolved)
                                    return resolved;

                                if (app.endsWith("-browser")) {
                                    resolved = Quickshell.iconPath(app, true);
                                    if (resolved)
                                        return resolved;

                                    return Quickshell.iconPath(app.replace("-browser", ""), true);
                                }
                                return Quickshell.iconPath(app, true);
                            }
                            fillMode: Image.PreserveAspectFit
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: modelData.isEmpty ? Constants.sizeXs : (Constants.sizeXs / 4)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Constants.sizeLg * 2

                            ThemedText {
                                text: modelData.app
                                font.weight: modelData.isEmpty ? Font.Normal : Font.Medium
                                font.pixelSize: Constants.sizeSm
                                color: modelData.isEmpty ? Theme.muted : Theme.fg
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            ThemedText {
                                text: modelData.isEmpty ? "0m" : (modelData.durationStr + " (" + Math.round(modelData.percentage * 100) + "%)")
                                font.pixelSize: Constants.sizeSm
                                color: Theme.muted
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: height / 2
                            color: Theme.bgSecondary

                            Rectangle {
                                visible: !modelData.isEmpty
                                height: parent.height
                                width: parent.width * (modelData.percentage || 0)
                                radius: height / 2
                                color: Theme.accent
                            }

                        }

                    }

                }

            }

        }

    }

}
