// modules/weather/WeatherPanel.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            visible: WeatherPanelState.visible

            anchors { top: true; left: true }
            margins {
                top: 44
                left: Math.max(8, Math.min(WeatherPanelState.anchorX - implicitWidth / 2, modelData.width - implicitWidth - 8))
            }

            implicitWidth: 240
            implicitHeight: 220
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 6

                    Text {
                        text: WeatherState.cityName
                        color: Colors.foregroundMuted
                        font.pixelSize: 11
                        visible: text !== ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: WeatherState.icon
                            color: "#F5F5F5"
                            font.pixelSize: 36
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Math.round(WeatherState.tempC) + "°C"
                                color: "#F5F5F5"
                                font.pixelSize: 24
                                font.bold: true
                            }
                            Text {
                                text: WeatherState.condition
                                color: Colors.foregroundMuted
                                font.pixelSize: 11
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colors.border
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("feelsLike")
                            color: Colors.foregroundMuted
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Math.round(WeatherState.feelsLikeC) + "°C"
                            color: "#F5F5F5"
                            font.pixelSize: 11
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("humidity")
                            color: Colors.foregroundMuted
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                        Text {
                            text: WeatherState.humidity + "%"
                            color: "#F5F5F5"
                            font.pixelSize: 11
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.t("wind")
                            color: Colors.foregroundMuted
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Math.round(WeatherState.windKmh) + " km/s"
                            color: "#F5F5F5"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}