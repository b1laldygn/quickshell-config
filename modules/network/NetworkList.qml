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
            id: netWindow
            property var modelData
            screen: modelData

            visible: NetworkState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            property string selectedSsid: ""
            property bool showPasswordFor: false
            property bool connectFailed: false
            property var savedConnections: []

            function refreshScan() {
                NetworkState.scanning = true
                scanProc.running = true
                savedProc.running = true
            }

            function attemptConnect() {
                const isSaved = netWindow.savedConnections.includes(netWindow.selectedSsid)
                connectProc.command = isSaved
                    ? ["nmcli", "connection", "up", netWindow.selectedSsid]
                    : ["nmcli", "device", "wifi", "connect", netWindow.selectedSsid]
                netWindow.connectFailed = false
                connectProc.running = true
            }

            function attemptConnectWithPassword() {
                connectProc.command = ["nmcli", "device", "wifi", "connect", netWindow.selectedSsid, "password", passwordField.text]
                netWindow.connectFailed = false
                connectProc.running = true
                netWindow.showPasswordFor = false
                passwordField.text = ""
            }

            onVisibleChanged: {
                if (visible) {
                    refreshScan()
                } else {
                    passwordField.text = ""
                    showPasswordFor = false
                    connectFailed = false
                }
            }

            Process {
                id: scanProc
                command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", "yes"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = this.text.trim().split("\n").filter(l => l.length > 0)
                        const seen = new Set()
                        const list = []
                        for (const line of lines) {
                            const parts = line.split(":")
                            const ssid = parts[0]
                            if (!ssid || seen.has(ssid)) continue
                            seen.add(ssid)
                            list.push({
                                ssid,
                                security: parts[1],
                                signal: parseInt(parts[2]) || 0,
                                inUse: parts[3] === "*"
                            })
                        }
                        list.sort((a, b) => b.signal - a.signal)
                        NetworkState.networks = list
                        NetworkState.scanning = false
                    }
                }
            }

            Process {
                id: savedProc
                command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        netWindow.savedConnections = this.text.trim().split("\n").filter(l => l.length > 0)
                    }
                }
            }

            Process {
                id: connectProc
                onExited: (exitCode) => {
                    if (exitCode !== 0) {
                        // Kayıtlı bağlantı denemesi başarısız olduysa (örn. şifre değişmiş),
                        // kullanıcıya şifre alanını aç ki tekrar deneyebilsin.
                        netWindow.connectFailed = true
                        netWindow.showPasswordFor = true
                    } else {
                        netWindow.connectFailed = false
                    }
                    netWindow.refreshScan()
                }
            }

            Item {
                anchors.fill: parent
                focus: netWindow.visible
                Keys.onEscapePressed: netWindow.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: netWindow.visible = false
    }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 44   // NOT: bar yüksekliğine göre ayarla
                    anchors.leftMargin: 10
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
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Wi-Fi Ağları"
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
                                    onClicked: netWindow.refreshScan()
                                }
                            }
                        }

                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: NetworkState.networks

                            delegate: Rectangle {
                                width: listView.width
                                height: 40
                                radius: 8
                                color: netMouseArea.containsMouse ? Colors.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: "󰖩"
                                        color: modelData.inUse ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    Text {
                                        text: modelData.ssid
                                        color: modelData.inUse ? Colors.accent : "#F5F5F5"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.inUse ? "Bağlı" : ""
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 10
                                        font.italic: true
                                    }
                                    Text {
                                        text: modelData.security !== "--" ? "󰌾" : ""
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }

                                MouseArea {
                                    id: netMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.inUse) {
                                            return // zaten bağlı, bir şey yapma
                                        }
                                        netWindow.selectedSsid = modelData.ssid
                                        netWindow.showPasswordFor = false
                                        netWindow.connectFailed = false

                                        const isOpen = modelData.security === "--"
                                        const isSaved = netWindow.savedConnections.includes(modelData.ssid)

                                        if (isOpen || isSaved) {
                                            netWindow.attemptConnect()
                                        } else {
                                            netWindow.showPasswordFor = true
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: netWindow.showPasswordFor
                            spacing: 4

                            Text {
                                visible: netWindow.connectFailed
                                text: "Bağlanılamadı, şifreyi kontrol edin"
                                color: "#f38ba8"
                                font.pixelSize: 10
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                TextInput {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    height: 30
                                    color: "#F5F5F5"
                                    font.pixelSize: 12
                                    echoMode: TextInput.Password
                                    clip: true
                                    focus: netWindow.showPasswordFor

                                    Keys.onReturnPressed: netWindow.attemptConnectWithPassword()
                                }

                                Text {
                                    text: "Bağlan"
                                    color: Colors.accent
                                    font.pixelSize: 12
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: netWindow.attemptConnectWithPassword()
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