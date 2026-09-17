import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "root:/config"

RowLayout {
    id: root
    property string screenName: ""
    spacing: 6

    Repeater {
        model: 10

        Rectangle {
            id: wsButton
            property int wsId: index + 1
            property bool hovered: false

            property bool isOccupied: {
                const ws = Hyprland.workspaces.values.find(
                    w => w.id === wsId && w.lastIpcObject?.monitor === root.screenName
                )
                return ws !== undefined
            }

            property bool isActive: {
                const fw = Hyprland.focusedWorkspace
                return fw?.id === wsId && fw?.lastIpcObject?.monitor === root.screenName
            }

            implicitWidth: 24
            implicitHeight: 20
            radius: 5
            color: isActive ? Colors.accent : (hovered ? Colors.hover : (isOccupied ? Colors.active : "transparent"))
            border.color: Colors.border
            border.width: isOccupied && !isActive ? 1 : 0

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            scale: isActive ? 1.05 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                text: wsButton.wsId
                color: wsButton.isActive ? Colors.accentText : Colors.foreground
                font.pixelSize: 12
                font.bold: wsButton.isActive
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: wsButton.hovered = true
                onExited: wsButton.hovered = false
                onClicked: Hyprland.dispatch("workspace " + wsButton.wsId)
            }
        }
    }
}