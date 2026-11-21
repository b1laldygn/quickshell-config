// modules/sysmon/SystemMonitorPanel.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: SystemInfo.panelVisible
            }

            anchors { top: true; left: true }
            margins {
                top: Math.round(44 * SettingsState.scaleFactor)
                left: Math.max(8, Math.min(SystemInfo.anchorX - implicitWidth / 2, modelData.width - implicitWidth - 8))
            }

            implicitWidth: Math.round(300 * SettingsState.scaleFactor)
            implicitHeight: Math.round(340 * SettingsState.scaleFactor)
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                radius: Math.round(12 * SettingsState.scaleFactor)
                opacity: fx.cardOpacity
                scale: fx.cardScale
                transformOrigin: Item.Top
                transform: Translate { y: fx.cardY }
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * SettingsState.scaleFactor)
                    spacing: Math.round(10 * SettingsState.scaleFactor)

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: I18n.t("systemStatus")
                            color: "#F5F5F5"
                            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Kapat Butonu
                        Rectangle {
                            width: Math.round(20 * SettingsState.scaleFactor)
                            height: Math.round(20 * SettingsState.scaleFactor)
                            radius: 4
                            color: closeHover.containsMouse ? Colors.hover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemInfo.panelVisible = false
                            }
                        }
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
                            spacing: Math.round(3 * SettingsState.scaleFactor)

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.label
                                    color: "#F5F5F5"
                                    font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.detail
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: Math.round(6 * SettingsState.scaleFactor)
                                radius: Math.round(3 * SettingsState.scaleFactor)
                                color: Colors.surface0

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, modelData.value))
                                    height: parent.height
                                    radius: Math.round(3 * SettingsState.scaleFactor)
                                    color: modelData.value > 0.85 ? Colors.danger : Colors.accent

                                    Behavior on width { NumberAnimation { duration: 300 } }
                                }
                            }
                        }
                    }

                    // --- Yük ortalaması + çalışma süresi ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Math.round(4 * SettingsState.scaleFactor)

                        Text {
                            text: I18n.t("loadAvg") + ": " + SystemInfo.loadAvg
                            color: Colors.foregroundMuted
                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: SystemInfo.uptime
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                    }

                    // --- En çok CPU kullanan süreçler ---
                    Text {
                        text: I18n.t("topProcesses")
                        color: "#F5F5F5"
                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                        font.bold: true
                        Layout.topMargin: Math.round(6 * SettingsState.scaleFactor)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Math.round(4 * SettingsState.scaleFactor)

                        Repeater {
                            model: SystemInfo.topProcesses

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.round(6 * SettingsState.scaleFactor)

                                Text {
                                    text: modelData.name
                                    color: "#F5F5F5"
                                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.cpu + "%"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                }

                                Text {
                                    text: modelData.mem + "%"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
