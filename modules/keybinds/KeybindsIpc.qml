// modules/keybinds/KeybindsIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "keybinds"

    function toggle(): void {
        KeybindsState.toggle()
    }

    function open(): void {
        KeybindsState.visible = true
        KeybindsState.refresh()
    }

    function close(): void {
        KeybindsState.visible = false
    }
}