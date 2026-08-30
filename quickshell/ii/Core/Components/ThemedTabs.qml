import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Item {
    id: root

    property var activeValue
    default property alias tabs: rowLayout.data
    property color activeColor: activeTab ? activeTab.activeColor : Theme.accent
    property real indicatorHeight: 2
    property real indicatorWidth: Constants.size5Xl
    property Item activeTab: null

    signal tabSelected(var value)

    function updateActiveTab() {
        let found = null;
        for (let i = 0; i < rowLayout.children.length; i++) {
            let child = rowLayout.children[i];
            if (child.value !== undefined) {
                child.isActive = (child.value === root.activeValue);
                if (child.isActive)
                    found = child;

            }
        }
        root.activeTab = found;
    }

    implicitHeight: Constants.size2Xl * 1.5
    implicitWidth: rowLayout.implicitWidth
    onActiveValueChanged: updateActiveTab()
    Component.onCompleted: updateActiveTab()

    Connections {
        function onChildrenChanged() {
            root.updateActiveTab();
        }

        target: rowLayout
    }

    Divider {
        anchors.bottom: parent.bottom
        width: parent.width
    }

    Rectangle {
        id: indicator

        z: 3
        anchors.bottom: parent.bottom
        height: root.indicatorHeight
        radius: height / 2
        x: root.activeTab ? root.activeTab.x + (root.activeTab.width - width) / 2 : 0
        width: root.activeTab ? Math.min(root.activeTab.width, root.indicatorWidth) : 0
        color: root.activeColor

        Behavior on x {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

        }

        Behavior on width {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    RowLayout {
        id: rowLayout

        z: 2
        anchors.fill: parent
        spacing: 0
    }

}
