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
            id: netWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: NetworkState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: NetworkState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            property string selectedSsid: ""
            property bool showPasswordFor: false
            property bool connectFailed: false
            property var savedConnections: []

            function signalIcon(sig) {
                if (sig >= 75) return "󰤨"
                if (sig >= 50) return "󰤥"
                if (sig >= 25) return "󰤢"
                return "󰤟"
            }

            function refreshScan() {
                NetworkState.scanning = true
                if (!scanProc.running) scanProc.running = true
                if (!savedProc.running) savedProc.running = true
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
                        list.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
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
                focus: NetworkState.visible
                Keys.onEscapePressed: NetworkState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: NetworkState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.leftMargin: Math.max(8, Math.min(NetworkState.anchorX - width / 2, parent.width - width - 8))
                    width: Math.round(310 * s)
                    height: Math.round(380 * s)
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
                                    text: "󰖩"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            Text {
                                text: I18n.t("wifiNetworks")
                                color: Colors.foreground
                                font.pixelSize: Math.round(14 * card.s)
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: NetworkState.scanning
                                text: I18n.t("scanning")
                                color: Colors.accent
                                font.pixelSize: Math.round(10 * card.s)
                            }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: refreshHover.containsMouse ? Colors.hover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    color: NetworkState.scanning ? Colors.accent : Colors.foregroundMuted
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: refreshHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: netWindow.refreshScan()
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
                                    onClicked: NetworkState.visible = false
                                }
                            }
                        }

                        // ── Ağ Listesi ───────────────────────────────────────
                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: Math.round(4 * card.s)
                            model: NetworkState.networks

                            delegate: Rectangle {
                                width: listView.width
                                height: Math.round(42 * card.s)
                                radius: Math.round(9 * card.s)
                                color: modelData.inUse
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                    : (netMouseArea.containsMouse ? Colors.hover : Colors.surface0)
                                border.color: modelData.inUse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(10 * card.s)
                                    anchors.rightMargin: Math.round(10 * card.s)
                                    spacing: Math.round(8 * card.s)

                                    Text {
                                        text: netWindow.signalIcon(modelData.signal)
                                        color: modelData.inUse ? Colors.accent : Colors.foreground
                                        font.pixelSize: Math.round(14 * card.s)
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    Text {
                                        text: modelData.ssid
                                        color: modelData.inUse ? Colors.accent : Colors.foreground
                                        font.pixelSize: Math.round(12 * card.s)
                                        font.bold: modelData.inUse
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: modelData.inUse
                                        height: Math.round(18 * card.s)
                                        width: connText.implicitWidth + Math.round(10 * card.s)
                                        radius: height / 2
                                        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)

                                        Text {
                                            id: connText
                                            anchors.centerIn: parent
                                            text: I18n.t("connected")
                                            color: Colors.accent
                                            font.pixelSize: Math.round(9 * card.s)
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        visible: modelData.security !== "--"
                                        text: "󰌾"
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(11 * card.s)
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }

                                MouseArea {
                                    id: netMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.inUse) return
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

                            Text {
                                anchors.centerIn: parent
                                visible: listView.count === 0 && !NetworkState.scanning
                                text: I18n.t("noNetworks")
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(12 * card.s)
                                font.italic: true
                            }
                        }

                        // ── Şifre Alanı ──────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: netWindow.showPasswordFor
                            spacing: Math.round(6 * card.s)

                            Text {
                                visible: netWindow.connectFailed
                                text: I18n.t("connectFailedMessage")
                                color: Colors.danger
                                font.pixelSize: Math.round(10 * card.s)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.round(6 * card.s)

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Math.round(32 * card.s)
                                    radius: Math.round(8 * card.s)
                                    color: Colors.surface0
                                    border.color: passwordField.activeFocus ? Colors.accent : Colors.border
                                    border.width: 1

                                    TextInput {
                                        id: passwordField
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(10 * card.s)
                                        anchors.rightMargin: Math.round(10 * card.s)
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(12 * card.s)
                                        echoMode: TextInput.Password
                                        clip: true
                                        focus: netWindow.showPasswordFor

                                        Keys.onReturnPressed: netWindow.attemptConnectWithPassword()
                                    }

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(10 * card.s)
                                        verticalAlignment: Text.AlignVCenter
                                        text: I18n.t("passwordPlaceholder")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(12 * card.s)
                                        visible: passwordField.text.length === 0
                                    }
                                }

                                Rectangle {
                                    height: Math.round(32 * card.s)
                                    width: connectBtnText.implicitWidth + Math.round(20 * card.s)
                                    radius: Math.round(8 * card.s)
                                    color: connectBtnMouse.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)

                                    Text {
                                        id: connectBtnText
                                        anchors.centerIn: parent
                                        text: I18n.t("connect")
                                        color: connectBtnMouse.containsMouse ? Colors.accentText : Colors.accent
                                        font.pixelSize: Math.round(11 * card.s)
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: connectBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
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
