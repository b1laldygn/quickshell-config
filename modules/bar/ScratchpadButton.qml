// modules/bar/ScratchpadButton.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: root
    readonly property real s: SettingsState.scaleFactor

    implicitWidth: contentRow.implicitWidth + Math.round(12 * s)
    implicitHeight: Math.round(26 * s)
    radius: Math.round(6 * s)
    color: hoverArea.containsMouse || ScratchpadState.visible ? Colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Math.round(4 * root.s)

        Text {
            text: "󰘸"
            color: ScratchpadState.visible || ScratchpadState.count > 0 ? Colors.accent : Colors.foreground
            font.pixelSize: Math.round(14 * root.s)
            font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
            visible: ScratchpadState.count > 0
            width: Math.max(Math.round(16 * root.s), badgeTxt.implicitWidth + Math.round(6 * root.s))
            height: Math.round(16 * root.s)
            radius: height / 2
            color: Colors.accent

            Text {
                id: badgeTxt
                anchors.centerIn: parent
                text: ScratchpadState.count
                color: Colors.accentText
                font.pixelSize: Math.round(9 * root.s)
                font.bold: true
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                NetworkState.visible = false
                AudioDeviceListState.visible = false
                BluetoothListState.visible = false
                SystemInfo.panelVisible = false
                WeatherPanelState.visible = false
                CalendarState.visible = false
                ScratchpadState.toggle()
            } else if (mouse.button === Qt.RightButton) {
                ScratchpadState.stashActive()
            }
        }
    }
}
