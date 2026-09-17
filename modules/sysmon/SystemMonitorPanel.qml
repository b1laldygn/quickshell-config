// modules/sysmon/SystemMonitorPanel.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            visible: SystemInfo.panelVisible

            anchors { top: true; left: true }
            margins { top: 44; left: 12 }

            implicitWidth: 300
            implicitHeight: 340
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Sistem Durumu"
                        color: "#F5F5F5"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    // --- Kullanım çubukları ---
                    Repeater {
                        model: [
                            { label: "CPU", value: SystemInfo.cpuUsage, detail: Math.round(SystemInfo.cpuUsage * 100) + "%" },
                            { label: "RAM", value: SystemInfo.memUsage, detail: SystemInfo.memUsedGb.toFixed(1) + " / " + SystemInfo.memTotalGb.toFixed(1) + " GB" },
                            { label: "Swap", value: SystemInfo.swapUsage, detail: Math.round(SystemInfo.swapUsage * 100) + "%" },
                            { label: "Disk", value: SystemInfo.diskUsage, detail: SystemInfo.diskUsed + " / " + SystemInfo.diskTotal }
                        ]

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.label
                                    color: "#F5F5F5"
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.detail
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 6
                                radius: 3
                                color: Colors.surface0

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, modelData.value))
                                    height: parent.height
                                    radius: 3
                                    color: modelData.value > 0.85 ? Colors.danger : Colors.accent

                                    Behavior on width { NumberAnimation { duration: 300 } }
                                }
                            }
                        }
                    }

                    // --- Yük ortalaması + çalışma süresi ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4

                        Text {
                            text: "Yük: " + SystemInfo.loadAvg
                            color: Colors.foregroundMuted
                            font.pixelSize: 10
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: SystemInfo.uptime
                        color: Colors.foregroundMuted
                        font.pixelSize: 10
                    }

                    // --- En çok CPU kullanan süreçler ---
                    Text {
                        text: "En Yoğun Süreçler"
                        color: "#F5F5F5"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.topMargin: 6
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: SystemInfo.topProcesses

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: modelData.name
                                    color: "#F5F5F5"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.cpu + "%"
                                    color: Colors.accent
                                    font.pixelSize: 10
                                }

                                Text {
                                    text: modelData.mem + "%"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}