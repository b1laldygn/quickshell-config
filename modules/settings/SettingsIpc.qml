// modules/settings/SettingsIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"

IpcHandler {
    target: "settings"

    function toggle(): void {
        SettingsState.settingsVisible = !SettingsState.settingsVisible
    }

    function open(): void { SettingsState.settingsVisible = true }
    function close(): void { SettingsState.settingsVisible = false }
}