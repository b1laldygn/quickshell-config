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
    property string fixedBackgroundColor: "#1e1e2e"
    property string language: "tr"

    // ---- Bar ----
    property int barHeight: 34
    property int barOpacity: 100

    // ---- Genel / performans ----
    property int volumePollInterval: 50
    property int brightnessPollInterval: 50
    property int weatherRefreshMinutes: 30

    // ---- Duvar kağıdı ----
    property string wallpaperTransition: "fade"
    property real wallpaperTransitionDuration: 1.0
    property string wallpaperDir: "/home/bilal/Pictures/wallpaper"

    // ---- Masaüstü widget'ları ----
    property bool showDesktopWidgets: true
    property string desktopWidgetCorner: "top-right"
    property bool showClockWidget: true
    property string clockStyle: "digital"
    property string clockWidgetCorner: "bottom-right"
    property bool showSystemWidget: true
    property string systemWidgetCorner: "top-left"
    property bool showMediaWidget: true
    property string mediaWidgetCorner: "bottom-left"
    property bool showCalendarWidget: false
    property string calendarWidgetCorner: "top-left"

    // ---- Tarih ve saat ----
    property bool use24h: true
    property bool barClockSeconds: false
    property bool deskClockSeconds: true
    property string dateFormat: "long"       // long | medium | numeric | iso
    property string weekStart: "mon"         // mon | sun

    // ---- Bildirimler ----
    property int notificationTimeout: 5
    property int notificationHistoryLimit: 50

    property bool settingsVisible: false
    property bool loaded: false

    readonly property var persistedKeys: [
        "showWeather", "showSystemMonitor", "showMediaControls", "showBattery",
        "showNotificationBell", "showSysTray",
        "useDynamicTheme", "fixedAccentColor", "fixedBackgroundColor", "language",
        "barHeight", "barOpacity",
        "volumePollInterval", "brightnessPollInterval", "weatherRefreshMinutes",
        "wallpaperTransition", "wallpaperTransitionDuration", "wallpaperDir",
        "showDesktopWidgets", "desktopWidgetCorner",
        "showClockWidget", "clockStyle", "clockWidgetCorner",
        "showSystemWidget", "systemWidgetCorner",
        "showMediaWidget", "mediaWidgetCorner",
        "showCalendarWidget", "calendarWidgetCorner",
        "use24h", "barClockSeconds", "deskClockSeconds", "dateFormat", "weekStart",
        "notificationTimeout", "notificationHistoryLimit"
    ]

    property Process saveProc: Process { command: [] }

    property Timer saveDebounce: Timer {
        interval: 400
        onTriggered: root.writeToDisk()
    }

    function save() { saveDebounce.restart() }

    function writeToDisk() {
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
                if (!root.useDynamicTheme) root.applyFixedTheme()
            }
        }
    }

    function applyFixedTheme() {
        const bg = root.fixedBackgroundColor
        const accent = root.fixedAccentColor
        DynamicTheme.applyColors(
            bg,
            DynamicTheme.mix(bg, "#000000", 0.25),
            DynamicTheme.mix("#ffffff", bg, 0.08),
            accent
        )
    }
}