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
                top: Math.round(44 * SettingsState.scaleFactor)
                right: Math.round(12 * SettingsState.scaleFactor)
            }

            implicitWidth: Math.round(340 * SettingsState.scaleFactor)
            implicitHeight: column.implicitHeight
            color: "transparent"

            WlrLayershell.exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Overlay

            ColumnLayout {
                id: column
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Math.round(8 * SettingsState.scaleFactor)
                width: Math.round(340 * SettingsState.scaleFactor)

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
