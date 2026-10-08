// services/TimeFormat.qml
pragma Singleton
import QtQuick

QtObject {
    function pad(n) { return n < 10 ? "0" + n : String(n) }

    function hour(d) {
        if (SettingsState.use24h) return pad(d.getHours())
        const h = d.getHours() % 12
        return String(h === 0 ? 12 : h)
    }

    function hm(d) { return hour(d) + ":" + pad(d.getMinutes()) }
    function seconds(d) { return pad(d.getSeconds()) }
    function suffix(d) { return SettingsState.use24h ? "" : (d.getHours() >= 12 ? "PM" : "AM") }

    // "17:03", "17:03:09", "5:03 PM", "5:03:09 PM"
    function full(d, withSeconds) {
        let s = hm(d)
        if (withSeconds) s += ":" + seconds(d)
        const sf = suffix(d)
        return sf !== "" ? s + " " + sf : s
    }

    function dateText(d) { return dateTextFor(d, SettingsState.dateFormat) }

    function dateTextFor(d, fmt) {
        const months = I18n.tArr("monthNames")
        const days = I18n.tArr("dayNamesLong")
        const weekday = days[(d.getDay() + 6) % 7]
        const month = months[d.getMonth()]
        switch (fmt) {
        case "medium": return d.getDate() + " " + month + " " + d.getFullYear()
        case "numeric": return pad(d.getDate()) + "." + pad(d.getMonth() + 1) + "." + d.getFullYear()
        case "iso": return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
        default: return weekday + ", " + d.getDate() + " " + month
        }
    }

    function weekStartDay() { return SettingsState.weekStart === "sun" ? 0 : 1 }
    function leadDays(jsWeekday) { return (jsWeekday - weekStartDay() + 7) % 7 }

    function weekdayLabel(i) {
        const names = I18n.tArr("dayNames")
        return names[(i + (weekStartDay() === 0 ? 6 : 0)) % 7]
    }
}