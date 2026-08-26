// config/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    // --- Ham palet (Catppuccin Mocha) ---
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"

    readonly property color blue: "#89b4fa"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"

    // --- Anlamsal isimler (widget'larda bunları kullan) ---
    readonly property color background: base
    readonly property color backgroundAlt: mantle
    readonly property color foreground: text
    readonly property color foregroundMuted: subtext

    readonly property color accent: blue
    readonly property color accentText: base   // accent üstü metin (koyu zeminde okunaklı)

    readonly property color hover: surface0
    readonly property color active: surface1
    readonly property color border: surface1

    readonly property color danger: red
    readonly property color warning: yellow
    readonly property color success: green
}