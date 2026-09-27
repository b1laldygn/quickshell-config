// services/WeatherPanelState.qml
pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
    property real anchorX: 0

    function toggle() {
        visible = !visible
    }
}