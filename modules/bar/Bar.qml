// modules/bar/Bar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/modules/bar"
import "root:/config"

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
            implicitHeight: 34
            color: Colors.background

            // Sol: hızlı erişim ikonları + batarya
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                QuickToggles {}
                BatteryIndicator {}
                SystemMonitor {}
                MediaControls {}
            }
            // Orta: saat (mutlak ortalanmış)
            Clock {
                anchors.centerIn: parent
            }

            // Sağ: Sistem tepsisi (SysTray) ve Workspace'ler
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                NotificationBell {}
                SysTray { trayWindow: bar }
                Workspaces { screenName: bar.modelData.name }
            }
        }
    }
}