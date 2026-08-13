import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    implicitHeight: mainLayout.implicitHeight
    Layout.fillWidth: true
    state: "visible"
    states: [
        State {
            name: "visible"

            PropertyChanges {
                target: quoteContainer
                opacity: 1
            }

        },
        State {
            name: "hidden"

            PropertyChanges {
                target: quoteContainer
                opacity: 0
            }

        }
    ]
    transitions: [
        Transition {
            from: "visible"
            to: "hidden"

            NumberAnimation {
                property: "opacity"
                duration: Constants.animFast
            }

        },
        Transition {
            from: "hidden"
            to: "visible"

            NumberAnimation {
                property: "opacity"
                duration: Constants.animNormal
                easing.type: Easing.OutQuad
            }

        }
    ]

    Timer {
        id: cycleTimer

        interval: Constants.animFast
        repeat: false
        onTriggered: {
            QuoteService.generateRandomQuote();
            root.state = "visible";
        }
    }

    ThemedText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: -Constants.sizeXs
        text: "“"
        font.pixelSize: 80
        font.family: Constants.fontFamily
        font.bold: true
        color: Theme.bgSecondary
    }

    MouseArea {
        id: clickArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.state === "visible") {
                root.state = "hidden";
                cycleTimer.start();
            }
        }
    }

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        spacing: 4

        ColumnLayout {
            id: quoteContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TypewriterText {
                text: "“" + QuoteService.currentQuote.text + "”"
                font.pixelSize: Constants.sizeSm + 1
                font.family: Constants.fontFamily
                font.italic: true
                color: Theme.fg
                opacity: clickArea.containsMouse ? 1 : 0.8
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                lineHeight: 1.2
                typeInterval: 20

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                    }

                }

            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                Divider {
                    implicitWidth: 12
                    Layout.fillWidth: false
                }

                TypewriterText {
                    text: QuoteService.currentQuote.author
                    font.pixelSize: Constants.sizeXs + 2
                    color: Theme.muted
                    Layout.alignment: Qt.AlignVCenter
                    typeInterval: 40

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

            }

        }

    }

}
