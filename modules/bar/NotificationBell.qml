// modules/bar/NotificationBell.qml
import QtQuick
import "root:/config"
import "root:/services"

Rectangle {
    id: bellBtn
    width: Math.round(26 * SettingsState.scaleFactor)
    height: Math.round(26 * SettingsState.scaleFactor)
    radius: Math.round(6 * SettingsState.scaleFactor)
    color: hoverArea.containsMouse
        ? Colors.hover
        : (SettingsState.dndEnabled ? Qt.rgba(0.98, 0.70, 0.53, 0.18) : "transparent")
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: SettingsState.dndEnabled ? "󰂛" : "󰂚"
        color: SettingsState.dndEnabled ? (Colors.warning || "#fab387") : "#F5F5F5"
        font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
        font.family: "JetBrainsMono Nerd Font"
    }

    Rectangle {
        visible: !SettingsState.dndEnabled && NotificationService.unreadCount > 0
        width: Math.round(8 * SettingsState.scaleFactor)
        height: Math.round(8 * SettingsState.scaleFactor)
        radius: width / 2
        color: Colors.danger
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Math.round(2 * SettingsState.scaleFactor)
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                NotificationService.toggleDnd()
            } else {
                NotificationService.toggleCenter()
            }
        }
    }
}
