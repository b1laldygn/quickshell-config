// services/AltTabState.qml
pragma Singleton
import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    property bool isOpen: false  // 'visible' yerine 'isOpen' yapıldı
    property int selectedIndex: 0
    property var mruAddresses: []
    property var windowList: []

    Connections {
        target: Hyprland
        onActiveToplevelChanged: {
            const t = Hyprland.activeToplevel
            if (!t || !t.address) return
            const addr = t.address
            let list = root.mruAddresses.filter(a => a !== addr)
            list.unshift(addr)
            if (list.length > 30) list = list.slice(0, 30)
            root.mruAddresses = list
        }
    }

    function currentWindows() {
        const all = []
        for (const ws of Hyprland.workspaces.values) {
            const tls = ws.toplevels ? ws.toplevels.values : []
            for (const t of tls) all.push(t)
        }

        const byAddr = {}
        for (const t of all) {
            if (t.address) byAddr[t.address] = t
        }

        const ordered = []
        for (const addr of root.mruAddresses) {
            if (byAddr[addr]) {
                ordered.push(byAddr[addr])
                delete byAddr[addr]
            }
        }
        for (const addr in byAddr) {
            ordered.push(byAddr[addr])
        }
        return ordered
    }

    function open() {
    root.windowList = currentWindows()
    if (root.windowList.length === 0) {
        root.isOpen = false
        return
    }
    root.selectedIndex = 1
    root.isOpen = true
}

    function next() {
        if (!root.isOpen) { open(); return }  // 'visible' yerine 'isOpen'
        if (root.windowList.length === 0) return
        root.selectedIndex = (root.selectedIndex + 1) % root.windowList.length
    }

    function prev() {
        if (!root.isOpen) { open(); return }  // 'visible' yerine 'isOpen'
        if (root.windowList.length === 0) return
        root.selectedIndex = (root.selectedIndex - 1 + root.windowList.length) % root.windowList.length
    }

    function selectAt(index) {
        root.selectedIndex = index
    }

    function commit() {
        if (!root.isOpen) return  // 'visible' yerine 'isOpen'
        const list = root.windowList
        if (list.length > 0 && root.selectedIndex < list.length) {
            const t = list[root.selectedIndex]
            if (t && t.address) {
                Hyprland.dispatch("focuswindow address:0x" + t.address)
            }
        }
        root.isOpen = false  // 'visible' yerine 'isOpen'
    }

    function cancel() {
        root.isOpen = false  // 'visible' yerine 'isOpen'
    }
}