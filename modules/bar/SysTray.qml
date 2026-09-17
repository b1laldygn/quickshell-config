import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "root:/config"

RowLayout {
    id: root
    spacing: 6

    property var trayWindow: null   // Bar.qml'den geçirilecek

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem
            required property SystemTrayItem modelData

            implicitWidth: 24
            implicitHeight: 24
            radius: 6
            color: hoverArea.containsMouse ? Colors.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayItem.modelData.icon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        trayItem.modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (root.trayWindow) {
                            const pos = trayItem.mapToItem(null, mouse.x, mouse.y)
                            trayItem.modelData.display(root.trayWindow, pos.x, pos.y)
                        }
                    }
                }
            }
        }
    }
}