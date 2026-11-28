// modules/bar/Clock.qml
import QtQuick
import "root:/services"

Item {
    id: root

    property date now: new Date()
    property real maxW: 0

    implicitWidth: Math.max(maxW, clockText.implicitWidth)
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        anchors.centerIn: parent
        text: TimeFormat.full(root.now, SettingsState.barClockSeconds)
        color: "#cdd6f4"
        font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
        onImplicitWidthChanged: if (implicitWidth > root.maxW) root.maxW = implicitWidth
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NetworkState.visible = false
            AudioDeviceListState.visible = false
            BluetoothListState.visible = false
            SystemInfo.panelVisible = false
            WeatherPanelState.visible = false
            CalendarState.toggle()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}