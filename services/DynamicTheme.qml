// services/DynamicTheme.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "root:/config"

QtObject {
    id: root

    function hexToRgb(hex) {
        const h = hex.replace("#", "")
        return {
            r: parseInt(h.substring(0, 2), 16),
            g: parseInt(h.substring(2, 4), 16),
            b: parseInt(h.substring(4, 6), 16)
        }
    }

    function luminance(rgb) {
        return 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
    }

    function saturation(rgb) {
        const r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255
        return Math.max(r, g, b) - Math.min(r, g, b)
    }

    function toHex(v) {
        const clamped = Math.max(0, Math.min(255, Math.round(v)))
        return clamped.toString(16).padStart(2, "0")
    }

    function mix(hex1, hex2, t) {
        const c1 = hexToRgb(hex1), c2 = hexToRgb(hex2)
        const r = c1.r + (c2.r - c1.r) * t
        const g = c1.g + (c2.g - c1.g) * t
        const b = c1.b + (c2.b - c1.b) * t
        return "#" + toHex(r) + toHex(g) + toHex(b)
    }

    property Process extractProc: Process {
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const colorList = this.text.trim().split("\n").filter(l => l.startsWith("#"))
                if (colorList.length < 3) return   // yeterli renk çıkmadıysa dokunma, fallback kalsın

                const withLum = colorList.map(hex => ({
                    hex: hex,
                    lum: root.luminance(root.hexToRgb(hex)),
                    sat: root.saturation(root.hexToRgb(hex))
                }))
                withLum.sort((a, b) => a.lum - b.lum)

                const darkest = withLum[0].hex
                const lightest = withLum[withLum.length - 1].hex
                const mostSaturated = withLum.reduce((max, c) => c.sat > max.sat ? c : max, withLum[0])

                const background = root.mix(darkest, "#000000", 0.2)
                const backgroundAlt = root.mix(darkest, "#000000", 0.35)
                const foreground = root.mix(lightest, "#ffffff", 0.35)
                const accent = mostSaturated.hex
                const accentLum = root.luminance(root.hexToRgb(accent))
                const accentText = accentLum > 140 ? "#111111" : "#ffffff"
                const hover = root.mix(background, accent, 0.15)
                const active = root.mix(background, accent, 0.28)
                const border = root.mix(background, "#ffffff", 0.12)

                Colors.applyPalette({
                    background: background,
                    backgroundAlt: backgroundAlt,
                    foreground: foreground,
                    foregroundMuted: root.mix(foreground, background, 0.4),
                    accent: accent,
                    accentText: accentText,
                    hover: hover,
                    active: active,
                    border: border
                })
            }
        }
    }

    function generateFromWallpaper(path) {
        extractProc.command = ["sh", "-c", 'exec ~/.config/hypr/scripts/extract-colors.sh "$1"', "_", path]
        extractProc.running = true
    }
}