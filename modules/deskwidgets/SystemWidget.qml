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
        spacing: Math.round(3 * SettingsState.scaleFactor)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: row.label
                color: "#F5F5F5"
                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                font.bold: true
                Layout.fillWidth: true
            }
            Text {
                text: row.detail
                color: Colors.foregroundMuted
                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(6 * SettingsState.scaleFactor)
            radius: Math.round(3 * SettingsState.scaleFactor)
            color: Colors.surface0

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, row.value))
                height: parent.height
                radius: Math.round(3 * SettingsState.scaleFactor)
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
                font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                font.bold: true
                Layout.bottomMargin: Math.round(6 * SettingsState.scaleFactor)
            }

            UsageRow {
                label: "CPU"
                value: SystemInfo.cpuUsage
                detail: Math.round(SystemInfo.cpuUsage * 100) + "%"
            }

            UsageRow {
                Layout.topMargin: Math.round(4 * SettingsState.scaleFactor)
                label: "RAM"
                value: SystemInfo.memUsage
                detail: SystemInfo.memUsedGb.toFixed(1) + " / " + SystemInfo.memTotalGb.toFixed(1) + " GB"
            }

            UsageRow {
                Layout.topMargin: Math.round(4 * SettingsState.scaleFactor)
                label: "Disk"
                value: SystemInfo.diskUsage
                detail: SystemInfo.diskUsed + " / " + SystemInfo.diskTotal
            }

            Text {
                Layout.topMargin: Math.round(8 * SettingsState.scaleFactor)
                text: SystemInfo.uptime
                color: Colors.foregroundMuted
                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
            }
        }
    }
}
