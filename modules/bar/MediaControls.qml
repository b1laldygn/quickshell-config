// modules/bar/MediaControls.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "root:/config"

Item {
    id: root

    property var activePlayer: {
        const players = Mpris.players.values
        if (players.length === 0) return null
        const playing = players.find(p => p.isPlaying)
        return playing || players[0]
    }

    property bool hasPlayer: activePlayer !== null
    property bool expanded: hoverArea.containsMouse && hasPlayer

    visible: hasPlayer
    implicitHeight: 26
    implicitWidth: expanded ? 280 : 26

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Pozisyonu çalarken canlı takip etmek için (sadece genişken, CPU tasarrufu için)
    Timer {
        interval: 500
        repeat: true
        running: root.expanded && root.activePlayer?.playbackState === MprisPlaybackState.Playing
        onTriggered: root.activePlayer.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.expanded ? Colors.backgroundAlt : "transparent"
        clip: true

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }

        // ---- KOMPAKT: sadece nota ikonu ----
        Text {
            id: compactIcon
            anchors.centerIn: parent
            text: "󰝚"
            color: "#F5F5F5"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            opacity: root.expanded ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // ---- GENİŞLEMİŞ HAL: kontroller + seek bar ----
        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8
            opacity: root.expanded ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                text: "󰒮"
                color: root.activePlayer?.canGoPrevious ? "#F5F5F5" : "#585b70"
                font.pixelSize: 13
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
                font.pixelSize: 13
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
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.activePlayer?.canGoNext) root.activePlayer.next()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: {
                        if (!root.activePlayer) return ""
                        const artist = root.activePlayer.trackArtist || ""
                        const title = root.activePlayer.trackTitle || ""
                        return artist ? artist + " - " + title : title
                    }
                    color: "#F5F5F5"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // ---- SEEK EDİLEBİLİR PROGRESS BAR ----
                Rectangle {
                    id: seekBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 2
                    color: Colors.surface0

                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: Colors.accent
                        width: {
                            const len = root.activePlayer?.length || 0
                            if (len <= 0) return 0
                            return parent.width * (root.activePlayer.position / len)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer?.canSeek ?? false
                        onClicked: (mouse) => {
                            const len = root.activePlayer?.length || 0
                            if (len <= 0) return
                            const ratio = mouse.x / width
                            root.activePlayer.position = ratio * len
                        }
                    }
                }
            }
        }
    }
}