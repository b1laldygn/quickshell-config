// services/KeybindsState.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false
    property var binds: []

    property Process readProc: Process {
        command: ["sh", "-c", "cat ~/.config/hypr/hyprland-quickshell.conf"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                const result = []
                for (const rawLine of lines) {
                    const line = rawLine.trim()
                    const m = line.match(/^bind[a-z]*\s*=\s*(.+)$/)
                    if (!m) continue
                    const parts = m[1].split(",")
                    if (parts.length < 3) continue

                    let mods = parts[0].trim().replace(/\$mainMod/g, "SUPER")
                    let key = parts[1].trim()
                    let dispatcher = parts[2].trim()
                    let args = parts.slice(3).join(",").trim()

                    result.push({ mods: mods, key: key, dispatcher: dispatcher, args: args })
                }
                root.binds = result
            }
        }
    }

    function refresh() {
        readProc.running = true
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) refresh()
    }
}