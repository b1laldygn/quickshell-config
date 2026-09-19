// services/AudioMixerState.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false
    property bool anyDragging: false
    property var streams: []

    property Process listProc: Process {
        command: ["pactl", "-f", "json", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = []
                try {
                    parsed = JSON.parse(this.text)
                } catch (e) {
                    parsed = []
                }

                const result = []
                for (const entry of parsed) {
                    const props = entry.properties || {}
                    const appName = props["application.name"] || props["media.name"] || "Uygulama"

                    let percent = 100
                    if (entry.volume) {
                        const firstKey = Object.keys(entry.volume)[0]
                        if (firstKey && entry.volume[firstKey] && entry.volume[firstKey].value_percent) {
                            percent = parseInt(entry.volume[firstKey].value_percent)
                        }
                    }

                    result.push({
                        id: entry.index,
                        appName: appName,
                        volume: percent / 100,
                        muted: !!entry.mute
                    })
                }
                root.streams = result
            }
        }
    }

    function refresh() {
        listProc.running = true
    }

    property Timer pollTimer: Timer {
        interval: 1000
        running: root.visible && !root.anyDragging
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function toggle() {
        root.visible = !root.visible
    }

    property Process setVolProc: Process { command: [] }
    function setVolume(streamId, pct) {
        setVolProc.command = ["pactl", "set-sink-input-volume", String(streamId), pct + "%"]
        setVolProc.running = true
    }

    property Process toggleMuteProc: Process { command: [] }
    function toggleMute(streamId) {
        toggleMuteProc.command = ["pactl", "set-sink-input-mute", String(streamId), "toggle"]
        toggleMuteProc.running = true
        refreshDelay.restart()
    }

    property Timer refreshDelay: Timer {
        interval: 150
        onTriggered: root.refresh()
    }
}