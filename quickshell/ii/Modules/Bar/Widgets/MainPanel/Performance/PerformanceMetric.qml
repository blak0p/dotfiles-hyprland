import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: root

    property string label: ""
    property string value: ""

    spacing: 2

    ThemedText {
        text: root.label.toUpperCase()
        font.pixelSize: Constants.sizeXs
        font.bold: true
        color: Theme.muted
    }

    ThemedText {
        text: root.value
        font.pixelSize: Constants.sizeSm + 2
        font.weight: Font.Medium
        color: Theme.fg
    }

}
