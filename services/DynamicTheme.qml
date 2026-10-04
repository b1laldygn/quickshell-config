// services/DynamicTheme.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "root:/config"
import "root:/services"
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

    function rgbToHsl(rgb) {
        const r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255
        const max = Math.max(r, g, b), min = Math.min(r, g, b)
        let h = 0, s = 0
        const l = (max + min) / 2
        const d = max - min
        if (d !== 0) {
            s = d / (1 - Math.abs(2 * l - 1))
            if (max === r) h = 60 * (((g - b) / d) % 6)
            else if (max === g) h = 60 * ((b - r) / d + 2)
            else h = 60 * ((r - g) / d + 4)
        }
        if (h < 0) h += 360
        return { h: h, s: s * 100, l: l * 100 }
    }

    function hslToHex(h, s, l) {
        s /= 100; l /= 100
        const c = (1 - Math.abs(2 * l - 1)) * s
        const x = c * (1 - Math.abs((h / 60) % 2 - 1))
        const m = l - c / 2
        let r = 0, g = 0, b = 0
        if (h < 60) { r = c; g = x; b = 0 }
        else if (h < 120) { r = x; g = c; b = 0 }
        else if (h < 180) { r = 0; g = c; b = x }
        else if (h < 240) { r = 0; g = x; b = c }
        else if (h < 300) { r = x; g = 0; b = c }
        else { r = c; g = 0; b = x }
        return "#" + toHex((r + m) * 255) + toHex((g + m) * 255) + toHex((b + m) * 255)
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
                if (!SettingsState.useDynamicTheme) return

                const colorList = this.text.trim().split("\n").filter(l => l.startsWith("#"))
                if (colorList.length < 3) return

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

                const accentHsl = root.rgbToHsl(root.hexToRgb(accent))
                const sat = Math.max(40, Math.min(70, accentHsl.s))
                const dimLight = 45
                const brightLight = 65

                const footColors = {
                    background: background,
                    foreground: root.mix(foreground, "#ffffff", 0.1),
                    color0: root.mix(background, "#000000", 0.4),
                    color1: root.hslToHex(0, sat, dimLight),
                    color2: root.hslToHex(120, sat, dimLight),
                    color3: root.hslToHex(60, sat, dimLight),
                    color4: root.hslToHex(240, sat, dimLight),
                    color5: root.hslToHex(300, sat, dimLight),
                    color6: root.hslToHex(180, sat, dimLight),
                    color7: root.mix(foreground, "#ffffff", 0.15),
                    color8: root.mix(background, "#ffffff", 0.25),
                    color9: root.hslToHex(0, sat, brightLight),
                    color10: root.hslToHex(120, sat, brightLight),
                    color11: root.hslToHex(60, sat, brightLight),
                    color12: root.hslToHex(240, sat, brightLight),
                    color13: root.hslToHex(300, sat, brightLight),
                    color14: root.hslToHex(180, sat, brightLight),
                    color15: root.mix(foreground, "#ffffff", 0.7)
                }

                root.writeFootTheme(footColors)
            }
        }
    }

    function generateFromWallpaper(path) {
        extractProc.command = ["sh", "-c", 'exec ~/.config/hypr/scripts/extract-colors.sh "$1"', "_", path]
        extractProc.running = true
    }

    property Process footWriteProc: Process { command: [] }
    property Process footReloadProc: Process { command: ["pkill", "-SIGUSR1", "foot"] }

    function writeFootTheme(c) {
        const stripHash = (hex) => hex.replace("#", "")

        const iniContent =
            "[colors]\n" +
            "background=" + stripHash(c.background) + "\n" +
            "foreground=" + stripHash(c.foreground) + "\n" +
            "regular0=" + stripHash(c.color0) + "\n" +
            "regular1=" + stripHash(c.color1) + "\n" +
            "regular2=" + stripHash(c.color2) + "\n" +
            "regular3=" + stripHash(c.color3) + "\n" +
            "regular4=" + stripHash(c.color4) + "\n" +
            "regular5=" + stripHash(c.color5) + "\n" +
            "regular6=" + stripHash(c.color6) + "\n" +
            "regular7=" + stripHash(c.color7) + "\n" +
            "bright0=" + stripHash(c.color8) + "\n" +
            "bright1=" + stripHash(c.color9) + "\n" +
            "bright2=" + stripHash(c.color10) + "\n" +
            "bright3=" + stripHash(c.color11) + "\n" +
            "bright4=" + stripHash(c.color12) + "\n" +
            "bright5=" + stripHash(c.color13) + "\n" +
            "bright6=" + stripHash(c.color14) + "\n" +
            "bright7=" + stripHash(c.color15) + "\n"

        footWriteProc.command = [
            "sh", "-c",
            'mkdir -p "$HOME/.config/foot" && cat > "$HOME/.config/foot/colors-dynamic.ini" << EOF\n' + iniContent + 'EOF'
        ]
        footWriteProc.running = true
        footReloadDelay.restart()
    }

    property Timer footReloadDelay: Timer {
        interval: 200
        onTriggered: footReloadProc.running = true
    }
}