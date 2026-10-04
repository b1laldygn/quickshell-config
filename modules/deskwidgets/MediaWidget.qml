// modules/deskwidgets/MediaWidget.qml
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    id: root

    property var activePlayer: {
        const players = Mpris.players.values
        if (players.length === 0) return null
        return players.find(p => p.isPlaying) || players[0]
    }

    Variants {
        model: Quickshell.screens

        DeskCard {
            property var modelData
            screen: modelData

            widgetId: "media"
            shown: SettingsState.showMediaWidget && root.activePlayer !== null
            corner: SettingsState.mediaWidgetCorner

            Timer {
                interval: 500
                repeat: true
                running: SettingsState.showMediaWidget && (root.activePlayer?.isPlaying ?? false)
                onTriggered: root.activePlayer.positionChanged()
            }

            Text {
                text: I18n.t("nowPlaying")
                color: Colors.foregroundMuted
                font.pixelSize: 10
            }

            Text {
                text: root.activePlayer?.trackTitle || ""
                color: "#F5F5F5"
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.activePlayer?.trackArtist || ""
                color: Colors.foregroundMuted
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                implicitHeight: 5
                radius: 2
                color: Colors.surface0

                Rectangle {
                    width: {
                        const len = root.activePlayer?.length || 0
                        if (len <= 0) return 0
                        return parent.width * Math.min(1, root.activePlayer.position / len)
                    }
                    height: parent.height
                    radius: 2
                    color: Colors.accent
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.activePlayer?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        const len = root.activePlayer?.length || 0
                        if (len <= 0) return
                        root.activePlayer.position = (mouse.x / width) * len
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                spacing: 22

                Text {
                    text: "󰒮"
                    color: root.activePlayer?.canGoPrevious ? "#F5F5F5" : "#585b70"
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer?.canGoPrevious) root.activePlayer.previous()
                    }
                }

                Text {
                    text: root.activePlayer?.isPlaying ? "󰏤" : "󰐊"
                    color: "#F5F5F5"
                    font.pixelSize: 22
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activePlayer?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    color: root.activePlayer?.canGoNext ? "#F5F5F5" : "#585b70"
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer?.canGoNext) root.activePlayer.next()
                    }
                }
            }
        }
    }
}