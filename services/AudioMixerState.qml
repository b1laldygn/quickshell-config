// services/AudioMixerState.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "root:/services"

QtObject {
    id: root

    property bool visible: false
    property bool anyDragging: false
    property var streams: []

    property real masterVolume: 0.5
    property bool masterMuted: false
    property bool initialized: false

    // ---- EVENT-DRIVEN AUDIO LISTENER (pactl subscribe) ----
    property Process subscribeProc: Process {
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const line = data.trim()
                if (line.includes("sink") || line.includes("server")) {
                    sinkDebounce.restart()
                }
                if (line.includes("sink-input")) {
                    if (root.visible || AudioDeviceListState.visible) {
                        streamDebounce.restart()
                    }
                }
            }
        }
        onExited: restartTimer.restart()
    }

    property Timer restartTimer: Timer {
        interval: 1000
        onTriggered: {
            if (!subscribeProc.running) subscribeProc.running = true
        }
    }

    property Timer sinkDebounce: Timer {
        interval: 40
        onTriggered: {
            if (!root.anyDragging) {
                root.refreshMaster()
            }
        }
    }

    property Timer streamDebounce: Timer {
        interval: 60
        onTriggered: {
            if (!root.anyDragging) {
                root.refresh()
            }
        }
    }

    // Uygulama sesleri (sink-inputs) listesini alma
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
        if (!listProc.running) listProc.running = true
    }

    // Mikser paneli açıldığında verileri anında tazele
    onVisibleChanged: {
        if (visible) {
            root.refreshMaster()
            root.refresh()
        }
    }

    function toggle() {
        root.visible = !root.visible
    }

    // Uygulama ses seviyesi değiştirme
    property Process setVolProc: Process { command: [] }
    function setVolume(streamId, pct) {
        setVolProc.command = ["pactl", "set-sink-input-volume", String(streamId), pct + "%"]
        setVolProc.running = true
    }

    // Uygulama sessize alma
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

    // Master ses seviyesini okuma
    property Process masterVolProc: Process {
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/(\d+)%/)
                if (match) {
                    const newVol = parseInt(match[1]) / 100
                    if (root.initialized && !root.anyDragging && Math.abs(newVol - root.masterVolume) > 0.001) {
                        if (!root.visible && !AudioDeviceListState.visible) {
                            OsdService.show("volume", newVol)
                        }
                    }
                    root.masterVolume = newVol
                    root.initialized = true
                }
            }
        }
    }

    // Master sessize alma durumunu okuma
    property Process masterMuteProc: Process {
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const muted = this.text.includes("yes")
                if (root.initialized && !root.anyDragging && muted !== root.masterMuted) {
                    if (!root.visible && !AudioDeviceListState.visible) {
                        OsdService.show("volume", muted ? 0 : root.masterVolume)
                    }
                }
                root.masterMuted = muted
            }
        }
    }

    function refreshMaster() {
        if (!masterVolProc.running) masterVolProc.running = true
        if (!masterMuteProc.running) masterMuteProc.running = true
    }

    // Master ses seviyesini ayarlama
    property Process setMasterVolProc: Process { command: [] }
    function setMasterVolume(pct) {
        setMasterVolProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", pct + "%"]
        setMasterVolProc.running = true
    }

    // Master sessize alma/açma
    property Process toggleMasterMuteProc: Process { command: [] }
    function toggleMasterMute() {
        toggleMasterMuteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        toggleMasterMuteProc.running = true
    }

    Component.onCompleted: {
        root.refreshMaster()
    }
}
