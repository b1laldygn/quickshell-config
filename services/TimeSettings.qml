// services/TimeSettings.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var timezones: []
    property string currentTimezone: ""
    property bool ntpEnabled: false
    property bool busy: false
    property string message: ""

    property Process listProc: Process {
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.timezones = this.text.trim().split("\n").filter(l => l.length > 0)
        }
    }

    property Process infoProc: Process {
        command: ["timedatectl", "show", "-p", "Timezone", "-p", "NTP"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.trim().split("\n")) {
                    const i = line.indexOf("=")
                    if (i < 0) continue
                    const key = line.slice(0, i)
                    const val = line.slice(i + 1)
                    if (key === "Timezone") root.currentTimezone = val
                    else if (key === "NTP") root.ntpEnabled = (val === "yes")
                }
            }
        }
    }

    // Çıktı "çıkışKodu|mesaj" biçiminde gelir
    property Process setProc: Process {
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                const sep = t.indexOf("|")
                const code = parseInt(t.slice(0, sep))
                const msg = t.slice(sep + 1).trim()
                root.busy = false
                root.message = code === 0 ? "" : (msg || "timedatectl error")
                root.refresh()
            }
        }
    }

    function refresh() {
        infoProc.running = true
        if (root.timezones.length === 0) listProc.running = true
    }

    function run(args) {
        if (root.busy) return
        root.busy = true
        root.message = ""
        setProc.command = ["sh", "-c", 'out=$(timedatectl "$@" 2>&1); echo "$?|$out"', "_"].concat(args)
        setProc.running = true
    }

    function setTimezone(tz) { run(["set-timezone", tz]) }
    function setNtp(on) { run(["set-ntp", on ? "true" : "false"]) }
}