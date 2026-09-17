// modules/launcher/LauncherIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "launcher"

    function toggle(): void {
        LauncherState.visible = !LauncherState.visible
    }

    function open(): void {
        LauncherState.visible = true
    }

    function close(): void {
        LauncherState.visible = false
    }
}