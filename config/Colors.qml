// config/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    // --- Ham palet (varsayılan: Catppuccin Mocha, wallpaper üretimi başarısız olursa fallback) ---
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"

    property color text: "#cdd6f4"
    property color subtext: "#a6adc8"

    property color blue: "#89b4fa"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"

    // --- Anlamsal isimler (widget'larda bunları kullan) ---
    property color background: base
    property color backgroundAlt: mantle
    property color foreground: text
    property color foregroundMuted: subtext

    property color accent: blue
    property color accentText: base

    property color hover: surface0
    property color active: surface1
    property color border: surface1

    property color danger: red
    property color warning: yellow
    property color success: green

    // Wallpaper'dan üretilen paleti uygula
    function applyPalette(p) {
        background = p.background
        backgroundAlt = p.backgroundAlt
        foreground = p.foreground
        foregroundMuted = p.foregroundMuted
        accent = p.accent
        accentText = p.accentText
        hover = p.hover
        active = p.active
        border = p.border
        surface0 = p.hover
        surface1 = p.active
    }
}