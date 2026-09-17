pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false
    property string type: "volume"
    property real value: 0

    property Timer hideTimer: Timer {
        interval: 1500
        onTriggered: root.visible = false
    }

    function show(t, v) {
    root.type = t
    root.value = Math.max(0, Math.min(1, v))
    root.visible = true
    hideTimer.restart()
}
}