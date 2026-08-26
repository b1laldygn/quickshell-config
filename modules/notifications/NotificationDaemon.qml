// modules/notifications/NotificationDaemon.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }
            margins {
                top: 44   // bar yüksekliğinin altından başlasın
                right: 12
            }

            implicitWidth: 320
            implicitHeight: column.implicitHeight
            color: "transparent"

            // WlrLayershell exclusiveZone: -1 -> diğer pencerelerden yer çalmasın
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Overlay

            ColumnLayout {
                id: column
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8
                width: 320

                Repeater {
                    model: NotificationService.notifications

                    NotificationPopup {
                        notification: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}