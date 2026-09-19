// modules/mixer/MixerIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "mixer"

    function toggle(): void {
        AudioMixerState.toggle()
        if (AudioMixerState.visible) AudioMixerState.refresh()
    }

    function open(): void {
        AudioMixerState.visible = true
        AudioMixerState.refresh()
    }

    function close(): void {
        AudioMixerState.visible = false
    }
}