// modules/clipboard/ClipboardIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "clipboard"

    function toggle(): void {
        ClipboardState.toggle()
    }

    function open(): void {
        ClipboardState.visible = true
        ClipboardState.refresh()
    }

    function close(): void {
        ClipboardState.visible = false
    }
}