// modules/settings/Settings.qml
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
            id: settingsWindow
            property var modelData
            screen: modelData

            visible: SettingsState.settingsVisible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // ---- Seçenek listeleri (dil değişince otomatik güncellenir) ----
            property var cornerOptions: [
                { label: I18n.t("topLeft"), key: "top-left" },
                { label: I18n.t("topRight"), key: "top-right" },
                { label: I18n.t("bottomLeft"), key: "bottom-left" },
                { label: I18n.t("bottomRight"), key: "bottom-right" }
            ]
            property var clockStyleOptions: [
                { label: I18n.t("digital"), key: "digital" },
                { label: I18n.t("analog"), key: "analog" }
            ]
            property var languageOptions: [
                { label: "Türkçe", key: "tr" },
                { label: "English", key: "en" }
            ]
            property var barToggleDefs: [
                { label: I18n.t("weather"), key: "showWeather" },
                { label: I18n.t("systemMonitor"), key: "showSystemMonitor" },
                { label: I18n.t("mediaControls"), key: "showMediaControls" },
                { label: I18n.t("battery"), key: "showBattery" },
                { label: I18n.t("notificationBell"), key: "showNotificationBell" },
                { label: I18n.t("systemTray"), key: "showSysTray" }
            ]
            property var deskWidgetDefs: [
                { label: I18n.t("weatherCard"), showKey: "showDesktopWidgets", cornerKey: "desktopWidgetCorner", hasStyle: false },
                { label: I18n.t("clockWidget"), showKey: "showClockWidget", cornerKey: "clockWidgetCorner", hasStyle: true },
                { label: I18n.t("systemWidget"), showKey: "showSystemWidget", cornerKey: "systemWidgetCorner", hasStyle: false },
                { label: I18n.t("mediaWidget"), showKey: "showMediaWidget", cornerKey: "mediaWidgetCorner", hasStyle: false },
                { label: I18n.t("calendarWidget"), showKey: "showCalendarWidget", cornerKey: "calendarWidgetCorner", hasStyle: false }
            ]
            property var stepperDefs: [
                { label: I18n.t("volumePollLabel"), key: "volumePollInterval", min: 20, max: 500, step: 10 },
                { label: I18n.t("brightnessPollLabel"), key: "brightnessPollInterval", min: 20, max: 500, step: 10 },
                { label: I18n.t("weatherRefreshLabel"), key: "weatherRefreshMinutes", min: 5, max: 120, step: 5 }
            ]

            // ---- Küçük yeniden kullanılabilir bileşenler ----
            component ToggleSwitch: Rectangle {
                id: sw
                property bool checked: false
                signal toggled()

                implicitWidth: 40
                implicitHeight: 22
                radius: 11
                color: checked ? Colors.accent : Colors.surface0
                border.color: Colors.border
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "#F5F5F5"
                    anchors.verticalCenter: parent.verticalCenter
                    x: sw.checked ? sw.width - width - 3 : 3
                    Behavior on x { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sw.toggled()
                }
            }

            component ToggleRow: RowLayout {
                id: toggleRow
                property string label: ""
                property bool checked: false
                signal toggled()

                Layout.fillWidth: true

                Text {
                    text: toggleRow.label
                    color: "#F5F5F5"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }

                ToggleSwitch {
                    checked: toggleRow.checked
                    onToggled: toggleRow.toggled()
                }
            }

            component ChoiceRow: Flow {
                id: choiceRow
                property var options: []
                property string current: ""
                signal chosen(string key)

                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: choiceRow.options

                    Rectangle {
                        implicitWidth: choiceText.implicitWidth + 20
                        implicitHeight: 28
                        radius: 6
                        color: choiceRow.current === modelData.key ? Colors.accent : Colors.surface0

                        Text {
                            id: choiceText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: choiceRow.current === modelData.key ? Colors.accentText : "#F5F5F5"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: choiceRow.chosen(modelData.key)
                        }
                    }
                }
            }

            component StepperRow: ColumnLayout {
                id: stepper
                property string label: ""
                property string settingKey: ""
                property real minValue: 0
                property real maxValue: 100
                property real stepValue: 1

                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: stepper.label
                        color: "#F5F5F5"
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Text {
                        text: SettingsState[stepper.settingKey]
                        color: Colors.foregroundMuted
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 6
                        color: Colors.surface0

                        Text { anchors.centerIn: parent; text: "−"; color: "#F5F5F5"; font.pixelSize: 14 }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsState[stepper.settingKey] = Math.max(stepper.minValue, SettingsState[stepper.settingKey] - stepper.stepValue)
                                SettingsState.save()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Colors.surface0

                        Rectangle {
                            width: parent.width * ((SettingsState[stepper.settingKey] - stepper.minValue) / (stepper.maxValue - stepper.minValue))
                            height: parent.height
                            radius: 3
                            color: Colors.accent
                        }
                    }

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 6
                        color: Colors.surface0

                        Text { anchors.centerIn: parent; text: "+"; color: "#F5F5F5"; font.pixelSize: 14 }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsState[stepper.settingKey] = Math.min(stepper.maxValue, SettingsState[stepper.settingKey] + stepper.stepValue)
                                SettingsState.save()
                            }
                        }
                    }
                }
            }

            component SectionTitle: Text {
                color: Colors.accent
                font.pixelSize: 13
                font.bold: true
            }

            component SubLabel: Text {
                color: Colors.foregroundMuted
                font.pixelSize: 10
            }

            component Divider: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.border
            }

            // ---- Ekran ----
            Item {
                anchors.fill: parent
                focus: settingsWindow.visible
                Keys.onEscapePressed: SettingsState.settingsVisible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: SettingsState.settingsVisible = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(560, parent.width * 0.8)
                    height: Math.min(760, parent.height * 0.88)
                    radius: 16
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 20
                        contentWidth: width
                        contentHeight: col.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: col
                            width: parent.width
                            spacing: 18

                            Text {
                                text: I18n.t("settings")
                                color: "#F5F5F5"
                                font.pixelSize: 20
                                font.bold: true
                            }

                            // ---------- TEMA ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SectionTitle { text: I18n.t("theme") }

                                ToggleRow {
                                    label: I18n.t("dynamicTheme")
                                    checked: SettingsState.useDynamicTheme
                                    onToggled: {
                                        SettingsState.useDynamicTheme = !SettingsState.useDynamicTheme
                                        if (!SettingsState.useDynamicTheme) {
                                            SettingsState.applyFixedAccent()
                                        } else if (WallpaperService.currentWallpaperPath) {
                                            DynamicTheme.generateFromWallpaper(WallpaperService.currentWallpaperPath)
                                        }
                                        SettingsState.save()
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !SettingsState.useDynamicTheme
                                    spacing: 8

                                    Repeater {
                                        model: ["#89b4fa", "#a6e3a1", "#f9e2af", "#f38ba8", "#cba6f7", "#94e2d5", "#fab387"]

                                        Rectangle {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: 14
                                            color: modelData
                                            border.color: SettingsState.fixedAccentColor === modelData ? "#F5F5F5" : "transparent"
                                            border.width: 2

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    SettingsState.fixedAccentColor = modelData
                                                    SettingsState.applyFixedAccent()
                                                    SettingsState.save()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Divider {}

                            // ---------- BAR WIDGET'LARI ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SectionTitle { text: I18n.t("barWidgets") }

                                Repeater {
                                    model: settingsWindow.barToggleDefs

                                    ToggleRow {
                                        label: modelData.label
                                        checked: SettingsState[modelData.key]
                                        onToggled: {
                                            SettingsState[modelData.key] = !SettingsState[modelData.key]
                                            SettingsState.save()
                                        }
                                    }
                                }
                            }

                            Divider {}

                            // ---------- MASAÜSTÜ WIDGET'LARI ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                SectionTitle { text: I18n.t("desktopWidgets") }

                                Repeater {
                                    model: settingsWindow.deskWidgetDefs

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        ToggleRow {
                                            label: modelData.label
                                            checked: SettingsState[modelData.showKey]
                                            onToggled: {
                                                SettingsState[modelData.showKey] = !SettingsState[modelData.showKey]
                                                SettingsState.save()
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            visible: SettingsState[modelData.showKey]
                                            spacing: 8

                                            SubLabel {
                                                text: I18n.t("clockStyle")
                                                visible: modelData.hasStyle
                                            }

                                            ChoiceRow {
                                                visible: modelData.hasStyle
                                                options: settingsWindow.clockStyleOptions
                                                current: SettingsState.clockStyle
                                                onChosen: (key) => {
                                                    SettingsState.clockStyle = key
                                                    SettingsState.save()
                                                }
                                            }

                                            SubLabel { text: I18n.t("position") }

                                            ChoiceRow {
                                                options: settingsWindow.cornerOptions
                                                current: SettingsState[modelData.cornerKey]
                                                onChosen: (key) => {
                                                    SettingsState[modelData.cornerKey] = key
                                                    SettingsState.save()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Divider {}

                            // ---------- DİL ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SectionTitle { text: I18n.t("language") }

                                ChoiceRow {
                                    options: settingsWindow.languageOptions
                                    current: SettingsState.language
                                    onChosen: (key) => {
                                        SettingsState.language = key
                                        SettingsState.save()
                                    }
                                }
                            }

                            Divider {}

                            // ---------- GENEL ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                SectionTitle { text: I18n.t("general") }

                                Repeater {
                                    model: settingsWindow.stepperDefs

                                    StepperRow {
                                        label: modelData.label
                                        settingKey: modelData.key
                                        minValue: modelData.min
                                        maxValue: modelData.max
                                        stepValue: modelData.step
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