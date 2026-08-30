import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property Component sourceComponent
    property bool exclusive: true
    property bool _isInternalActive: false
    property bool _isActive: exclusive ? (AppState.activePopup === popupId) : _isInternalActive
    property bool _isClosing: false

    on_IsActiveChanged: {
        if (popupId === "")
            return ;

        if (_isActive) {
            _isClosing = false;
            loader.active = true;
            if (loader.status === Loader.Ready && loader.item)
                loader.item.isOpen = true;

        } else {
            if (loader.item)
                loader.item.isOpen = false;

            _isClosing = true;
        }
    }
    Component.onCompleted: {
        if (root.popupId !== "")
            socketCleanup.running = true;

    }

    Connections {
        function onTogglePopup(id) {
            if (root.popupId !== "" && id === root.popupId) {
                if (root.exclusive) {
                    if (AppState.activePopup === id)
                        AppState.activePopup = "";
                    else
                        AppState.activePopup = id;
                } else {
                    root._isInternalActive = !root._isInternalActive;
                }
            }
        }

        function onOpenPopup(id) {
            if (root.popupId !== "" && id === root.popupId) {
                if (root.exclusive)
                    AppState.activePopup = id;
                else
                    root._isInternalActive = true;
            }
        }

        target: AppState
    }

    Loader {
        id: loader

        active: false
        sourceComponent: root.sourceComponent
        onStatusChanged: {
            if (status === Loader.Ready && root._isActive && item)
                item.isOpen = true;

        }

        Connections {
            function onFullyClosed() {
                loader.active = false;
                root._isClosing = false;
                if (!root.exclusive)
                    root._isInternalActive = false;
                else if (AppState.activePopup === root.popupId)
                    AppState.activePopup = "";
            }

            target: loader.item
        }

    }

    SocketServer {
        id: server

        path: root.popupId !== "" ? "/tmp/quickshell_" + root.popupId : ""
        active: false

        handler: Component {
            Socket {
                onConnectedChanged: {
                    if (connected) {
                        AppState.togglePopup(root.popupId);
                        connected = false;
                    }
                }
            }

        }

    }

    Process {
        id: socketCleanup

        command: ["rm", "-f", "/tmp/quickshell_" + root.popupId]
        onExited: function(exitCode) {
            if (root.popupId !== "")
                server.active = true;

        }
    }

}
