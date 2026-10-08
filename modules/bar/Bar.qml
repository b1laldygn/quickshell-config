// modules/bar/Bar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/modules/bar"
import "root:/config"
import "root:/services"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: SettingsState.barHeight
            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, SettingsState.barOpacity / 100)

            // Sol: hızlı erişim ikonları + batarya
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                QuickToggles {}

                BatteryIndicator {
                    visible: SettingsState.showBattery && Battery.available
                }

                SystemMonitor {
                    visible: SettingsState.showSystemMonitor
                }

                WeatherWidget {
                    visible: SettingsState.showWeather && WeatherState.loaded
                }

                MediaControls {
                    id: mediaControls
                    visible: SettingsState.showMediaControls && mediaControls.hasPlayer
                }
            }

            // Orta: saat (mutlak ortalanmış)
            Clock {
                anchors.centerIn: parent
            }

            // Sağ: bildirim zili, sistem tepsisi ve workspace'ler
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                NotificationBell {
                    visible: SettingsState.showNotificationBell
                }

                SysTray {
                    trayWindow: bar
                    visible: SettingsState.showSysTray
                }

                Workspaces { screenName: bar.modelData.name }
            }
        }
    }
}