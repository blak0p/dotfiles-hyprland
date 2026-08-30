import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.Core
import qs.Core.Components
import qs.Core.Services

ColumnLayout {
    id: root

    property int mode: 0 // 0 = Pomodoro, 1 = Stopwatch
    property int remaining: 25 * 60 // pomodoro seconds
    property int elapsed: 0 // stopwatch seconds
    property bool running: false
    property int session: 0

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedText {
            text: "Foco"
            font.pixelSize: Constants.sizeXl
            font.bold: true
            color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        ThemedButton {
            text: mode === 0 ? "Pomodoro" : "Cronómetro"
            onClicked: {
                root.mode = mode === 0 ? 1 : 0;
                root.running = false;
            }
        }
    }

    // Big time display
    ThemedText {
        Layout.alignment: Qt.AlignHCenter
        text: mode === 0 ? fmtPomodoro() : fmtStopwatch()
        font.pixelSize: 44
        font.bold: true
        color: Theme.fg
    }

    // Mode label
    ThemedText {
        Layout.alignment: Qt.AlignHCenter
        text: mode === 0
            ? (root.running ? ("Sesión " + (root.session % 4) + " • Concentrá" : "25 min de foco")
                )
            : (root.running ? "Contando..." : "Cronómetro listo")
        font.pixelSize: Constants.sizeSm
        color: Theme.muted
    }

    // Controls
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        ThemedButton {
            text: root.running ? "Pausar" : "Iniciar"
            onClicked: root.running = !root.running
        }

        ThemedButton {
            text: "Reiniciar"
            onClicked: {
                root.running = false;
                root.remaining = 25 * 60;
                root.elapsed = 0;
            }
        }

        ThemedButton {
            text: root.mode === 0 ? "+5 min" : "Registrar"
            visible: root.mode === 0
            onClicked: root.remaining += 5 * 60
        }
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.mode === 0) {
                root.remaining--;
                if (root.remaining <= 0) {
                    root.remaining = 25 * 60;
                    root.session++;
                }
            } else {
                root.elapsed++;
            }
        }
    }

    function fmtPomodoro(): string {
        const m = Math.floor(root.remaining / 60);
        const s = root.remaining % 60;
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }

    function fmtStopwatch(): string {
        const h = Math.floor(root.elapsed / 3600);
        const m = Math.floor((root.elapsed % 3600) / 60);
        const s = root.elapsed % 60;
        return (h > 0 ? h + ":" : "") + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }
}
