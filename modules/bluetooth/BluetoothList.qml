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
            id: btWindow
            property var modelData
            screen: modelData

            visible: BluetoothListState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            property var devices: []
            property string busyMac: ""

            function refresh() {
                pairedProc.running = true
            }

            onVisibleChanged: if (visible) refresh()

            Process {
                id: pairedProc
                command: ["bluetoothctl", "devices", "Paired"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = this.text.trim().split("\n").filter(l => l.length > 0)
                        const parsed = lines.map(line => {
                            const parts = line.split(" ")
                            const mac = parts[1]
                            const name = parts.slice(2).join(" ")
                            return { mac, name, connected: false }
                        })
                        btWindow.devices = parsed
                        connectedProc.running = true
                    }
                }
            }

            Process {
    id: connectedProc
    command: ["bluetoothctl", "devices", "Connected"]
    stdout: StdioCollector {
        onStreamFinished: {
            const lines = this.text.trim().split("\n").filter(l => l.length > 0)
            const connectedMacs = new Set(lines.map(l => l.split(" ")[1]))
            btWindow.devices = btWindow.devices.map(d => {
                return { mac: d.mac, name: d.name, connected: connectedMacs.has(d.mac) }
            })
        }
    }
}

            Process {
                id: actionProc
                onExited: {
                    btWindow.busyMac = ""
                    btWindow.refresh()
                }
            }

            function toggleConnection(device) {
                busyMac = device.mac
                actionProc.command = device.connected
                    ? ["bluetoothctl", "disconnect", device.mac]
                    : ["bluetoothctl", "connect", device.mac]
                actionProc.running = true
            }

            Item {
                anchors.fill: parent
                focus: btWindow.visible
                Keys.onEscapePressed: BluetoothListState.visible = false   // önce: btWindow.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: BluetoothListState.visible = false           // önce: btWindow.visible = false
    }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 44    // NOT: bar yüksekliğine göre ayarla
                    anchors.leftMargin: 180  // NOT: bluetooth ikonunun gerçek x konumuna göre ayarla
                    width: 300
                    height: 320
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Bluetooth"
                                color: "#F5F5F5"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 36; height: 20
                                radius: 10
                                color: BluetoothStatus.powered ? Colors.accent : Colors.surface0
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    width: 16; height: 16
                                    radius: 8
                                    color: "#F5F5F5"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: BluetoothStatus.powered ? parent.width - width - 2 : 2
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothStatus.togglePower()
                                }
                            }

                            Text {
                                text: "󰑓"
                                color: "#F5F5F5"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: btWindow.refresh()
                                }
                            }
                        }

                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: btWindow.devices

                            delegate: Rectangle {
                                width: listView.width
                                height: 44
                                radius: 8
                                color: devMouseArea.containsMouse ? Colors.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: modelData.connected ? "󰂱" : "󰂯"
                                        color: modelData.connected ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 14
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            text: modelData.name
                                            color: modelData.connected ? Colors.accent : "#F5F5F5"
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.connected ? "Bağlı" : "Bağlı değil"
                                            color: Colors.foregroundMuted
                                            font.pixelSize: 10
                                        }
                                    }

                                    Text {
                                        visible: btWindow.busyMac === modelData.mac
                                        text: "..."
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: devMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: btWindow.busyMac === ""
                                    onClicked: btWindow.toggleConnection(modelData)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: listView.count === 0
                                text: "Eşlenmiş cihaz yok"
                                color: Colors.foregroundMuted
                                font.pixelSize: 12
                                font.italic: true
                            }
                        }
                    }
                }
            }
        }
    }
}