// modules/bar/BatteryIndicator.qml
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

RowLayout {
    id: root
    spacing: 4
    visible: Battery.available   // laptop değilse widget tamamen gizlenir

    Text {
        text: {
            if (Battery.charging) return "󰂄"
            const p = Battery.percentage
            if (p >= 0.9) return "󰁹"
            if (p >= 0.6) return "󰂀"
            if (p >= 0.3) return "󰁾"
            if (p >= 0.15) return "󰁻"
            return "󰁺"
        }
        color: Battery.percentage < 0.15 && !Battery.charging ? Colors.danger : Colors.foreground
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
    }

    Text {
        text: Math.round(Battery.percentage * 100) + "%"
        color: Colors.foreground
        font.pixelSize: 11
    }
}