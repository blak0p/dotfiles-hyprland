import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

FloatingWindow {
    id: root

    property string popupId: ""
    property string windowTitle: ""
    default property alias content: innerLayout.data
    property color backgroundColor: Theme.opaqueBg
    property int contentPadding: Constants.sizeLg
    property bool isOpen: false
    property bool _windowVisible: false

    signal windowClosed()
    signal fullyClosed()

    title: windowTitle
    color: backgroundColor
    visible: _windowVisible
    onClosed: {
        isOpen = false;
    }
    onIsOpenChanged: {
        if (isOpen) {
            root._windowVisible = true;
        } else {
            root._windowVisible = false;
            root.windowClosed();
            root.fullyClosed();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: Constants.sizeLg

        ColumnLayout {
            id: innerLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeLg
        }

    }

}
