// modules/overview/OverviewIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "overview"

    function toggle(): void {
        OverviewState.visible = !OverviewState.visible
    }

    function open(): void {
        OverviewState.visible = true
    }

    function close(): void {
        OverviewState.visible = false
    }
}