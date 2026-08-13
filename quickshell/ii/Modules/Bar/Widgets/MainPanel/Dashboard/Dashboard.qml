import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

RowLayout {
    id: root

    property var widget

    spacing: Constants.sizeLg

    ColumnLayout {
        Layout.alignment: Qt.AlignTop
        spacing: Constants.sizeLg
        Layout.fillWidth: true
        Layout.preferredWidth: 420
        Layout.fillHeight: true

        MiniMusicWidget {
            id: miniMusicWidget

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        UpdatesCard {
            id: updatesCard

            Layout.fillWidth: true
            Layout.fillHeight: false
        }

        QuoteWidget {
            id: quoteWidget

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

    }

}
