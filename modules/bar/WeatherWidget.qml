// modules/bar/WeatherWidget.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: root
    implicitWidth: content.implicitWidth + 12
    implicitHeight: 26
    radius: 6
    visible: WeatherState.loaded
    color: hoverArea.containsMouse ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: WeatherState.icon
            color: "#F5F5F5"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            text: Math.round(WeatherState.tempC) + "°"
            color: "#F5F5F5"
            font.pixelSize: 11
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
            WeatherPanelState.toggle()
        }
    }
}