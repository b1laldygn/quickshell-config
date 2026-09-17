// modules/bar/SystemMonitor.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: root
    implicitWidth: content.implicitWidth + 12
    implicitHeight: 26
    radius: 6
    color: hoverArea.containsMouse || SystemInfo.panelVisible ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 8

        RowLayout {
            spacing: 3

            Text {
                text: "󰻠"
                color: "#F5F5F5"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                text: Math.round(SystemInfo.cpuUsage * 100) + "%"
                color: SystemInfo.cpuUsage > 0.85 ? Colors.danger : "#F5F5F5"
                font.pixelSize: 11
            }
        }

        RowLayout {
            spacing: 3

            Text {
                text: "󰍛"
                color: "#F5F5F5"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                text: Math.round(SystemInfo.memUsage * 100) + "%"
                color: SystemInfo.memUsage > 0.85 ? Colors.danger : "#F5F5F5"
                font.pixelSize: 11
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SystemInfo.togglePanel()
    }
}