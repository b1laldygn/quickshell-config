// services/WallpaperThumbs.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string home: "/home/bilal"
    readonly property string sourceDir: {
        const d = SettingsState.wallpaperDir.trim().replace(/\/+$/, "")
        return d.startsWith("~") ? home + d.slice(1) : d
    }
    readonly property string thumbDir: home + "/.cache/quickshell/wallpaper-thumbs"

    property int imageCount: 0      // -1: klasör bulunamadı
    property bool rerun: false

    property Process genProc: Process {
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(this.text.trim().split("\n").pop())
                root.imageCount = isNaN(n) ? 0 : n
            }
        }
        onExited: {
            if (root.rerun) {
                root.rerun = false
                root.start()
            }
        }
    }

    function start() {
        genProc.command = [
            "sh", "-c",
            'exec "$HOME/.config/hypr/scripts/make-wallpaper-thumbs.sh" "$1" "$2"',
            "_", root.sourceDir, root.thumbDir
        ]
        genProc.running = true
    }

    function generate() {
        if (genProc.running) root.rerun = true
        else root.start()
    }

    onSourceDirChanged: generate()
    Component.onCompleted: start()
}