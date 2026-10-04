// services/SettingsState.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "root:/config"

QtObject {
    id: root

    // ---- Bar widget görünürlükleri ----
    property bool showWeather: true
    property bool showSystemMonitor: true
    property bool showMediaControls: true
    property bool showBattery: true
    property bool showNotificationBell: true
    property bool showSysTray: true

    // ---- Tema ----
    property bool useDynamicTheme: true
    property string fixedAccentColor: "#89b4fa"
    property string language: "tr"

    // ---- Genel / performans ----
    property int volumePollInterval: 50
    property int brightnessPollInterval: 50
    property int weatherRefreshMinutes: 30

    // ---- Duvar kağıdı ----
    property string wallpaperTransition: "fade"
    property real wallpaperTransitionDuration: 1.0

    // ---- Masaüstü widget'ları ----
    property bool showDesktopWidgets: true            // hava durumu kartı
    property string desktopWidgetCorner: "top-right"
    property bool showClockWidget: true
    property string clockStyle: "digital"             // "digital" | "analog"
    property string clockWidgetCorner: "bottom-right"
    property bool showSystemWidget: true
    property string systemWidgetCorner: "top-left"
    property bool showMediaWidget: true
    property string mediaWidgetCorner: "bottom-left"
    property bool showCalendarWidget: false
    property string calendarWidgetCorner: "top-left"

    property bool settingsVisible: false
    property bool loaded: false

    readonly property var persistedKeys: [
        "showWeather", "showSystemMonitor", "showMediaControls", "showBattery",
        "showNotificationBell", "showSysTray",
        "useDynamicTheme", "fixedAccentColor", "language",
        "volumePollInterval", "brightnessPollInterval", "weatherRefreshMinutes",
        "wallpaperTransition", "wallpaperTransitionDuration",
        "showDesktopWidgets", "desktopWidgetCorner",
        "showClockWidget", "clockStyle", "clockWidgetCorner",
        "showSystemWidget", "systemWidgetCorner",
        "showMediaWidget", "mediaWidgetCorner",
        "showCalendarWidget", "calendarWidgetCorner"
    ]

    property Process saveProc: Process { command: [] }

    function save() {
        const data = {}
        for (const k of root.persistedKeys) data[k] = root[k]
        saveProc.command = [
            "sh", "-c",
            'mkdir -p "$HOME/.config/quickshell/myconfig" && printf "%s" "$1" > "$HOME/.config/quickshell/myconfig/settings.json"',
            "_", JSON.stringify(data)
        ]
        saveProc.running = true
    }

    property Process loadProc: Process {
        command: ["sh", "-c", 'cat "$HOME/.config/quickshell/myconfig/settings.json" 2>/dev/null']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    try {
                        const d = JSON.parse(this.text)
                        for (const k of root.persistedKeys) {
                            if (d[k] !== undefined) root[k] = d[k]
                        }
                    } catch (e) {}
                }
                root.loaded = true
                if (!root.useDynamicTheme) root.applyFixedAccent()
            }
        }
    }

    function applyFixedAccent() {
        const accent = root.fixedAccentColor
        Colors.applyPalette({
            background: Colors.background,
            backgroundAlt: Colors.backgroundAlt,
            foreground: Colors.foreground,
            foregroundMuted: Colors.foregroundMuted,
            accent: accent,
            accentText: DynamicTheme.luminance(DynamicTheme.hexToRgb(accent)) > 140 ? "#111111" : "#ffffff",
            hover: DynamicTheme.mix(Colors.background, accent, 0.15),
            active: DynamicTheme.mix(Colors.background, accent, 0.28),
            border: Colors.border
        })
    }
}