import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Card {
    id: root

    property bool active: false
    implicitHeight: contentLayout.implicitHeight + Constants.sizeLg * 2

    onActiveChanged: {
        CodexBar.popupOpen = root.active;
        if (root.active)
            CodexBar.refresh();
    }

    Component.onDestruction: CodexBar.popupOpen = false

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true

            ThemedText {
                text: Translation.tr("Codex")
                font.pixelSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ThemedButton {
                text: Translation.tr("Refresh")
                onClicked: CodexBar.refresh()
            }
        }

        Divider {}

        ThemedText {
            Layout.fillWidth: true
            text: CodexBar.accountEmail.length > 0 ? CodexBar.accountEmail : Translation.tr("Codex account")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true

            ThemedText {
                text: Translation.tr("Weekly Usage")
                font.bold: true
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ThemedText {
                text: CodexBar.weeklyRemainingPercent >= 0 ? Math.round(CodexBar.weeklyRemainingPercent) + "%" : "--"
                color: Theme.accent
                font.bold: true
            }
        }

        ThemedText {
            Layout.fillWidth: true
            text: CodexBar.weeklyTimeRemaining.length > 0 ? Translation.tr("Time left:") + " " + CodexBar.weeklyTimeRemaining : Translation.tr("Waiting for usage data...")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
        }

        RowLayout {
            visible: CodexBar.hasPrimary
            Layout.fillWidth: true

            ThemedText {
                text: Translation.tr("Session")
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ThemedText {
                text: Math.round(CodexBar.primaryRemainingPercent) + "%"
                color: Theme.accentComplementary
            }
        }

        RowLayout {
            visible: CodexBar.creditsRemaining > 0 || CodexBar.resetCreditsAvailable > 0
            Layout.fillWidth: true

            ThemedText {
                text: Translation.tr("Credits")
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ThemedText {
                text: (CodexBar.creditsRemaining + CodexBar.resetCreditsAvailable).toString()
                color: Theme.accent
            }
        }

        ThemedText {
            Layout.fillWidth: true
            visible: CodexBar.hasError || CodexBar.statusDescription.length > 0
            text: CodexBar.hasError ? Translation.tr("Could not fetch data") : CodexBar.statusDescription
            color: CodexBar.hasError ? "#ef4444" : Theme.muted
            wrapMode: Text.WordWrap
        }
    }
}
