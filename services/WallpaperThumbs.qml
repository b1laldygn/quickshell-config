// services/WallpaperThumbs.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string sourceDir: "/home/bilal/Pictures/wallpaper"
    readonly property string thumbDir: "/home/bilal/.cache/quickshell/wallpaper-thumbs"

    property Process genProc: Process {
        command: [
            "sh", "-c",
            'exec "$HOME/.config/hypr/scripts/make-wallpaper-thumbs.sh" "$1" "$2"',
            "_", root.sourceDir, root.thumbDir
        ]
    }

    function generate() {
        if (genProc.running) {
            genProc.terminate()
        }
        genProc.running = true
    }

    Component.onCompleted: {
        generate()
    }
}