// services/ClipboardState.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false
    property var entries: []

    property Process listProc: Process {
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0)
                root.entries = lines.map(line => {
                    const tabIndex = line.indexOf("\t")
                    const preview = tabIndex >= 0 ? line.substring(tabIndex + 1) : line
                    return { raw: line, preview: preview }
                })
            }
        }
    }

    function refresh() {
        listProc.running = true
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) refresh()
    }

    property Process selectProc: Process {
        command: []
    }

    function selectEntry(rawLine) {
        selectProc.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", rawLine]
        selectProc.running = true
        root.visible = false
    }

    property Process deleteProc: Process {
        command: []
        onExited: root.refresh()
    }

    function deleteEntry(rawLine) {
        deleteProc.command = ["sh", "-c", 'printf "%s" "$1" | cliphist delete', "_", rawLine]
        deleteProc.running = true
    }

    property Process wipeProc: Process {
        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }

    function wipeAll() {
        wipeProc.running = true
    }
}