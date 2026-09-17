import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "network"
    function toggle(): void { NetworkState.visible = !NetworkState.visible }
    function open(): void { NetworkState.visible = true }
    function close(): void { NetworkState.visible = false }
}
