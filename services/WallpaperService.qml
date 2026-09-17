// services/WallpaperService.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string currentWallpaperPath: ""

    property Process applyProc: Process {
        command: []
    }

    property Process saveProc: Process {
        command: []
    }

    property Process restoreProc: Process {
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim()
                if (path.length > 0) {
                    root.applyWallpaper(path)
                }
            }
        }
    }

    function applyWallpaper(path) {
        root.currentWallpaperPath = path
        applyProc.command = [
            "swww", "img", path,
            "--transition-type", "fade",
            "--transition-duration", "1"
        ]
        applyProc.running = true
    }

    function setWallpaper(path) {
        applyWallpaper(path)

        saveProc.command = [
            "sh", "-c",
            'mkdir -p "$HOME/.cache/quickshell" && printf "%s" "$1" > "$HOME/.cache/quickshell/last_wallpaper"',
            "_", path
        ]
        saveProc.running = true
    }

    function restoreLastWallpaper() {
        restoreProc.command = [
            "sh", "-c",
            'cat "$HOME/.cache/quickshell/last_wallpaper" 2>/dev/null'
        ]
        restoreProc.running = true
    }
}