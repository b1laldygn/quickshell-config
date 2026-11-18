pragma Singleton
import Quickshell

Singleton {
    property bool visible: false

    function toggle() {
        visible = !visible
    }
}