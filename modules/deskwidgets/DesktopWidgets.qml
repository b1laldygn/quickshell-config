// modules/deskwidgets/DesktopWidgets.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        DeskCard {
            property var modelData
            screen: modelData

            widgetId: "weather"
            shown: SettingsState.showDesktopWidgets
            corner: SettingsState.desktopWidgetCorner

            Text {
                visible: WeatherState.loaded && WeatherState.cityName !== ""
                text: WeatherState.cityName
                color: Colors.foregroundMuted
                font.pixelSize: 11
            }

            RowLayout {
                visible: WeatherState.loaded
                spacing: 12

                Text {
                    text: WeatherState.icon
                    color: "#F5F5F5"
                    font.pixelSize: 34
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
                        elide: Text.ElideRight
                        Layout.maximumWidth: 150
                    }
                }
            }

            Rectangle {
                visible: WeatherState.loaded
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Colors.border
            }

            RowLayout {
                visible: WeatherState.loaded
                spacing: 12

                Text {
                    text: I18n.t("feelsLike") + " " + Math.round(WeatherState.feelsLikeC) + "°"
                    color: Colors.foregroundMuted
                    font.pixelSize: 10
                }
                Text {
                    text: I18n.t("humidity") + " " + WeatherState.humidity + "%"
                    color: Colors.foregroundMuted
                    font.pixelSize: 10
                }
                Text {
                    text: I18n.t("wind") + " " + Math.round(WeatherState.windKmh)
                    color: Colors.foregroundMuted
                    font.pixelSize: 10
                }
            }

            Text {
                visible: !WeatherState.loaded
                text: "..."
                color: Colors.foregroundMuted
                font.pixelSize: 12
            }
        }
    }
}