// modules/weather/WeatherPanel.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: weatherWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: WeatherPanelState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WeatherPanelState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent
                focus: WeatherPanelState.visible
                Keys.onEscapePressed: WeatherPanelState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: WeatherPanelState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.leftMargin: Math.max(8, Math.min(WeatherPanelState.anchorX - width / 2, parent.width - width - 8))
                    width: Math.round(280 * s)
                    height: Math.round(230 * s)
                    radius: Math.round(14 * s)
                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transformOrigin: Item.Top
                    transform: Translate { y: fx.cardY }
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.round(16 * card.s)
                        spacing: Math.round(12 * card.s)

                        // ── Başlık ───────────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * card.s)

                            Text {
                                text: "󰍎"
                                color: Colors.accent
                                font.pixelSize: Math.round(13 * card.s)
                                font.family: "JetBrainsMono Nerd Font"
                                visible: WeatherState.cityName !== ""
                            }

                            Text {
                                text: WeatherState.cityName !== "" ? WeatherState.cityName : I18n.t("weather")
                                color: Colors.foreground
                                font.pixelSize: Math.round(13 * card.s)
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: closeHover.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * card.s)
                                }

                                MouseArea {
                                    id: closeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WeatherPanelState.visible = false
                                }
                            }
                        }

                        // ── Ana Sıcaklık Kartı ───────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Math.round(10 * card.s)
                            color: Colors.surface0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Math.round(12 * card.s)
                                spacing: Math.round(12 * card.s)

                                Text {
                                    text: WeatherState.icon
                                    color: Colors.accent
                                    font.pixelSize: Math.round(38 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(2 * card.s)

                                    Text {
                                        text: Math.round(WeatherState.tempC) + "°C"
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(24 * card.s)
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: WeatherState.condition
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(11 * card.s)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // ── 3'lü Detay Kutucukları ───────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * card.s)

                            Repeater {
                                model: [
                                    { icon: "󰔏", label: I18n.t("feelsLike"), val: Math.round(WeatherState.feelsLikeC) + "°C" },
                                    { icon: "󰖎", label: I18n.t("humidity"), val: WeatherState.humidity + "%" },
                                    { icon: "󰖝", label: I18n.t("wind"), val: Math.round(WeatherState.windKmh) + " km/h" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.round(52 * card.s)
                                    radius: Math.round(9 * card.s)
                                    color: Colors.surface0

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: Math.round(2 * card.s)

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.icon
                                            color: Colors.accent
                                            font.pixelSize: Math.round(12 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.val
                                            color: Colors.foreground
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.label
                                            color: Colors.foregroundMuted
                                            font.pixelSize: Math.round(9 * card.s)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
