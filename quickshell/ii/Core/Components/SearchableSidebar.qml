import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property string searchPlaceholder: "Search..."
    property string searchText: searchBar.text
    default property alias content: scrollContent.data
    property Component headerComponent: null
    property bool showSearch: true

    signal searchRequested(string text)

    Layout.preferredWidth: 260
    Layout.maximumWidth: 260
    Layout.minimumWidth: 260
    Layout.fillHeight: true
    color: Theme.bgSecondary

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeLg

        Loader {
            Layout.fillWidth: true
            sourceComponent: root.headerComponent
            visible: root.headerComponent !== null
        }

        ThemedSearchBar {
            id: searchBar

            visible: root.showSearch
            placeholderText: root.searchPlaceholder
            onSearchRequested: function(text) {
                root.searchRequested(text);
            }
            Layout.fillWidth: true
        }

        Shortcut {
            sequence: "Ctrl+K"
            enabled: root.showSearch
            onActivated: searchBar.forceActiveFocus()
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: scrollContent.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: scrollContent

                width: parent.width
            }

        }

    }

}
