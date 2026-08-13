import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Windows

CenterWindow {
    id: root

    property var menuModel: [{
        "id": "lock",
        "icon": "lock",
        "command": ["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "lock", "activate"],
        "confirm": false
    }, {
        "id": "suspend",
        "icon": "moon",
        "command": ["sh", "-c", "mpc -q pause; amixer set Master mute; systemctl suspend"],
        "confirm": true
    }, {
        "id": "logout",
        "icon": "logout",
        "command": ["hyprctl", "dispatch", "exit"],
        "confirm": true
    }, {
        "id": "reboot",
        "icon": "reload",
        "command": ["systemctl", "reboot"],
        "confirm": true
    }, {
        "id": "shutdown",
        "icon": "power",
        "command": ["systemctl", "poweroff"],
        "confirm": true
    }]

    signal requestClose()

    function runAction(index) {
        if (index >= 0 && index < root.menuModel.length) {
            let modelData = root.menuModel[index];
            if (modelData.confirm) {
                let scriptPath = Quickshell.env("HOME") + "/.config/quickshell/Scripts/power_action.sh";
                let args = [scriptPath, modelData.id];
                for (let arg of modelData.command) args.push(arg)
                actionProc.command = ["bash"].concat(args);
            } else {
                actionProc.command = modelData.command;
            }
            actionProc.startDetached();
            root.isOpen = false;
        }
    }

    popupId: "powerMenu"
    preferredWidth: contentRow.implicitWidth + (Constants.sizeLg * 2)
    preferredHeight: contentRow.implicitHeight + (Constants.sizeLg * 2)
    onPopupOpened: {
        focusTimer.start();
        contentRow.currentIndex = 0;
    }

    Timer {
        id: focusTimer

        interval: 50
        repeat: false
        onTriggered: contentRow.forceActiveFocus()
    }

    Process {
        id: actionProc
    }

    RowLayout {
        id: contentRow

        property int currentIndex: 0

        Layout.alignment: Qt.AlignCenter
        spacing: Constants.size2Xl
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Right) {
                if (currentIndex + 1 < root.menuModel.length) {
                    currentIndex++;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Left) {
                if (currentIndex - 1 >= 0) {
                    currentIndex--;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.runAction(currentIndex);
                event.accepted = true;
            }
        }

        Repeater {
            model: root.menuModel

            delegate: Item {
                id: delegateRoot

                readonly property bool isCurrent: contentRow.currentIndex === index
                readonly property bool isHovered: hoverHandler.hovered || isCurrent
                readonly property bool isPressed: tapHandler.pressed

                implicitWidth: 80
                implicitHeight: 80
                scale: isPressed ? 0.95 : (isHovered ? 1.05 : 1)

                Rectangle {
                    anchors.fill: parent
                    radius: Constants.size2Xl
                    color: isHovered ? Theme.bgSecondary : "transparent"
                    border.width: isCurrent ? 2 : 1
                    border.color: isCurrent ? Theme.accent : (isHovered ? "transparent" : Theme.border)

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

                SvgIcon {
                    anchors.centerIn: parent
                    icon: modelData.icon
                    iconSize: Constants.size2Xl
                    flat: true
                    iconColor: delegateRoot.isHovered ? Theme.accent : Theme.fg

                    Behavior on iconColor {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

                HoverHandler {
                    id: hoverHandler

                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered)
                            contentRow.currentIndex = index;

                    }
                }

                TapHandler {
                    id: tapHandler

                    onTapped: {
                        contentRow.currentIndex = index;
                        root.runAction(index);
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

    }

}
