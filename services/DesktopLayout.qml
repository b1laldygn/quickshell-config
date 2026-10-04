// services/DesktopLayout.qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    // Köşeye en yakın olan önce gelir
    readonly property var order: ["weather", "clock", "system", "media", "calendar"]
    readonly property int gap: 12

    property var heights: ({})
    property int version: 0

    function report(id, h) {
        if (root.heights[id] === h) return
        root.heights[id] = h
        root.version++
    }

    function cornerOf(id) {
        switch (id) {
        case "weather": return SettingsState.desktopWidgetCorner
        case "clock": return SettingsState.clockWidgetCorner
        case "system": return SettingsState.systemWidgetCorner
        case "media": return SettingsState.mediaWidgetCorner
        case "calendar": return SettingsState.calendarWidgetCorner
        }
        return ""
    }

    function offsetFor(id) {
        void root.version
        const mine = cornerOf(id)
        let sum = 0
        for (const other of root.order) {
            if (other === id) break
            const h = root.heights[other] || 0
            if (h > 0 && cornerOf(other) === mine) sum += h + root.gap
        }
        return sum
    }
}