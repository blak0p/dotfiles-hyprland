import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Core
import qs.Core.Components

MouseArea {
    id: itemRoot

    required property SystemTrayItem modelData
    property var trayItem: modelData

    signal clicked(var mouse)

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    implicitWidth: Constants.sizeLg
    implicitHeight: Constants.sizeLg
    width: Constants.sizeLg
    height: Constants.sizeLg

    IconImage {
        id: iconImage

        anchors.centerIn: parent
        implicitSize: Constants.sizeLg
        width: Constants.sizeLg
        height: Constants.sizeLg
        source: itemRoot.trayItem ? itemRoot.trayItem.icon : ""

        scale: itemRoot.pressed ? 0.9 : (itemRoot.containsMouse ? 1.1 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    Loader {
        id: menuPopupLoader
        active: false

        sourceComponent: TrayMenuPopup {
            trayItem: itemRoot.trayItem
            anchor.window: itemRoot.QsWindow.window
            anchor.item: itemRoot

            Component.onCompleted: {
                this.visible = true;
            }
        }
    }

    onClicked: (mouse) => {
        if (!itemRoot.trayItem)
            return;

        if (mouse.button === Qt.LeftButton) {
            itemRoot.trayItem.activate();
        } else if (mouse.button === Qt.RightButton) {
            if (menuPopupLoader.active && menuPopupLoader.item && menuPopupLoader.item.visible) {
                menuPopupLoader.item.visible = false;
                menuPopupLoader.active = false;
            } else {
                menuPopupLoader.active = true;
                if (menuPopupLoader.item)
                    menuPopupLoader.item.visible = true;
            }
        } else if (mouse.button === Qt.MiddleButton) {
            if (itemRoot.trayItem.secondaryActivate)
                itemRoot.trayItem.secondaryActivate();
        }

        itemRoot.clicked(mouse);
    }
}




