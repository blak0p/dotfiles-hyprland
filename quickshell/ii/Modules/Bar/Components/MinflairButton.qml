import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

BarButton {
    id: root

    AnimatedMinflair {
        id: minflair

        anchors.centerIn: parent
        iconSize: Constants.size3Xl
        scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.1 : 1)

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.widget)
                    root.widget.isOpen = !root.widget.isOpen;

            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuads
            }

        }

    }

}
