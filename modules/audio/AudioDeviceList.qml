import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: audioWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: AudioDeviceListState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: AudioDeviceListState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            property var sinks: []
            property var sources: []

            function refresh() {
                if (!statusProc.running) statusProc.running = true
            }

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
                focus: AudioDeviceListState.visible
                Keys.onEscapePressed: AudioDeviceListState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: AudioDeviceListState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.leftMargin: Math.max(8, Math.min(AudioDeviceListState.anchorX - width / 2, parent.width - width - 8))
                    width: Math.round(330 * s)
                    height: Math.min(Math.round(540 * s), Math.round(mainColumn.implicitHeight + 30 * s))
                    radius: Math.round(14 * s)
                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transformOrigin: Item.Top
                    transform: Translate { y: fx.cardY }
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Math.round(14 * card.s)
                        contentWidth: width
                        contentHeight: mainColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: mainColumn
                            width: parent.width
                            spacing: Math.round(10 * card.s)

                            // ── Başlık ───────────────────────────────────────
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.round(8 * card.s)

                                Rectangle {
                                    width: Math.round(26 * card.s)
                                    height: width
                                    radius: Math.round(8 * card.s)
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

                                    Text {
                                        anchors.centerIn: parent
                                        text: AudioMixerState.masterMuted ? "󰝟" : "󰕾"
                                        color: Colors.accent
                                        font.pixelSize: Math.round(13 * card.s)
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }

                                Text {
                                    text: I18n.t("audioDevices")
                                    color: Colors.foreground
                                    font.pixelSize: Math.round(14 * card.s)
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: Math.round(24 * card.s)
                                    height: width
                                    radius: Math.round(6 * card.s)
                                    color: refreshHover.containsMouse ? Colors.hover : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰑓"
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(13 * card.s)
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    MouseArea {
                                        id: refreshHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            audioWindow.refresh()
                                            AudioMixerState.refreshMaster()
                                            AudioMixerState.refresh()
                                        }
                                    }
                                }

                                Rectangle {
                                    width: Math.round(24 * card.s)
                                    height: width
                                    radius: Math.round(6 * card.s)
                                    color: closeHover.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                        font.pixelSize: Math.round(11 * card.s)
                                    }

                                    MouseArea {
                                        id: closeHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AudioDeviceListState.visible = false
                                    }
                                }
                            }

                            // ── Ana Ses Kartı ────────────────────────────────
                            Rectangle {
                                id: volumeCard
                                Layout.fillWidth: true
                                implicitHeight: Math.round(56 * card.s)
                                radius: Math.round(10 * card.s)
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
                                    anchors.margins: Math.round(10 * card.s)
                                    spacing: Math.round(6 * card.s)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(6 * card.s)

                                        Text {
                                            text: AudioMixerState.masterMuted ? "󰝟" : "󰕾"
                                            color: AudioMixerState.masterMuted ? Colors.danger : Colors.accent
                                            font.pixelSize: Math.round(14 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioMixerState.toggleMasterMute()
                                            }
                                        }

                                        Text {
                                            text: I18n.t("systemVolume")
                                            color: Colors.foreground
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: AudioMixerState.masterMuted ? I18n.t("muted") : Math.round(volumeCard.localVolume * 100) + "%"
                                            color: AudioMixerState.masterMuted ? Colors.danger : Colors.accent
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioMixerState.toggleMasterMute()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: Math.round(8 * card.s)
                                        radius: height / 2
                                        color: Colors.hover

                                        Rectangle {
                                            width: parent.width * Math.min(1, volumeCard.localVolume)
                                            height: parent.height
                                            radius: height / 2
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

                                            onPressed: (mouse) => { volumeCard.dragging = true; updateFromX(mouse.x) }
                                            onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x) }
                                            onReleased: { volumeCard.dragging = false; AudioMixerState.refreshMaster() }
                                        }
                                    }
                                }
                            }

                            // ── Çıkış Cihazları ──────────────────────────────
                            Text {
                                text: I18n.t("output")
                                color: Colors.accent
                                font.pixelSize: Math.round(10 * card.s)
                                font.bold: true
                            }

                            Repeater {
                                model: audioWindow.sinks
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: Math.round(36 * card.s)
                                    radius: Math.round(8 * card.s)
                                    color: modelData.isDefault
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                        : (sinkArea.containsMouse ? Colors.hover : Colors.surface0)
                                    border.color: modelData.isDefault ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(10 * card.s)
                                        anchors.rightMargin: Math.round(10 * card.s)
                                        spacing: Math.round(8 * card.s)

                                        Text {
                                            text: modelData.isDefault ? "󰕾" : "󰓃"
                                            color: modelData.isDefault ? Colors.accent : Colors.foreground
                                            font.pixelSize: Math.round(13 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                        Text {
                                            text: modelData.name
                                            color: modelData.isDefault ? Colors.accent : Colors.foreground
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: modelData.isDefault
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: modelData.isDefault
                                            text: "󰄬"
                                            color: Colors.accent
                                            font.pixelSize: Math.round(12 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"
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

                            // ── Giriş Cihazları ──────────────────────────────
                            Text {
                                text: I18n.t("input")
                                color: Colors.accent
                                font.pixelSize: Math.round(10 * card.s)
                                font.bold: true
                                Layout.topMargin: Math.round(4 * card.s)
                            }

                            Repeater {
                                model: audioWindow.sources
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: Math.round(36 * card.s)
                                    radius: Math.round(8 * card.s)
                                    color: modelData.isDefault
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                        : (sourceArea.containsMouse ? Colors.hover : Colors.surface0)
                                    border.color: modelData.isDefault ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(10 * card.s)
                                        anchors.rightMargin: Math.round(10 * card.s)
                                        spacing: Math.round(8 * card.s)

                                        Text {
                                            text: "󰍬"
                                            color: modelData.isDefault ? Colors.accent : Colors.foreground
                                            font.pixelSize: Math.round(13 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                        Text {
                                            text: modelData.name
                                            color: modelData.isDefault ? Colors.accent : Colors.foreground
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: modelData.isDefault
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: modelData.isDefault
                                            text: "󰄬"
                                            color: Colors.accent
                                            font.pixelSize: Math.round(12 * card.s)
                                            font.family: "JetBrainsMono Nerd Font"
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
                                Layout.topMargin: Math.round(4 * card.s)
                            }

                            // ── Uygulama Sesleri ─────────────────────────────
                            Text {
                                text: I18n.t("appVolumes")
                                color: Colors.accent
                                font.pixelSize: Math.round(10 * card.s)
                                font.bold: true
                            }

                            Text {
                                visible: AudioMixerState.streams.length === 0
                                text: I18n.t("noAppsPlaying")
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(11 * card.s)
                                font.italic: true
                            }

                            Repeater {
                                model: AudioMixerState.streams

                                Rectangle {
                                    id: streamCard
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(54 * card.s)
                                    radius: Math.round(9 * card.s)
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
                                        anchors.margins: Math.round(8 * card.s)
                                        spacing: Math.round(5 * card.s)

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.appName
                                                color: Colors.foreground
                                                font.pixelSize: Math.round(11 * card.s)
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: modelData.muted ? I18n.t("muted") : Math.round(streamCard.localVolume * 100) + "%"
                                                color: modelData.muted ? Colors.danger : Colors.foregroundMuted
                                                font.pixelSize: Math.round(10 * card.s)

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: AudioMixerState.toggleMute(modelData.id)
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: Math.round(6 * card.s)
                                            radius: height / 2
                                            color: Colors.hover

                                            Rectangle {
                                                width: parent.width * Math.min(1, streamCard.localVolume)
                                                height: parent.height
                                                radius: height / 2
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
                        }
                    }
                }
            }
        }
    }
}
