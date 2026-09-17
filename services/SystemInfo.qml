// services/SystemInfo.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // --- Hafif metrikler (sürekli) ---
    property real cpuUsage: 0        // 0.0 - 1.0
    property real memUsage: 0        // 0.0 - 1.0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real swapUsage: 0
    property string loadAvg: "-"

    // --- Ağır metrikler (sadece panel açıkken) ---
    property bool panelVisible: false
    property var topProcesses: []
    property string diskUsed: "-"
    property string diskTotal: "-"
    property real diskUsage: 0
    property string uptime: "-"

    // CPU delta hesabı için önceki okuma
    property real prevTotal: 0
    property real prevIdle: 0

    property Process quickProc: Process {
        command: ["sh", "-c",
            "awk '/^cpu /{t=0; for(i=2;i<=NF;i++) t+=$i; print \"CPU\", t, $5+$6; exit}' /proc/stat; " +
            "awk '/^MemTotal:|^MemAvailable:|^SwapTotal:|^SwapFree:/{print $1, $2}' /proc/meminfo; " +
            "awk '{print \"LOAD\", $1, $2, $3}' /proc/loadavg"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                let memTotal = 0, memAvail = 0, swapTotal = 0, swapFree = 0

                for (const line of lines) {
                    const parts = line.trim().split(/\s+/)
                    if (parts[0] === "CPU") {
                        const total = parseFloat(parts[1])
                        const idle = parseFloat(parts[2])
                        if (root.prevTotal > 0) {
                            const dTotal = total - root.prevTotal
                            const dIdle = idle - root.prevIdle
                            if (dTotal > 0) {
                                root.cpuUsage = Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal))
                            }
                        }
                        root.prevTotal = total
                        root.prevIdle = idle
                    } else if (parts[0] === "MemTotal:") {
                        memTotal = parseFloat(parts[1])
                    } else if (parts[0] === "MemAvailable:") {
                        memAvail = parseFloat(parts[1])
                    } else if (parts[0] === "SwapTotal:") {
                        swapTotal = parseFloat(parts[1])
                    } else if (parts[0] === "SwapFree:") {
                        swapFree = parseFloat(parts[1])
                    } else if (parts[0] === "LOAD") {
                        root.loadAvg = parts[1] + "  " + parts[2] + "  " + parts[3]
                    }
                }

                if (memTotal > 0) {
                    root.memUsage = (memTotal - memAvail) / memTotal
                    root.memUsedGb = (memTotal - memAvail) / 1048576
                    root.memTotalGb = memTotal / 1048576
                }
                if (swapTotal > 0) {
                    root.swapUsage = (swapTotal - swapFree) / swapTotal
                }
            }
        }
    }

    property Timer quickTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.quickProc.running = true
    }

    // --- Detaylı bilgiler, sadece panel açıkken ---
    property Process detailProc: Process {
        command: ["sh", "-c",
            "ps -eo comm=,pcpu=,pmem= --sort=-pcpu | head -5 | awk '{print \"PROC\", $1, $2, $3}'; " +
            "df -P / | awk 'NR==2{print \"DISK\", $3, $2, $5}'; " +
            "echo \"UP $(uptime -p 2>/dev/null || uptime)\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                const procs = []

                for (const line of lines) {
                    const parts = line.trim().split(/\s+/)
                    if (parts[0] === "PROC") {
                        procs.push({
                            name: parts[1] || "",
                            cpu: parts[2] || "0",
                            mem: parts[3] || "0"
                        })
                    } else if (parts[0] === "DISK") {
                        root.diskUsed = Math.round(parseFloat(parts[1]) / 1048576) + " GB"
                        root.diskTotal = Math.round(parseFloat(parts[2]) / 1048576) + " GB"
                        root.diskUsage = parseFloat(parts[3]) / 100
                    } else if (parts[0] === "UP") {
                        root.uptime = line.substring(3).trim()
                    }
                }
                root.topProcesses = procs
            }
        }
    }

    property Timer detailTimer: Timer {
        interval: 3000
        running: root.panelVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.detailProc.running = true
    }

    function togglePanel() {
        root.panelVisible = !root.panelVisible
    }
}