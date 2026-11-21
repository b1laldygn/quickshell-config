// modules/notifications/NotificationPopup.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Rectangle {
    id: card
    property var notification

    readonly property bool isCritical: card.notification?.urgency === 2
    readonly property string appName: (card.notification?.appName || "Bildirim").trim()

    width: Math.round(340 * SettingsState.scaleFactor)
    implicitHeight: content.implicitHeight + (actionsRow.visible ? actionsRow.implicitHeight + 8 : 0) + Math.round(24 * SettingsState.scaleFactor)
    radius: Math.round(10 * SettingsState.scaleFactor)
    color: Colors.backgroundAlt
    border.color: isCritical ? Colors.danger : Colors.border
    border.width: isCritical ? 2 : 1

    // Kritik veya otomatik kapatma zamanlayıcısı
    Timer {
        running: card.notification && card.notification.urgency !== 2
        interval: card.notification && card.notification.expireTimeout > 0
                    ? card.notification.expireTimeout : SettingsState.notificationTimeout * 1000
        onTriggered: NotificationService.dismiss(card.notification.id)
    }

    // Sol aciliyet renk şeridi
    Rectangle {
        width: Math.round(4 * SettingsState.scaleFactor)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(3 * SettingsState.scaleFactor)
        radius: Math.round(2 * SettingsState.scaleFactor)
        color: isCritical
            ? Colors.danger
            : (card.notification?.urgency === 0 ? Colors.surface0 : Colors.accent)
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(12 * SettingsState.scaleFactor)
        anchors.leftMargin: Math.round(16 * SettingsState.scaleFactor)
        spacing: Math.round(8 * SettingsState.scaleFactor)

        RowLayout {
            id: content
            Layout.fillWidth: true
            spacing: Math.round(10 * SettingsState.scaleFactor)

            Image {
                source: card.notification?.image || ""
                visible: source !== ""
                Layout.preferredWidth: Math.round(36 * SettingsState.scaleFactor)
                Layout.preferredHeight: Math.round(36 * SettingsState.scaleFactor)
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * SettingsState.scaleFactor)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: card.appName
                        color: Colors.accent
                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                        font.bold: true
                    }

                    Text {
                        visible: card.isCritical
                        text: "󰅚 " + I18n.t("criticalNotice")
                        color: Colors.danger
                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    text: card.notification?.summary || ""
                    color: Colors.foreground
                    font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: card.notification?.body || ""
                    color: Colors.foregroundMuted
                    font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            // Hızlı Eylemler (Sessize Al & Kapat)
            RowLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 4

                // Uygulamayı Sessize Al butonu
                Rectangle {
                    width: Math.round(22 * SettingsState.scaleFactor)
                    height: Math.round(22 * SettingsState.scaleFactor)
                    radius: Math.round(4 * SettingsState.scaleFactor)
                    color: muteHover.containsMouse ? Colors.hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰝟"
                        color: muteHover.containsMouse ? Colors.accent : Colors.foregroundMuted
                        font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: muteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.muteApp(card.appName)
                            NotificationService.dismiss(card.notification.id)
                        }
                    }
                }

                // Kapat Butonu
                Rectangle {
                    width: Math.round(22 * SettingsState.scaleFactor)
                    height: Math.round(22 * SettingsState.scaleFactor)
                    radius: Math.round(4 * SettingsState.scaleFactor)
                    color: closeHover.containsMouse ? Colors.hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                        font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.dismiss(card.notification.id)
                    }
                }
            }
        }

        RowLayout {
            id: actionsRow
            Layout.fillWidth: true
            spacing: Math.round(8 * SettingsState.scaleFactor)
            visible: card.notification && card.notification.actions && card.notification.actions.length > 0

            Repeater {
                model: card.notification ? card.notification.actions : []

                delegate: Rectangle {
                    radius: Math.round(6 * SettingsState.scaleFactor)
                    color: actionHover.containsMouse ? Colors.accent : Colors.surface0
                    Layout.preferredHeight: Math.round(28 * SettingsState.scaleFactor)
                    Layout.preferredWidth: actionLabel.implicitWidth + Math.round(20 * SettingsState.scaleFactor)

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: actionHover.containsMouse ? Colors.accentText : "#F5F5F5"
                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
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
