// modules/bar/WeatherWidget.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: root
    implicitWidth: content.implicitWidth + Math.round(12 * SettingsState.scaleFactor)
    implicitHeight: Math.round(26 * SettingsState.scaleFactor)
    radius: Math.round(6 * SettingsState.scaleFactor)
    visible: WeatherState.loaded
    color: hoverArea.containsMouse || WeatherPanelState.visible ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(5 * SettingsState.scaleFactor)

        Text {
            text: WeatherState.icon
            color: WeatherPanelState.visible ? Colors.accent : Colors.foreground
            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            text: Math.round(WeatherState.tempC) + "°"
            color: WeatherPanelState.visible ? Colors.accent : Colors.foreground
            font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const pos = root.mapToItem(null, root.width / 2, root.height)
            WeatherPanelState.anchorX = pos.x
            NetworkState.visible = false
            AudioDeviceListState.visible = false
            BluetoothListState.visible = false
            SystemInfo.panelVisible = false
            CalendarState.visible = false
            WeatherPanelState.toggle()
        }
    }
}
