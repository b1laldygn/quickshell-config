// modules/bar/QuickToggles.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth
import "root:/config"
import "root:/services"

RowLayout {
    id: root
    spacing: 10

    property real currentVolume: 0.5
    property real currentBrightness: 0.5

    // ---- WIFI ----
    Rectangle {
        id: wifiBtn
        Layout.alignment: Qt.AlignVCenter
        width: 26
        height: 26
        radius: 6
        color: wifiHover.containsMouse ? Colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: WifiStatus.connected ? "󰖩" : "󰖪"
            color: "#F5F5F5"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: wifiHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    NetworkState.visible = !NetworkState.visible
                } else if (mouse.button === Qt.RightButton) {
                    wifiMenuProc.running = true
                }
            }
        }
    }

    Process {
        id: wifiMenuProc
        command: ["nm-connection-editor"]
    }

    // ---- BRIGHTNESS ----
    Item {
        id: brightnessContainer
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: brightnessIcon.width + 4 + brightnessLabel.width
        implicitHeight: 16

        Text {
            id: brightnessIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃞"
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            id: brightnessLabel
            anchors.left: brightnessIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: brightnessIcon.verticalCenter
            text: Math.round(root.currentBrightness * 100) + "%"
            color: "#cdd6f4"
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onWheel: (wheel) => {
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                root.currentBrightness = Math.max(0, Math.min(1, root.currentBrightness + delta))
                OsdService.show("brightness", root.currentBrightness)
                brightnessDebounce.restart()
            }
        }
    }

    // Scroll durduktan 150ms sonra gerçek komutu çalıştır
    Timer {
        id: brightnessDebounce
        interval: 150
        onTriggered: {
            const pct = Math.round(root.currentBrightness * 100)
            brightnessSetProc.command = ["brightnessctl", "set", pct + "%"]
            brightnessSetProc.running = true
        }
    }

    Process {
        id: brightnessSetProc
        onExited: brightnessGetProc.running = true
    }

    // Gerçek donanım değeriyle senkronize etmek için (scroll yokken de)
    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "-m", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")
                if (parts.length > 3) {
                    const newBrightness = parseInt(parts[3]) / 100
                    if (Math.abs(newBrightness - root.currentBrightness) > 0.001) {
                        root.currentBrightness = newBrightness
                        OsdService.show("brightness", newBrightness)
                    }
                }
            }
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            if (!brightnessDebounce.running) {
                brightnessGetProc.running = true
            }
        }
    }

    // ---- VOLUME (wpctl ile PipeWire/PulseAudio Kontrolü) ----
    Item {
        id: volumeContainer
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: volumeIcon.width + 4 + volumeLabel.width
        implicitHeight: 16

        Text {
            id: volumeIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰕾"
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            id: volumeLabel
            anchors.left: volumeIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: volumeIcon.verticalCenter
            text: Math.round(root.currentVolume * 100) + "%"
            color: "#cdd6f4"
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    AudioDeviceListState.visible = !AudioDeviceListState.visible
                } else if (mouse.button === Qt.MiddleButton) {
                    volumeMuteProc.running = true
                }
            }
            onWheel: (wheel) => {
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                root.currentVolume = Math.max(0, Math.min(1, root.currentVolume + delta))
                OsdService.show("volume", root.currentVolume)
                volumeDebounce.restart()
            }
        }
    }

    // Scroll durduktan 150ms sonra gerçek komutu çalıştır
    Timer {
        id: volumeDebounce
        interval: 150
        onTriggered: {
            const pct = Math.round(root.currentVolume * 100)
            volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]
            volumeSetProc.running = true
        }
    }

    Process {
        id: volumeSetProc
        onExited: {
            volumeStatusProc.running = true
            volumeMuteStatusProc.running = true
        }
    }

    // Ses Seviyesini Okuma (senkronizasyon)
    Process {
        id: volumeStatusProc
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                const match = out.match(/(\d+)%/);
                if (match && match[1]) {
                    const newVolume = parseInt(match[1]) / 100
                    if (Math.abs(newVolume - root.currentVolume) > 0.001) {
                        root.currentVolume = newVolume
                        OsdService.show("volume", newVolume)
                    }
                }
            }
        }
    }

    // Mute (Sessizlik) Durumunu Okuma
    Process {
        id: volumeMuteStatusProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const isMuted = this.text.includes("yes");
                volumeIcon.text = isMuted ? "󰝟" : "󰕾"
            }
        }
    }

    Process {
        id: volumeMuteProc
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        onExited: {
            volumeStatusProc.running = true
            volumeMuteStatusProc.running = true
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            if (!volumeDebounce.running) {
                volumeStatusProc.running = true
                volumeMuteStatusProc.running = true
            }
        }
    }

    // ---- BLUETOOTH ----
    Rectangle {
        id: btBtn
        Layout.alignment: Qt.AlignVCenter
        width: 26
        height: 26
        radius: 6
        color: btHover.containsMouse ? Colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: {
                if (!BluetoothStatus.powered) return "󰂲"
                if (BluetoothStatus.connectedCount > 0) return "󰂱"
                return "󰂯"
            }
            color: "#F5F5F5"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: btHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    BluetoothListState.visible = !BluetoothListState.visible
                } else if (mouse.button === Qt.RightButton) {
                    bluetoothMenuProc.running = true
                }
            }
        }
    }

    Process {
        id: bluetoothMenuProc
        command: ["blueman-manager"]
    }
}