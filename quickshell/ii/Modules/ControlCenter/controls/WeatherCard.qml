// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W E A T H E R   C A R D                                                │
// │   weather · now and atmospheric conditions                               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import "../theme"
import "../services"
import "../components"

Card {
    id: root

    property int cols: 2
    property int rows: 3
    padding: 12

    readonly property bool oneLine: root.rows <= 1

    readonly property string labelFeelsLike: (typeof Translation !== "undefined" && Translation.currentLocale === "es_MX")
        ? "Sensación"
        : (typeof Translation !== "undefined" ? Translation.tr("Feels like") : "Sensación")
    readonly property string labelHumidity: typeof Translation !== "undefined" ? Translation.tr("Humidity") : "Humedad"
    readonly property string labelWind: typeof Translation !== "undefined" ? Translation.tr("Wind") : "Viento"
    readonly property string labelUvIndex: typeof Translation !== "undefined" ? Translation.tr("UV Index") : "Índice UV"

    Component.onCompleted: WeatherService.subscribe()
    Component.onDestruction: WeatherService.release()

    // ── 1-LINE COMPACT VIEW ─────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        visible: root.oneLine
        spacing: 10

        Text {
            text: WeatherService.available ? (WeatherService.glyph || "󰖌") : "󰖌"
            font.family: Theme.fontMono
            font.pixelSize: 22
            color: Theme.text
        }

        Text {
            text: WeatherService.available ? `${WeatherService.temperature}°C` : "—"
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.bold: true
            color: Theme.text
        }

        Text {
            Layout.fillWidth: true
            text: WeatherService.available
                ? `${root.labelFeelsLike} ${WeatherService.feelsLike}°C  ·  ${WeatherService.place}`
                : "No reading"
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textMuted
        }

        Text {
            visible: WeatherService.available
            text: `󰖌 ${WeatherService.humidity}%`
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeLabel
            color: Theme.textMuted
        }
    }

    // ── FULL WEATHER CARD ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        visible: !root.oneLine
        spacing: 12

        // ── TOP HEADER ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Left: circular badge + temp/feels
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    radius: 23
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: WeatherService.available ? (WeatherService.glyph || "󰖌") : "󰖌"
                        font.family: Theme.fontMono
                        font.pixelSize: 24
                        color: Theme.text
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: WeatherService.available
                            ? `${WeatherService.temperature}°C`
                            : "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        text: WeatherService.available
                            ? `${root.labelFeelsLike} ${WeatherService.feelsLike}°C`
                            : "Sin datos"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.textMuted
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: city name + refresh button, and below: humidity indicator
            ColumnLayout {
                spacing: 3
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 6

                    Text {
                        text: WeatherService.available && WeatherService.place !== ""
                            ? WeatherService.place
                            : (SettingsService.weatherPlace.trim() || "—")
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.maximumWidth: 200
                    }

                    Rectangle {
                        id: refreshBtn
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 12
                        color: refreshMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                        scale: refreshMouse.pressed ? 0.88 : (refreshMouse.containsMouse ? 1.1 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Text {
                            id: refreshIcon
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: refreshMouse.containsMouse ? Theme.fg : Theme.textMuted
                            rotation: 0

                            RotationAnimator {
                                id: spinAnim
                                target: refreshIcon
                                from: 0
                                to: 360
                                duration: 700
                                loops: WeatherService.query.running ? Animation.Infinite : 1
                                running: WeatherService.query.running
                            }
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                spinAnim.restart()
                                WeatherService.refresh()
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: WeatherService.available
                        ? `${root.labelHumidity}: ${WeatherService.humidity}%`
                        : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }
            }
        }

        // ── BOTTOM 3 STAT CHIPS ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // 1. Humedad
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: "󰖌"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.text
                        }

                        Text {
                            text: root.labelHumidity
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: WeatherService.available ? `${WeatherService.humidity}%` : "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.text
                    }
                }
            }

            // 2. Viento
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: "󰖝"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.text
                        }

                        Text {
                            text: root.labelWind
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: WeatherService.available ? `${WeatherService.wind} km/h` : "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.text
                    }
                }
            }

            // 3. Índice UV
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: "󰍦"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.text
                        }

                        Text {
                            text: root.labelUvIndex
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: WeatherService.available ? `UV ${WeatherService.uv}` : "UV —"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.text
                    }
                }
            }
        }
    }
}
