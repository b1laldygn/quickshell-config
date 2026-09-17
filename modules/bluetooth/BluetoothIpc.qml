import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "bluetooth"
    function toggle(): void { BluetoothListState.visible = !BluetoothListState.visible }
    function open(): void { BluetoothListState.visible = true }
    function close(): void { BluetoothListState.visible = false }
}