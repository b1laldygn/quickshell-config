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
        const leadCount = (new Date(year, month, 1).getDay() + 6) % 7
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
            cardWidth: 250

            Text {
                text: I18n.tArr("monthNames")[root.now.getMonth()] + " " + root.now.getFullYear()
                color: "#F5F5F5"
                font.pixelSize: 14
                font.bold: true
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: 7

                    Text {
                        text: I18n.tArr("dayNames")[index]
                        color: Colors.foregroundMuted
                        font.pixelSize: 9
                        font.bold: true
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Repeater {
                    model: root.cells

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 22
                        radius: 5
                        color: modelData.isToday ? Colors.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.isToday
                                ? Colors.accentText
                                : (modelData.current ? "#F5F5F5" : Colors.foregroundMuted)
                            font.pixelSize: 10
                            font.bold: modelData.isToday
                        }
                    }
                }
            }
        }
    }
}