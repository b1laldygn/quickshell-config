// modules/bar/SystemMonitor.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: root
    implicitWidth: content.implicitWidth + Math.round(12 * SettingsState.scaleFactor)
    implicitHeight: Math.round(26 * SettingsState.scaleFactor)
    radius: Math.round(6 * SettingsState.scaleFactor)
    color: hoverArea.containsMouse || SystemInfo.panelVisible ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(8 * SettingsState.scaleFactor)

        RowLayout {
            spacing: Math.round(3 * SettingsState.scaleFactor)

            Text {
                text: "󰻠"
                color: "#F5F5F5"
                font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                text: Math.round(SystemInfo.cpuUsage * 100) + "%"
                color: SystemInfo.cpuUsage > 0.85 ? Colors.danger : "#F5F5F5"
                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
            }
        }

        RowLayout {
            spacing: Math.round(3 * SettingsState.scaleFactor)

            Text {
                text: "󰍛"
                color: "#F5F5F5"
                font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                text: Math.round(SystemInfo.memUsage * 100) + "%"
                color: SystemInfo.memUsage > 0.85 ? Colors.danger : "#F5F5F5"
                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const pos = root.mapToItem(null, root.width / 2, root.height)
            SystemInfo.anchorX = pos.x
            SystemInfo.togglePanel()
        }
    }
}
