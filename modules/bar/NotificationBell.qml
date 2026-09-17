// modules/bar/NotificationBell.qml
import QtQuick
import "root:/config"
import "root:/services"

Rectangle {
    id: bellBtn
    width: 26
    height: 26
    radius: 6
    color: hoverArea.containsMouse ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: "󰂚"
        color: "#F5F5F5"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
    }

    Rectangle {
        visible: NotificationService.unreadCount > 0
        width: 8
        height: 8
        radius: 4
        color: Colors.danger
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.toggleCenter()
    }
}