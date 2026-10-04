// modules/deskwidgets/SystemWidget.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    component UsageRow: ColumnLayout {
        id: row
        property string label: ""
        property real value: 0
        property string detail: ""

        Layout.fillWidth: true
        spacing: 3

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: row.label
                color: "#F5F5F5"
                font.pixelSize: 11
                font.bold: true
                Layout.fillWidth: true
            }
            Text {
                text: row.detail
                color: Colors.foregroundMuted
                font.pixelSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Colors.surface0

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, row.value))
                height: parent.height
                radius: 3
                color: row.value > 0.85 ? Colors.danger : Colors.accent
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        DeskCard {
            property var modelData
            screen: modelData

            widgetId: "system"
            shown: SettingsState.showSystemWidget
            corner: SettingsState.systemWidgetCorner

            Text {
                text: I18n.t("systemStatus")
                color: "#F5F5F5"
                font.pixelSize: 14
                font.bold: true
                Layout.bottomMargin: 6
            }

            UsageRow {
                label: "CPU"
                value: SystemInfo.cpuUsage
                detail: Math.round(SystemInfo.cpuUsage * 100) + "%"
            }

            UsageRow {
                Layout.topMargin: 4
                label: "RAM"
                value: SystemInfo.memUsage
                detail: SystemInfo.memUsedGb.toFixed(1) + " / " + SystemInfo.memTotalGb.toFixed(1) + " GB"
            }

            UsageRow {
                Layout.topMargin: 4
                label: "Disk"
                value: SystemInfo.diskUsage
                detail: SystemInfo.diskUsed + " / " + SystemInfo.diskTotal
            }

            Text {
                Layout.topMargin: 8
                text: SystemInfo.uptime
                color: Colors.foregroundMuted
                font.pixelSize: 10
            }
        }
    }
}