// services/SystemMonitorState.qml
pragma Singleton
import QtQuick
import "root:/services"

QtObject {
    id: root
    property bool visible: SystemInfo.panelVisible
    property real anchorX: SystemInfo.anchorX

    function toggle() {
        SystemInfo.togglePanel()
    }
}
