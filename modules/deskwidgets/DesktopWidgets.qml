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
                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
            }

            RowLayout {
                visible: WeatherState.loaded
                spacing: Math.round(12 * SettingsState.scaleFactor)

                Text {
                    text: WeatherState.icon
                    color: "#F5F5F5"
                    font.pixelSize: Math.round(34 * SettingsState.scaleFactor)
                    font.family: "JetBrainsMono Nerd Font"
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        text: Math.round(WeatherState.tempC) + "°C"
                        color: "#F5F5F5"
                        font.pixelSize: Math.round(24 * SettingsState.scaleFactor)
                        font.bold: true
                    }

                    Text {
                        text: WeatherState.condition
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                        elide: Text.ElideRight
                        Layout.maximumWidth: Math.round(150 * SettingsState.scaleFactor)
                    }
                }
            }

            Rectangle {
                visible: WeatherState.loaded
                Layout.fillWidth: true
                Layout.topMargin: Math.round(6 * SettingsState.scaleFactor)
                Layout.bottomMargin: Math.round(4 * SettingsState.scaleFactor)
                implicitHeight: 1
                color: Colors.border
            }

            RowLayout {
                visible: WeatherState.loaded
                spacing: Math.round(12 * SettingsState.scaleFactor)

                Text {
                    text: I18n.t("feelsLike") + " " + Math.round(WeatherState.feelsLikeC) + "°"
                    color: Colors.foregroundMuted
                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                }
                Text {
                    text: I18n.t("humidity") + " " + WeatherState.humidity + "%"
                    color: Colors.foregroundMuted
                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                }
                Text {
                    text: I18n.t("wind") + " " + Math.round(WeatherState.windKmh)
                    color: Colors.foregroundMuted
                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                }
            }

            Text {
                visible: !WeatherState.loaded
                text: "..."
                color: Colors.foregroundMuted
                font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
            }
        }
    }
}
