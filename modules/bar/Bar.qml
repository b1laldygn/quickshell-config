// modules/bar/Bar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/modules/bar"
import "root:config"

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

            // Sol: hızlı erişim ikonları
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                QuickToggles {}
            }

            // Orta: saat (mutlak ortalanmış, sol/sağ içerikten bağımsız)
            Clock {
                anchors.centerIn: parent
            }

            // Sağ: workspace'ler
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Workspaces { screenName: bar.modelData.name }
            }
        }
    }
}