// modules/bluetooth/BluetoothList.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: btWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: BluetoothListState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: BluetoothListState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            property var devices: []
            property string busyMac: ""

            function refresh() {
                if (!pairedProc.running) pairedProc.running = true
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
                        if (connectedProc.running) connectedProc.running = false
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
                focus: BluetoothListState.visible
                Keys.onEscapePressed: BluetoothListState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: BluetoothListState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.leftMargin: Math.max(8, Math.min(BluetoothListState.anchorX - width / 2, parent.width - width - 8))
                    width: Math.round(310 * s)
                    height: Math.round(340 * s)
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
                                    text: BluetoothStatus.powered ? "󰂯" : "󰂲"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            Text {
                                text: "Bluetooth"
                                color: Colors.foreground
                                font.pixelSize: Math.round(14 * card.s)
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: Math.round(36 * card.s)
                                height: Math.round(20 * card.s)
                                radius: height / 2
                                color: BluetoothStatus.powered ? Colors.accent : Colors.surface0
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    width: Math.round(16 * card.s)
                                    height: width
                                    radius: width / 2
                                    color: "#F5F5F5"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: BluetoothStatus.powered ? parent.width - width - Math.round(2 * card.s) : Math.round(2 * card.s)
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothStatus.togglePower()
                                }
                            }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: refreshHover.containsMouse ? Colors.hover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: refreshHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: btWindow.refresh()
                                }
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
                                    onClicked: BluetoothListState.visible = false
                                }
                            }
                        }

                        // ── Cihaz Listesi ────────────────────────────────────
                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: Math.round(5 * card.s)
                            model: btWindow.devices

                            delegate: Rectangle {
                                width: listView.width
                                height: Math.round(48 * card.s)
                                radius: Math.round(9 * card.s)
                                color: modelData.connected
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                    : (devMouseArea.containsMouse ? Colors.hover : Colors.surface0)
                                border.color: modelData.connected ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(10 * card.s)
                                    anchors.rightMargin: Math.round(10 * card.s)
                                    spacing: Math.round(10 * card.s)

                                    Text {
                                        text: modelData.connected ? "󰂱" : "󰂯"
                                        color: modelData.connected ? Colors.accent : Colors.foreground
                                        font.pixelSize: Math.round(15 * card.s)
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(1 * card.s)

                                        Text {
                                            text: modelData.name
                                            color: modelData.connected ? Colors.accent : Colors.foreground
                                            font.pixelSize: Math.round(12 * card.s)
                                            font.bold: modelData.connected
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.connected ? I18n.t("connected") : I18n.t("notConnected")
                                            color: Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * card.s)
                                        }
                                    }

                                    Text {
                                        visible: btWindow.busyMac === modelData.mac
                                        text: "..."
                                        color: Colors.accent
                                        font.pixelSize: Math.round(12 * card.s)
                                        font.bold: true
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
                                text: I18n.t("noPairedDevices")
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(12 * card.s)
                                font.italic: true
                            }
                        }
                    }
                }
            }
        }
    }
}
