// modules/deskwidgets/CalendarWidget.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    id: root

    property date now: new Date()
    readonly property var cells: buildDays(now.getMonth(), now.getFullYear())

    function buildDays(month, year) {
        const leadCount = TimeFormat.leadDays(new Date(year, month, 1).getDay())
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrev = new Date(year, month, 0).getDate()
        const today = new Date()
        const out = []

        for (let i = leadCount; i > 0; i--)
            out.push({ day: daysInPrev - i + 1, current: false, isToday: false })
        for (let d = 1; d <= daysInMonth; d++) {
            const isToday = d === today.getDate() && month === today.getMonth() && year === today.getFullYear()
            out.push({ day: d, current: true, isToday: isToday })
        }
        let next = 1
        while (out.length < 42) out.push({ day: next++, current: false, isToday: false })
        return out
    }

    Timer {
        interval: 60000
        repeat: true
        running: SettingsState.showCalendarWidget
        onTriggered: root.now = new Date()
    }

    Variants {
        model: Quickshell.screens

        DeskCard {
            property var modelData
            screen: modelData

            widgetId: "calendar"
            shown: SettingsState.showCalendarWidget
            corner: SettingsState.calendarWidgetCorner
            cardWidth: Math.round(250 * SettingsState.scaleFactor)

            Text {
                text: I18n.tArr("monthNames")[root.now.getMonth()] + " " + root.now.getFullYear()
                color: "#F5F5F5"
                font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                font.bold: true
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.round(6 * SettingsState.scaleFactor)
                columns: 7
                rowSpacing: Math.round(2 * SettingsState.scaleFactor)
                columnSpacing: Math.round(2 * SettingsState.scaleFactor)

                Repeater {
                    model: 7

                    Text {
                        text: TimeFormat.weekdayLabel(index)
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(9 * SettingsState.scaleFactor)
                        font.bold: true
                        Layout.preferredWidth: Math.round(28 * SettingsState.scaleFactor)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Repeater {
                    model: root.cells

                    Rectangle {
                        Layout.preferredWidth: Math.round(28 * SettingsState.scaleFactor)
                        Layout.preferredHeight: Math.round(22 * SettingsState.scaleFactor)
                        radius: Math.round(5 * SettingsState.scaleFactor)
                        color: modelData.isToday ? Colors.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.isToday
                                ? Colors.accentText
                                : (modelData.current ? "#F5F5F5" : Colors.foregroundMuted)
                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                            font.bold: modelData.isToday
                        }
                    }
                }
            }
        }
    }
}
