import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "audio"
    function toggle(): void { AudioDeviceListState.visible = !AudioDeviceListState.visible }
    function open(): void { AudioDeviceListState.visible = true }
    function close(): void { AudioDeviceListState.visible = false }
}