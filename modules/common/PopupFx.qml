// modules/common/PopupFx.qml
import QtQuick
import "root:/services"

Item {
    id: fx

    // Pop-up'ın durumu: true olunca açılır, false olunca kapanış animasyonu oynar
    property bool open: false
    // Pencerenin görünür olması gereken süre (kapanış animasyonu bitene kadar true kalır)
    property bool shown: false
    property real progress: 0

    readonly property string style: SettingsState.popupAnimation
    readonly property int baseDuration: SettingsState.popupAnimDuration

    // Kartın kullanacağı değerler
    readonly property real cardOpacity: {
        if (style === "none") return 1
        if (style === "fade") return Math.max(0, Math.min(1, progress))
        return Math.max(0, Math.min(1, progress * 1.4))
    }

    readonly property real cardY: {
        switch (style) {
        case "slide": return (1 - progress) * -26
        case "drop": return (1 - progress) * -70
        default: return 0
        }
    }

    readonly property real cardScale: {
        switch (style) {
        case "scale": return 0.9 + 0.1 * progress
        case "pop": return 0.75 + 0.25 * progress
        default: return 1
        }
    }

    function easingFor(opening) {
        if (!opening) return Easing.InCubic
        switch (style) {
        case "pop": return Easing.OutBack
        case "drop": return Easing.OutBounce
        default: return Easing.OutCubic
        }
    }

    NumberAnimation {
        id: anim
        target: fx
        property: "progress"
        onFinished: {
            if (!fx.open) fx.shown = false
        }
    }

    onOpenChanged: {
        anim.stop()
        if (open) shown = true

        if (style === "none" || baseDuration <= 0) {
            progress = open ? 1 : 0
            if (!open) shown = false
            return
        }

        anim.to = open ? 1 : 0
        anim.duration = open ? baseDuration : Math.round(baseDuration * 0.7)
        anim.easing.type = easingFor(open)
        if (open && style === "pop") anim.easing.overshoot = 1.5
        anim.restart()
    }

    Component.onCompleted: {
        if (open) {
            shown = true
            progress = 1
        }
    }
}