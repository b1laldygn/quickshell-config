import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "root:/config"


RowLayout {
    id: root
    property string screenName: ""
    spacing: 6

    Repeater {
        model: 9 // 1'den 9'a kadar workspace göster

        Rectangle {
            id: wsButton
            property int wsId: index + 1
            property bool isActive: Hyprland.focusedWorkspace?.id === wsId
            property bool isOccupied: {
                const ws = Hyprland.workspaces.values.find(w => w.id === wsId)
                return ws !== undefined
            }

            implicitWidth: 24
            implicitHeight: 20
            radius: 5
            color: isActive ? Colors.accent : (isOccupied ? Colors.active : "transparent")
            border.color: Colors.border

            border.width: isOccupied && !isActive ? 1 : 0

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
                onClicked: Hyprland.dispatch("workspace " + wsButton.wsId)
            }
        }
    }
}