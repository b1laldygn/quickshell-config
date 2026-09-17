// services/WifiStatus.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool connected: false
    property string ssid: ""

    property Process checkProc: Process {
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev status | grep '^wifi'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (!line) {
                    root.connected = false
                    root.ssid = ""
                    return
                }
                const parts = line.split(":")
                root.connected = parts[1] === "connected"
                root.ssid = root.connected ? (parts[2] || "") : ""
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.checkProc.running = true
    }
}