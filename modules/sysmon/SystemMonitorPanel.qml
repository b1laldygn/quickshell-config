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
            id: sysmonWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: SystemInfo.panelVisible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: SystemInfo.panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent
                focus: SystemInfo.panelVisible
                Keys.onEscapePressed: SystemInfo.panelVisible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: SystemInfo.panelVisible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.leftMargin: Math.max(8, Math.min(SystemInfo.anchorX - width / 2, parent.width - width - 8))
                    width: Math.round(320 * s)
                    height: mainCol.implicitHeight + Math.round(28 * s)
                    radius: Math.round(14 * s)
                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transformOrigin: Item.Top
                    transform: Translate { y: fx.cardY }
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        id: mainCol
                        anchors.fill: parent
                        anchors.margins: Math.round(14 * card.s)
                        spacing: Math.round(10 * card.s)

                        // ── Başlık ───────────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(8 * card.s)

                            Rectangle {
                                width: Math.round(26 * card.s)
                                height: width
                                radius: Math.round(8 * card.s)
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰻠"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            Text {
                                text: I18n.t("systemStatus")
                                color: Colors.foreground
                                font.pixelSize: Math.round(14 * card.s)
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: closeHover.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * card.s)
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

                        // ── Kullanım Çubukları ───────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: barsCol.implicitHeight + Math.round(16 * card.s)
                            radius: Math.round(10 * card.s)
                            color: Colors.surface0

                            ColumnLayout {
                                id: barsCol
                                anchors.fill: parent
                                anchors.margins: Math.round(10 * card.s)
                                spacing: Math.round(8 * card.s)

                                Repeater {
                                    model: [
                                        { label: "CPU", value: SystemInfo.cpuUsage, detail: Math.round(SystemInfo.cpuUsage * 100) + "%" },
                                        { label: "RAM", value: SystemInfo.memUsage, detail: SystemInfo.memUsedGb.toFixed(1) + " / " + SystemInfo.memTotalGb.toFixed(1) + " GB" },
                                        { label: "Swap", value: SystemInfo.swapUsage, detail: Math.round(SystemInfo.swapUsage * 100) + "%" },
                                        { label: "Disk", value: SystemInfo.diskUsage, detail: SystemInfo.diskUsed + " / " + SystemInfo.diskTotal }
                                    ]

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(3 * card.s)

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.label
                                                color: Colors.foreground
                                                font.pixelSize: Math.round(11 * card.s)
                                                font.bold: true
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: modelData.detail
                                                color: modelData.value > 0.85 ? Colors.danger : Colors.foregroundMuted
                                                font.pixelSize: Math.round(10 * card.s)
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: Math.round(6 * card.s)
                                            radius: height / 2
                                            color: Colors.hover

                                            Rectangle {
                                                width: parent.width * Math.max(0, Math.min(1, modelData.value))
                                                height: parent.height
                                                radius: height / 2
                                                color: modelData.value > 0.85 ? Colors.danger : Colors.accent

                                                Behavior on width { NumberAnimation { duration: 300 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Yük & Çalışma Süresi ─────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * card.s)

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.round(42 * card.s)
                                radius: Math.round(8 * card.s)
                                color: Colors.surface0

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Math.round(6 * card.s)
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: I18n.t("loadAvg")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(9 * card.s)
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: SystemInfo.loadAvg
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(10 * card.s)
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.round(42 * card.s)
                                radius: Math.round(8 * card.s)
                                color: Colors.surface0

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Math.round(6 * card.s)
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: I18n.t("uptime")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(9 * card.s)
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: SystemInfo.uptime
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(10 * card.s)
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // ── En Yoğun Süreçler ────────────────────────────────
                        Text {
                            text: I18n.t("topProcesses")
                            color: Colors.accent
                            font.pixelSize: Math.round(10 * card.s)
                            font.bold: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Math.round(4 * card.s)

                            Repeater {
                                model: SystemInfo.topProcesses

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.round(24 * card.s)
                                    radius: Math.round(6 * card.s)
                                    color: Colors.surface0

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(8 * card.s)
                                        anchors.rightMargin: Math.round(8 * card.s)
                                        spacing: Math.round(6 * card.s)

                                        Text {
                                            text: modelData.name
                                            color: Colors.foreground
                                            font.pixelSize: Math.round(10 * card.s)
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.cpu + "%"
                                            color: Colors.accent
                                            font.pixelSize: Math.round(10 * card.s)
                                            font.bold: true
                                        }

                                        Text {
                                            text: modelData.mem + "%"
                                            color: Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * card.s)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
