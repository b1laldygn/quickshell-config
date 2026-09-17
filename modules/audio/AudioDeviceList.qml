import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: audioWindow
            property var modelData
            screen: modelData

            visible: AudioDeviceListState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            property var sinks: []
            property var sources: []

            function refresh() { statusProc.running = true }
            onVisibleChanged: if (visible) refresh()

            function parseSection(text, sectionName, stopNames) {
                const startIdx = text.indexOf(sectionName)
                if (startIdx === -1) return []
                let endIdx = text.length
                for (const n of stopNames) {
                    const idx = text.indexOf(n, startIdx + sectionName.length)
                    if (idx !== -1 && idx < endIdx) endIdx = idx
                }
                const block = text.slice(startIdx, endIdx)
                const lines = block.split("\n")
                const devices = []
                for (const line of lines) {
                    const m = line.match(/(\*)?\s*(\d+)\.\s+(.+?)\s+\[vol:/)
                    if (m) {
                        devices.push({ id: m[2], name: m[3].trim(), isDefault: m[1] === "*" })
                    }
                }
                return devices
            }

            Process {
                id: statusProc
                command: ["wpctl", "status"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const text = this.text
                        audioWindow.sinks = audioWindow.parseSection(
                            text, "Sinks:", ["Sink endpoints:", "Sources:", "Source endpoints:", "Filters:"])
                        audioWindow.sources = audioWindow.parseSection(
                            text, "Sources:", ["Source endpoints:", "Filters:"])
                    }
                }
            }

            Process {
                id: setDefaultProc
                onExited: audioWindow.refresh()
            }

            function setDefault(id) {
                setDefaultProc.command = ["wpctl", "set-default", id]
                setDefaultProc.running = true
            }

            Item {
                anchors.fill: parent
                focus: audioWindow.visible
                Keys.onEscapePressed: audioWindow.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: audioWindow.visible = false
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 44    // NOT: bar yüksekliğine göre ayarla
                    anchors.leftMargin: 130  // NOT: ses ikonunun gerçek x konumuna göre ayarla
                    width: 300
                    height: 360
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Ses Cihazları"
                                color: "#F5F5F5"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "󰑓"
                                color: "#F5F5F5"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioWindow.refresh()
                                }
                            }
                        }

                        Text {
                            text: "Çıkış"
                            color: Colors.foregroundMuted
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Repeater {
                            model: audioWindow.sinks
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: sinkArea.containsMouse ? Colors.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8
                                    Text {
                                        text: modelData.isDefault ? "󰕾" : "󰓃"
                                        color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    Text {
                                        text: modelData.name
                                        color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: sinkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioWindow.setDefault(modelData.id)
                                }
                            }
                        }

                        Text {
                            text: "Giriş (Mikrofon)"
                            color: Colors.foregroundMuted
                            font.pixelSize: 10
                            font.bold: true
                            Layout.topMargin: 6
                        }

                        Repeater {
                            model: audioWindow.sources
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: sourceArea.containsMouse ? Colors.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8
                                    Text {
                                        text: "󰍬"
                                        color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    Text {
                                        text: modelData.name
                                        color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: sourceArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioWindow.setDefault(modelData.id)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}