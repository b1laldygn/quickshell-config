// services/CalendarState.qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false
    property date today: new Date()
    property int viewMonth: today.getMonth()
    property int viewYear: today.getFullYear()

    function toggle() {
        root.visible = !root.visible
        if (root.visible) {
            root.viewMonth = root.today.getMonth()
            root.viewYear = root.today.getFullYear()
        }
    }

    function nextMonth() {
        if (root.viewMonth === 11) {
            root.viewMonth = 0
            root.viewYear++
        } else {
            root.viewMonth++
        }
    }

    function prevMonth() {
        if (root.viewMonth === 0) {
            root.viewMonth = 11
            root.viewYear--
        } else {
            root.viewMonth--
        }
    }
}