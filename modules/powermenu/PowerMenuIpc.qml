import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "powermenu"

    function toggle(): void { PowerMenuState.visible = !PowerMenuState.visible }
    function open(): void { PowerMenuState.visible = true }
    function close(): void { PowerMenuState.visible = false }
}