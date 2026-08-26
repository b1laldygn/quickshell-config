pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property real cpuUsage: 0
    property real memUsage: 0

    property Process cpuProc: Process {
        command: ["sh", "-c", "top -bn1 | grep Cpu | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuUsage = parseFloat(this.text) || 0
        }
    }

    property Timer cpuTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.cpuProc.running = true
    }
}