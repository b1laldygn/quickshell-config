// modules/alttab/AltTabIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "alttab"

    function next(): void { AltTabState.next() }
    function prev(): void { AltTabState.prev() }
    function commit(): void { AltTabState.commit() }
    function cancel(): void { AltTabState.cancel() }
}