import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth

RowLayout {
    id: root
    spacing: 10

    // ---- WIFI ----
    Text {
        text: "󰖩"
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wifiMenuProc.running = true
        }
    }

    Process {
        id: wifiMenuProc
        command: ["nm-connection-editor"]
    }

    // ---- BRIGHTNESS ----
    RowLayout {
        spacing: 4

        Text {
            text: "󰃞"
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            id: brightnessLabel
            text: "--"
            color: "#cdd6f4"
            font.pixelSize: 11
        }

        MouseArea {
            width: 20
            height: 16
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                const step = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                brightnessSetProc.command = ["brightnessctl", "set", step]
                brightnessSetProc.running = true
            }
        }
    }

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "-m", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")
                if (parts.length > 3) brightnessLabel.text = parts[3]
            }
        }
    }

    Process {
        id: brightnessSetProc
        onExited: brightnessGetProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: brightnessGetProc.running = true
    }

    // ---- VOLUME (wpctl ile PipeWire/PulseAudio Kontrolü) ----
    RowLayout {
        spacing: 4

        Text {
            id: volumeIcon
            text: "󰕾"
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            id: volumeLabel
            text: "--"
            color: "#cdd6f4"
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                volumeMuteProc.running = true
            }
            onWheel: (wheel) => {
                const step = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", step]
                volumeSetProc.running = true
            }
        }
    }

// Ses Seviyesini Okuma
Process {
    id: volumeStatusProc
    command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            const out = this.text.trim();
            const match = out.match(/(\d+)%/); 
            if (match && match[1]) {
                volumeLabel.text = match[1] + "%";
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
            if (isMuted) {
                volumeIcon.text = "󰝟";
                volumeLabel.text = "Mute";
            } else {
                volumeIcon.text = "󰕾";
            }
        }
    }
}
Process {
    id: volumeSetProc
    onExited: {
        volumeStatusProc.running = true
        volumeMuteStatusProc.running = true
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
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
        volumeStatusProc.running = true
        volumeMuteStatusProc.running = true
    }
}

    // ---- BLUETOOTH ----
    Text {
        text: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
        color: "#cdd6f4"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        }
    }
}