import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.services

ColumnLayout {
    id: menuRoot

    property var menuHandle: null
    property var menuStack: []
    property string title: Translation.tr("Menu")
    property var activeChildren: menuRoot.menuStack.length > 1 ? subOpener.children : rootOpener.children

    signal backRequested()
    signal closeRequested()

    function resetToRoot() {
        if (menuHandle)
            menuRoot.menuStack = [menuHandle];
        else
            menuRoot.menuStack = [];
    }

    function isRedundantSeparator(idx) {
        let children = menuRoot.activeChildren;
        if (!children)
            return false;

        let prevIsSeparator = true;
        for (let i = idx - 1; i >= 0; i--) {
            let prev = children[i];
            if (prev && (prev.text !== "" || prev.isSeparator)) {
                if (!prev.isSeparator)
                    prevIsSeparator = false;

                break;
            }
        }
        if (prevIsSeparator)
            return true;

        let nextIsSeparator = true;
        for (let i = idx + 1; i < children.length; i++) {
            let next = children[i];
            if (next && (next.text !== "" || next.isSeparator)) {
                if (!next.isSeparator)
                    nextIsSeparator = false;

                break;
            }
        }
        if (nextIsSeparator)
            return true;

        return false;
    }

    spacing: Constants.sizeXs
    onMenuHandleChanged: {
        if (menuHandle)
            menuRoot.menuStack = [menuHandle];
        else
            menuRoot.menuStack = [];
    }

    QsMenuOpener {
        id: rootOpener

        menu: menuRoot.menuHandle
    }

    QsMenuOpener {
        id: subOpener

        menu: menuRoot.menuStack.length > 1 ? menuRoot.menuStack[menuRoot.menuStack.length - 1] : null
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Constants.sizeSm

        SvgIcon {
            icon: "chevron-left"
            iconColor: Theme.muted
            iconSize: Constants.sizeLg
            flat: true
            visible: menuRoot.menuStack.length > 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let s = menuRoot.menuStack.slice();
                    s.pop();
                    menuRoot.menuStack = s;
                }
            }

        }

        ThemedText {
            text: menuRoot.menuStack.length > 1 ? (menuRoot.menuStack[menuRoot.menuStack.length - 1].text || "Back") : menuRoot.title
            font.pixelSize: Constants.sizeLg
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

    }

    Divider {
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: Constants.sizeXs

            Repeater {
                model: menuRoot.activeChildren

                delegate: Rectangle {
                    id: itemRoot

                    property real animOffsetX: 15

                    Layout.fillWidth: true
                    Layout.preferredHeight: (modelData && modelData.isSeparator) ? 1 : 32
                    implicitWidth: (modelData && modelData.isSeparator) ? 0 : (itemRow.implicitWidth + (Constants.sizeSm * 2))
                    color: itemMouseArea.containsMouse ? Theme.bgSecondary : "transparent"
                    radius: Constants.sizeLg
                    visible: {
                        if (!modelData)
                            return false;

                        if (modelData.isSeparator)
                            return !menuRoot.isRedundantSeparator(index);

                        return modelData.text !== "";
                    }
                    opacity: 0
                    Component.onCompleted: {
                        itemRoot.opacity = 1;
                        itemRoot.animOffsetX = 0;
                    }

                    RowLayout {
                        id: itemRow

                        anchors.fill: parent
                        anchors.leftMargin: Constants.sizeSm
                        anchors.rightMargin: Constants.sizeSm
                        spacing: Constants.sizeSm
                        visible: modelData && !modelData.isSeparator

                        Item {
                            Layout.preferredWidth: trayIcon.status === Image.Ready ? Constants.sizeLg : 0
                            Layout.preferredHeight: Constants.sizeLg
                            Layout.alignment: Qt.AlignVCenter
                            visible: trayIcon.status === Image.Ready

                            SvgIcon {
                                id: trayIcon

                                anchors.centerIn: parent
                                iconSize: Constants.sizeLg
                                flat: true
                                iconColor: Theme.fg
                                icon: {
                                    if (!modelData || !modelData.icon)
                                        return "";

                                    try {
                                        let ic = modelData.icon;
                                        let icStr = ic.toString().trim();
                                        if (icStr === "")
                                            return "";

                                        if (icStr.indexOf("://") !== -1 || icStr.startsWith("/"))
                                            return icStr;

                                        return "image://icon/" + icStr + "?fallback=false";
                                    } catch (e) {
                                        return "";
                                    }
                                }
                            }

                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: modelData ? modelData.text : ""
                            color: (modelData && modelData.enabled) ? Theme.fg : Theme.muted
                            font.pixelSize: Constants.sizeSm
                            elide: Text.ElideRight
                        }

                        SvgIcon {
                            icon: "check"
                            visible: modelData && modelData.checkState === Qt.Checked
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs
                            flat: true
                        }

                        SvgIcon {
                            icon: "chevron-right"
                            visible: modelData && modelData.hasChildren
                            iconColor: Theme.muted
                            iconSize: Constants.sizeXs
                            flat: true
                        }

                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.border
                        visible: modelData.isSeparator
                    }

                    MouseArea {
                        id: itemMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: !modelData.isSeparator && modelData.enabled
                        onClicked: {
                            if (modelData.hasChildren) {
                                let s = menuRoot.menuStack.slice();
                                s.push(modelData);
                                menuRoot.menuStack = s;
                            } else {
                                if (typeof modelData.triggered === "function")
                                    modelData.triggered();

                                menuRoot.closeRequested();
                            }
                        }
                    }

                    transform: Translate {
                        x: itemRoot.animOffsetX
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutExpo
                        }

                    }

                    Behavior on animOffsetX {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutExpo
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

            }

        }

    }

}
