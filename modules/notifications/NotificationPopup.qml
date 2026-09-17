// modules/notifications/NotificationPopup.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: card
    property var notification

    width: 320
    implicitHeight: content.implicitHeight + actionsRow.implicitHeight + 24
    radius: 10
    color: Colors.backgroundAlt
    border.color: Colors.border
    border.width: 1

    // Kritik değilse otomatik kapat
    Timer {
        running: card.notification && card.notification.urgency !== 2 // 2 = Critical
        interval: card.notification && card.notification.expireTimeout > 0
                ? card.notification.expireTimeout : 5000
        onTriggered: NotificationService.dismiss(card.notification.id)
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            id: content
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: card.notification?.image || ""
                visible: source !== ""
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: card.notification?.summary || ""
                    color: Colors.foreground
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: card.notification?.body || ""
                    color: Colors.foregroundMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Colors.foregroundMuted
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismiss(card.notification.id)
                }
            }
        }

        RowLayout {
            id: actionsRow
            Layout.fillWidth: true
            spacing: 8
            visible: card.notification && card.notification.actions && card.notification.actions.length > 0

            Repeater {
                model: card.notification ? card.notification.actions : []

                delegate: Rectangle {
                    radius: 6
                    color: actionHover.containsMouse ? Colors.accent : Colors.surface0
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: actionLabel.implicitWidth + 20

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: actionHover.containsMouse ? Colors.accentText : "#F5F5F5"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke()
                            NotificationService.dismiss(card.notification.id)
                        }
                    }
                }
            }
        }
    }
}