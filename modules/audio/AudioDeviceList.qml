import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: audioWindow
            property var modelData
            screen: modelData

            visible: AudioDeviceListState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            property var sinks: []
            property var sources: []

            function refresh() { statusProc.running = true }
            onVisibleChanged: {
                if (visible) {
                    refresh()
                    AudioMixerState.refreshMaster()
                    AudioMixerState.refresh()
                }
            }

            function parseSection(text, sectionName, stopNames) {
                const startIdx = text.indexOf(sectionName)
                if (startIdx === -1) return []
                let endIdx = text.length
                for (const n of stopNames) {
                    const idx = text.indexOf(n, startIdx + sectionName.length)
                    if (idx !== -1 && idx < endIdx) endIdx = idx
                }
                const block = text.slice(startIdx, endIdx)
                const lines = block.split("\n")
                const devices = []
                for (const line of lines) {
                    const m = line.match(/(\*)?\s*(\d+)\.\s+(.+?)\s+\[vol:/)
                    if (m) {
                        devices.push({ id: m[2], name: m[3].trim(), isDefault: m[1] === "*" })
                    }
                }
                return devices
            }

            Process {
                id: statusProc
                command: ["wpctl", "status"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const text = this.text
                        audioWindow.sinks = audioWindow.parseSection(
                            text, "Sinks:", ["Sink endpoints:", "Sources:", "Source endpoints:", "Filters:"])
                        audioWindow.sources = audioWindow.parseSection(
                            text, "Sources:", ["Source endpoints:", "Filters:"])
                    }
                }
            }

            Process {
                id: setDefaultProc
                onExited: audioWindow.refresh()
            }

            function setDefault(id) {
                setDefaultProc.command = ["wpctl", "set-default", id]
                setDefaultProc.running = true
            }

            Item {
                anchors.fill: parent
                focus: audioWindow.visible
                Keys.onEscapePressed: audioWindow.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: audioWindow.visible = false
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 44    // NOT: bar yüksekliğine göre ayarla
                    anchors.leftMargin: 130  // NOT: ses ikonunun gerçek x konumuna göre ayarla
                    width: 300
                    height: 520
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 12
                        contentWidth: width
                        contentHeight: mainColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: mainColumn
                            width: parent.width
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: I18n.t("audioDevices")
                                    color: "#F5F5F5"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "󰑓"
                                    color: "#F5F5F5"
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            audioWindow.refresh()
                                            AudioMixerState.refreshMaster()
                                            AudioMixerState.refresh()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: volumeCard
                                Layout.fillWidth: true
                                implicitHeight: 50
                                radius: 8
                                color: Colors.surface0

                                property real localVolume: AudioMixerState.masterVolume
                                property bool dragging: false

                                Connections {
                                    target: AudioMixerState
                                    function onMasterVolumeChanged() {
                                        if (!volumeCard.dragging) volumeCard.localVolume = AudioMixerState.masterVolume
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: AudioMixerState.masterMuted ? "󰝟" : "󰕾"
                                            color: "#F5F5F5"
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioMixerState.toggleMasterMute()
                                            }
                                        }

                                        Text {
                                            text: AudioMixerState.masterMuted ? I18n.t("muted") : Math.round(volumeCard.localVolume * 100) + "%"
                                            color: AudioMixerState.masterMuted ? Colors.danger : "#F5F5F5"
                                            font.pixelSize: 11
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 8
                                        radius: 4
                                        color: Colors.hover

                                        Rectangle {
                                            width: parent.width * Math.min(1, volumeCard.localVolume)
                                            height: parent.height
                                            radius: 4
                                            color: AudioMixerState.masterMuted ? Colors.foregroundMuted : Colors.accent

                                            Behavior on width {
                                                enabled: !volumeCard.dragging
                                                NumberAnimation { duration: 100 }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            function updateFromX(x) {
                                                const ratio = Math.max(0, Math.min(1, x / width))
                                                volumeCard.localVolume = ratio
                                                AudioMixerState.setMasterVolume(Math.round(ratio * 100))
                                            }

                                            onPressed: (mouse) => updateFromX(mouse.x)
                                            onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x) }
                                            onReleased: AudioMixerState.refreshMaster()
                                        }
                                    }
                                }
                            }

                            Text {
                                text: I18n.t("output")
                                color: Colors.foregroundMuted
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Repeater {
                                model: audioWindow.sinks
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: sinkArea.containsMouse ? Colors.hover : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        Text {
                                            text: modelData.isDefault ? "󰕾" : "󰓃"
                                            color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                        Text {
                                            text: modelData.name
                                            color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: sinkArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: audioWindow.setDefault(modelData.id)
                                    }
                                }
                            }

                            Text {
                                text: I18n.t("input")
                                color: Colors.foregroundMuted
                                font.pixelSize: 10
                                font.bold: true
                                Layout.topMargin: 6
                            }

                            Repeater {
                                model: audioWindow.sources
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: sourceArea.containsMouse ? Colors.hover : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        Text {
                                            text: "󰍬"
                                            color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                        Text {
                                            text: modelData.name
                                            color: modelData.isDefault ? Colors.accent : "#F5F5F5"
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: sourceArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: audioWindow.setDefault(modelData.id)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Colors.border
                                Layout.topMargin: 4
                            }

                            Text {
                                text: I18n.t("appVolumes")
                                color: Colors.foregroundMuted
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                visible: AudioMixerState.streams.length === 0
                                text: I18n.t("noAppsPlaying")
                                color: Colors.foregroundMuted
                                font.pixelSize: 11
                                font.italic: true
                            }

                            Repeater {
                                model: AudioMixerState.streams

                                Rectangle {
                                    id: streamCard
                                    Layout.fillWidth: true
                                    implicitHeight: 56
                                    radius: 8
                                    color: Colors.surface0

                                    property real localVolume: modelData.volume
                                    property bool dragging: false

                                    Connections {
                                        target: AudioMixerState
                                        function onStreamsChanged() {
                                            if (!streamCard.dragging) streamCard.localVolume = modelData.volume
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.appName
                                                color: "#F5F5F5"
                                                font.pixelSize: 11
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: modelData.muted ? I18n.t("muted") : Math.round(streamCard.localVolume * 100) + "%"
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
                                            Layout.fillWidth: true
                                            height: 6
                                            radius: 3
                                            color: Colors.hover

                                            Rectangle {
                                                width: parent.width * Math.min(1, streamCard.localVolume)
                                                height: parent.height
                                                radius: 3
                                                color: modelData.muted ? Colors.foregroundMuted : Colors.accent

                                                Behavior on width {
                                                    enabled: !streamCard.dragging
                                                    NumberAnimation { duration: 100 }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor

                                                function updateFromX(x) {
                                                    const ratio = Math.max(0, Math.min(1, x / width))
                                                    streamCard.localVolume = ratio
                                                    AudioMixerState.setVolume(modelData.id, Math.round(ratio * 100))
                                                }

                                                onPressed: (mouse) => {
                                                    streamCard.dragging = true
                                                    AudioMixerState.anyDragging = true
                                                    updateFromX(mouse.x)
                                                }
                                                onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x) }
                                                onReleased: {
                                                    streamCard.dragging = false
                                                    AudioMixerState.anyDragging = false
                                                    AudioMixerState.refresh()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
}