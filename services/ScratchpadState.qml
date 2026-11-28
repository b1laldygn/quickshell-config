// services/ScratchpadState.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    property bool visible: false
    property bool loading: false
    property var items: []
    readonly property int count: items.length
    property string activeTitle: ""
    property string activeAddress: ""
    property string _lastItemsJson: "[]"
    property bool _pendingRefresh: false

    property Connections hyprConn: Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const n = ev.name
            if (n === "movewindow" || n === "movewindowv2" || n === "openwindow" ||
                n === "closewindow" || n === "activespecial") {
                debounceRefresh.restart()
            }
        }
    }

    property Timer debounceRefresh: Timer {
        interval: 150
        onTriggered: root.refresh()
    }

    property Process clientsProc: Process {
        command: ["sh", "-c", "hyprctl clients -j 2>/dev/null; echo '___SP_SPLIT___'; hyprctl activewindow -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("___SP_SPLIT___")
                const clientsRaw = (parts[0] || "").trim()
                const activeRaw = (parts[1] || "").trim()

                const list = []
                try {
                    const arr = JSON.parse(clientsRaw)
                    if (Array.isArray(arr)) {
                        for (const c of arr) {
                            const wsName = c.workspace && c.workspace.name ? String(c.workspace.name) : ""
                            if (!wsName.startsWith("special")) continue
                            list.push({
                                address: c.address || "",
                                title: c.title || c.initialTitle || c.class || "Window",
                                appClass: c.class || c.initialClass || "",
                                workspaceName: wsName.replace(/^special:/, ""),
                                pid: c.pid || 0
                            })
                        }
                    }
                } catch (e) {}

                const nextJson = JSON.stringify(list)
                if (nextJson !== root._lastItemsJson) {
                    root._lastItemsJson = nextJson
                    root.items = list
                }

                try {
                    const act = JSON.parse(activeRaw)
                    const actWs = act.workspace && act.workspace.name ? String(act.workspace.name) : ""
                    if (act && act.address && !actWs.startsWith("special")) {
                        root.activeAddress = act.address
                        root.activeTitle = act.title || act.class || ""
                    } else {
                        root.activeAddress = ""
                        root.activeTitle = ""
                    }
                } catch (e) {
                    root.activeAddress = ""
                    root.activeTitle = ""
                }

                root.loading = false
                if (root._pendingRefresh) {
                    root._pendingRefresh = false
                    debounceRefresh.restart()
                }
            }
        }
    }

    property Process dispatchProc: Process {
        onExited: debounceRefresh.restart()
    }

    function refresh() {
        if (clientsProc.running) {
            root._pendingRefresh = true
            return
        }
        root.loading = true
        clientsProc.running = true
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) refresh()
    }

    function stashActive() {
        if (dispatchProc.running) return
        if (root.activeAddress) {
            dispatchProc.command = ["hyprctl", "dispatch", "movetoworkspacesilent", "special:scratchpad,address:" + root.activeAddress]
        } else {
            dispatchProc.command = ["hyprctl", "dispatch", "movetoworkspacesilent", "special:scratchpad"]
        }
        dispatchProc.running = true
    }

    function restoreWindow(address) {
        if (!address || dispatchProc.running) return
        const wsId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
        dispatchProc.command = [
            "hyprctl", "--batch",
            "dispatch movetoworkspace " + wsId + ",address:" + address + "; dispatch focuswindow address:" + address
        ]
        dispatchProc.running = true
        root.visible = false
    }

    function closeWindow(address) {
        if (!address || dispatchProc.running) return
        dispatchProc.command = ["hyprctl", "dispatch", "closewindow", "address:" + address]
        dispatchProc.running = true
    }

    Component.onCompleted: refresh()
}
