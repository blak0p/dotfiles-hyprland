import Qt5Compat.GraphicalEffects
import QtQuick
import qs.Core

Item {
    id: root

    property alias text: textItem.text
    property alias font: textItem.font
    property alias color: textItem.color
    property alias horizontalAlignment: textItem.horizontalAlignment
    property alias verticalAlignment: textItem.verticalAlignment
    property alias wrapMode: textItem.wrapMode
    property int shadowRadius: Constants.sizeSm
    property int shadowVerticalOffset: 2

    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight

    Text {
        id: textItem

        anchors.fill: parent
        color: Theme.fg
        layer.enabled: true

        layer.effect: DropShadow {
            transparentBorder: true
            color: Theme.shadow
            radius: root.shadowRadius
            samples: root.shadowRadius * 2 + 1
            verticalOffset: root.shadowVerticalOffset
        }

    }

}
