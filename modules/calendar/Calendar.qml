// modules/calendar/Calendar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calWindow
            property var modelData
            screen: modelData

            // Pencere kapanış animasyonu bitene kadar açık kalsın
            property bool showWindow: false
            visible: showWindow

            onVisibleChanged: {}

            Connections {
                target: CalendarState
                function onVisibleChanged() {
                    if (CalendarState.visible) {
                        calWindow.showWindow = true
                    } else {
                        hideTimer.restart()
                    }
                }
            }

            Timer {
                id: hideTimer
                interval: 220
                onTriggered: calWindow.showWindow = false
            }

            anchors { top: true }
            margins.top: 44

            implicitWidth: 280
            implicitHeight: 320
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            readonly property var monthNames: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                                                "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
            readonly property var dayNames: ["Pzt", "Sal", "Çrş", "Prş", "Cum", "Cmt", "Paz"]

            function buildDays(month, year) {
                const firstOfMonth = new Date(year, month, 1)
                const jsWeekday = firstOfMonth.getDay()
                const leadCount = (jsWeekday + 6) % 7
                const daysInMonth = new Date(year, month + 1, 0).getDate()
                const daysInPrevMonth = new Date(year, month, 0).getDate()

                const today = new Date()
                const cells = []

                for (let i = leadCount; i > 0; i--) {
                    cells.push({ day: daysInPrevMonth - i + 1, current: false, isToday: false })
                }
                for (let d = 1; d <= daysInMonth; d++) {
                    const isToday = d === today.getDate() && month === today.getMonth() && year === today.getFullYear()
                    cells.push({ day: d, current: true, isToday: isToday })
                }
                let nextDay = 1
                while (cells.length < 42) {
                    cells.push({ day: nextDay, current: false, isToday: false })
                    nextDay++
                }
                return cells
            }

            property var dayCells: buildDays(CalendarState.viewMonth, CalendarState.viewYear)

            onDayCellsChanged: monthFade.restart()

            SequentialAnimation {
                id: monthFade
                NumberAnimation { target: gridWrapper; property: "opacity"; to: 0.15; duration: 80; easing.type: Easing.OutCubic }
                NumberAnimation { target: gridWrapper; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                opacity: CalendarState.visible ? 1 : 0
                scale: CalendarState.visible ? 1 : 0.92
                y: CalendarState.visible ? 0 : -12
                transformOrigin: Item.Top

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: prevHover.containsMouse ? Colors.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "‹"
                                color: "#F5F5F5"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: prevHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarState.prevMonth()
                            }
                        }

                        Text {
                            text: calWindow.monthNames[CalendarState.viewMonth] + " " + CalendarState.viewYear
                            color: "#F5F5F5"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: nextHover.containsMouse ? Colors.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "›"
                                color: "#F5F5F5"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: nextHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarState.nextMonth()
                            }
                        }
                    }

                    Item {
                        id: gridWrapper
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GridLayout {
                            anchors.fill: parent
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: 7
                                Text {
                                    text: calWindow.dayNames[index]
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                    Layout.preferredWidth: 32
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Repeater {
                                model: calWindow.dayCells

                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: modelData.isToday ? Colors.accent : "transparent"

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        color: modelData.isToday
                                            ? Colors.accentText
                                            : (modelData.current ? "#F5F5F5" : Colors.foregroundMuted)
                                        font.pixelSize: 11
                                        font.bold: modelData.isToday
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}