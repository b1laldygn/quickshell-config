// modules/scratchpad/ScratchpadIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "scratchpad"

    function toggle(): void {
        ScratchpadState.toggle()
    }

    function open(): void {
        ScratchpadState.visible = true
        ScratchpadState.refresh()
    }

    function close(): void {
        ScratchpadState.visible = false
    }

    function stash(): void {
        ScratchpadState.stashActive()
    }
}
