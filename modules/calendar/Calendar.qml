// modules/calendar/Calendar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: CalendarState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: CalendarState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            function buildDays(month, year) {
                const firstOfMonth = new Date(year, month, 1)
                const jsWeekday = firstOfMonth.getDay()
                const leadCount = TimeFormat.leadDays(jsWeekday)
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

            Item {
                anchors.fill: parent
                focus: CalendarState.visible
                Keys.onEscapePressed: CalendarState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: CalendarState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    width: Math.round(300 * s)
                    height: Math.round(335 * s)
                    radius: Math.round(14 * s)
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transformOrigin: Item.Top
                    transform: Translate { y: fx.cardY }

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.round(14 * card.s)
                        spacing: Math.round(10 * card.s)

                        // ── Başlık ve Ay Navigasyonu ─────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(6 * card.s)

                            Rectangle {
                                width: Math.round(26 * card.s)
                                height: width
                                radius: Math.round(7 * card.s)
                                color: prevHover.containsMouse ? Colors.hover : Colors.surface0
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "‹"
                                    color: Colors.foreground
                                    font.pixelSize: Math.round(16 * card.s)
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
                                text: I18n.tArr("monthNames")[CalendarState.viewMonth] + " " + CalendarState.viewYear
                                color: Colors.foreground
                                font.pixelSize: Math.round(13 * card.s)
                                font.bold: true
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                width: Math.round(26 * card.s)
                                height: width
                                radius: Math.round(7 * card.s)
                                color: nextHover.containsMouse ? Colors.hover : Colors.surface0
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "›"
                                    color: Colors.foreground
                                    font.pixelSize: Math.round(16 * card.s)
                                }

                                MouseArea {
                                    id: nextHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CalendarState.nextMonth()
                                }
                            }

                            Rectangle {
                                width: todayTxt.implicitWidth + Math.round(12 * card.s)
                                height: Math.round(24 * card.s)
                                radius: Math.round(6 * card.s)
                                color: todayHover.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

                                Text {
                                    id: todayTxt
                                    anchors.centerIn: parent
                                    text: I18n.t("today")
                                    color: todayHover.containsMouse ? Colors.accentText : Colors.accent
                                    font.pixelSize: Math.round(10 * card.s)
                                    font.bold: true
                                }

                                MouseArea {
                                    id: todayHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const now = new Date()
                                        CalendarState.viewMonth = now.getMonth()
                                        CalendarState.viewYear = now.getFullYear()
                                    }
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
                                rowSpacing: Math.round(4 * card.s)
                                columnSpacing: Math.round(4 * card.s)

                                Repeater {
                                    model: 7
                                    Text {
                                        text: TimeFormat.weekdayLabel(index)
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(10 * card.s)
                                        font.bold: true
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Repeater {
                                    model: calWindow.dayCells

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.round(30 * card.s)
                                        radius: Math.round(7 * card.s)
                                        color: modelData.isToday
                                            ? Colors.accent
                                            : (dayHover.containsMouse && modelData.current ? Colors.hover : "transparent")

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: modelData.isToday
                                                ? Colors.accentText
                                                : (modelData.current ? Colors.foreground : Colors.foregroundMuted)
                                            opacity: modelData.current ? 1.0 : 0.45
                                            font.pixelSize: Math.round(11 * card.s)
                                            font.bold: modelData.isToday
                                        }

                                        MouseArea {
                                            id: dayHover
                                            anchors.fill: parent
                                            hoverEnabled: true
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
}
