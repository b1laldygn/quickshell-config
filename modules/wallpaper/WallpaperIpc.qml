// modules/wallpaper/WallpaperIpc.qml
import Quickshell
import Quickshell.Io
import "root:/services"    // ← bu satırı ekle

IpcHandler {
    target: "wallpaper"

    function toggle(): void {
        WallpaperPickerState.visible = !WallpaperPickerState.visible
    }

    function open(): void {
        WallpaperPickerState.visible = true
    }

    function close(): void {
        WallpaperPickerState.visible = false
    }
}