// services/BluetoothStatus.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool powered: false
    property int connectedCount: 0

    property Process checkProc: Process {
        command: [
            "sh", "-c",
            "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off; bluetoothctl devices Connected 2>/dev/null | wc -l"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.powered = lines[0] === "on"
                root.connectedCount = parseInt(lines[1]) || 0
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.checkProc.running = true
    }

    property Process toggleProc: Process {
        command: []
        onExited: root.checkProc.running = true   // toggle sonrası hemen tazele
    }

    function togglePower() {
        toggleProc.command = ["bluetoothctl", "power", root.powered ? "off" : "on"]
        toggleProc.running = true
    }
}