// modules/mixer/AudioMixer.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            visible: AudioMixerState.visible

            anchors { top: true; right: true }
            margins { top: 44; right: 12 }

            implicitWidth: 320
            implicitHeight: Math.min(520, 140 + streamList.contentHeight)
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Ses Ayarları"
                        color: "#F5F5F5"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    // ---- SİSTEM (MASTER) SESİ ----
                    Rectangle {
                        id: masterCard
                        Layout.fillWidth: true
                        implicitHeight: 60
                        radius: 8
                        color: Colors.surface0

                        property real localVolume: AudioMixerState.masterVolume
                        property bool dragging: false

                        Connections {
                            target: AudioMixerState
                            function onMasterVolumeChanged() {
                                if (!masterCard.dragging) masterCard.localVolume = AudioMixerState.masterVolume
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Sistem Sesi"
                                    color: "#F5F5F5"
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: AudioMixerState.masterMuted ? "Sessiz" : Math.round(masterCard.localVolume * 100) + "%"
                                    color: AudioMixerState.masterMuted ? Colors.danger : Colors.foregroundMuted
                                    font.pixelSize: 10

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AudioMixerState.toggleMasterMute()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: Colors.hover

                                Rectangle {
                                    width: parent.width * Math.min(1, masterCard.localVolume)
                                    height: parent.height
                                    radius: 4
                                    color: AudioMixerState.masterMuted ? Colors.foregroundMuted : Colors.accent

                                    Behavior on width {
                                        enabled: !masterCard.dragging
                                        NumberAnimation { duration: 100 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    function updateFromX(x) {
                                        const ratio = Math.max(0, Math.min(1, x / width))
                                        masterCard.localVolume = ratio
                                        AudioMixerState.setMasterVolume(Math.round(ratio * 100))
                                    }

                                    onPressed: (mouse) => {
                                        masterCard.dragging = true
                                        AudioMixerState.anyDragging = true
                                        updateFromX(mouse.x)
                                    }
                                    onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x) }
                                    onReleased: {
                                        masterCard.dragging = false
                                        AudioMixerState.anyDragging = false
                                        AudioMixerState.refreshMaster()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colors.border
                    }

                    // ---- UYGULAMA BAZLI SESLER ----
                    Text {
                        text: "Uygulama Sesleri"
                        color: "#F5F5F5"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        visible: AudioMixerState.streams.length === 0
                        text: "Ses çalan uygulama yok"
                        color: Colors.foregroundMuted
                        font.pixelSize: 11
                        font.italic: true
                        Layout.topMargin: 10
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ListView {
                        id: streamList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: AudioMixerState.streams

                        delegate: Rectangle {
                            width: streamList.width
                            implicitHeight: 60
                            radius: 8
                            color: Colors.surface0

                            property real localVolume: modelData.volume
                            property bool dragging: false

                            Connections {
                                target: AudioMixerState
                                function onStreamsChanged() {
                                    if (!dragging) localVolume = modelData.volume
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.appName
                                        color: "#F5F5F5"
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.muted ? "Sessiz" : Math.round(localVolume * 100) + "%"
                                        color: modelData.muted ? Colors.danger : Colors.foregroundMuted
                                        font.pixelSize: 10

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: AudioMixerState.toggleMute(modelData.id)
                                        }
                                    }
                                }

                                Rectangle {
                                    id: track
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: Colors.hover

                                    Rectangle {
                                        width: parent.width * Math.min(1, localVolume)
                                        height: parent.height
                                        radius: 4
                                        color: modelData.muted ? Colors.foregroundMuted : Colors.accent

                                        Behavior on width {
                                            enabled: !dragging
                                            NumberAnimation { duration: 100 }
                                        }
                                    }

                                    MouseArea {
                                        id: sliderMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        function updateFromX(x) {
                                            const ratio = Math.max(0, Math.min(1, x / width))
                                            localVolume = ratio
                                            const pct = Math.round(ratio * 100)
                                            AudioMixerState.setVolume(modelData.id, pct)
                                        }

                                        onPressed: (mouse) => {
                                            dragging = true
                                            AudioMixerState.anyDragging = true
                                            updateFromX(mouse.x)
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) updateFromX(mouse.x)
                                        }
                                        onReleased: {
                                            dragging = false
                                            AudioMixerState.anyDragging = false
                                            AudioMixerState.refresh()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}