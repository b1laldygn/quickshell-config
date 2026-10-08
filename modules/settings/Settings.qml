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

            property string tab: "appearance"

            onVisibleChanged: if (visible) TimeSettings.refresh()
            onTabChanged: {
                flick.contentY = 0
                if (tab === "datetime") TimeSettings.refresh()
            }

            // ---- Seçenek listeleri (dil değişince otomatik güncellenir) ----
            property var tabDefs: [
                { key: "appearance", label: I18n.t("tabAppearance") },
                { key: "desktop", label: I18n.t("tabDesktop") },
                { key: "datetime", label: I18n.t("tabDateTime") },
                { key: "notifications", label: I18n.t("notificationsTitle") },
                { key: "general", label: I18n.t("general") }
            ]
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
            property var timeFormatOptions: [
                { label: I18n.t("hour24"), key: "24" },
                { label: I18n.t("hour12"), key: "12" }
            ]
            property var dateFormatOptions: [
                { key: "long", label: TimeFormat.dateTextFor(new Date(), "long") },
                { key: "medium", label: TimeFormat.dateTextFor(new Date(), "medium") },
                { key: "numeric", label: TimeFormat.dateTextFor(new Date(), "numeric") },
                { key: "iso", label: TimeFormat.dateTextFor(new Date(), "iso") }
            ]
            property var weekStartOptions: [
                { label: I18n.t("monday"), key: "mon" },
                { label: I18n.t("sunday"), key: "sun" }
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
            property var pollStepperDefs: [
                { label: I18n.t("volumePollLabel"), key: "volumePollInterval", min: 20, max: 500, step: 10 },
                { label: I18n.t("brightnessPollLabel"), key: "brightnessPollInterval", min: 20, max: 500, step: 10 },
                { label: I18n.t("weatherRefreshLabel"), key: "weatherRefreshMinutes", min: 5, max: 120, step: 5 }
            ]
            readonly property var accentPresets: ["#89b4fa", "#a6e3a1", "#f9e2af", "#f38ba8", "#cba6f7", "#94e2d5", "#fab387"]
            readonly property var backgroundPresets: ["#1e1e2e", "#11111b", "#181825", "#0f172a", "#1a1b26", "#101820", "#1c1917"]

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

            component SwatchRow: Flow {
                id: swatchRow
                property var colors: []
                property string current: ""
                signal chosen(string hex)

                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: swatchRow.colors

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: modelData
                        border.color: swatchRow.current.toLowerCase() === modelData.toLowerCase() ? "#F5F5F5" : Colors.border
                        border.width: 2

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: swatchRow.chosen(modelData)
                        }
                    }
                }
            }

            component HsvSlider: Item {
                id: hs
                property real ratio: 0
                property bool rainbow: false
                property color startColor: "#000000"
                property color endColor: "#ffffff"
                signal moved(real r)

                Layout.fillWidth: true
                implicitHeight: 18

                Gradient {
                    id: rainbowGradient
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff0000" }
                    GradientStop { position: 0.17; color: "#ffff00" }
                    GradientStop { position: 0.33; color: "#00ff00" }
                    GradientStop { position: 0.5; color: "#00ffff" }
                    GradientStop { position: 0.67; color: "#0000ff" }
                    GradientStop { position: 0.83; color: "#ff00ff" }
                    GradientStop { position: 1.0; color: "#ff0000" }
                }

                Gradient {
                    id: plainGradient
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: hs.startColor }
                    GradientStop { position: 1.0; color: hs.endColor }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 10
                    radius: 5
                    border.color: Colors.border
                    border.width: 1
                    gradient: hs.rainbow ? rainbowGradient : plainGradient
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: "#F5F5F5"
                    border.color: "#66000000"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(1, hs.ratio)) * (hs.width - width)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function update(mx) {
                        hs.moved(Math.max(0, Math.min(1, (mx - 7) / (hs.width - 14))))
                    }

                    onPressed: (mouse) => update(mouse.x)
                    onPositionChanged: (mouse) => { if (pressed) update(mouse.x) }
                }
            }

            component ColorPicker: ColumnLayout {
                id: picker
                property string value: "#89b4fa"
                property real maxBrightness: 1.0
                signal picked(string hex)

                property real hue: 0
                property real sat: 0
                property real bri: 0
                property string lastEmitted: ""

                Layout.fillWidth: true
                spacing: 8

                function h2(x) {
                    return Math.round(Math.max(0, Math.min(1, x)) * 255).toString(16).padStart(2, "0")
                }

                function hexOf(h, s, v) {
                    const c = Qt.hsva(h, s, v, 1)
                    return "#" + h2(c.r) + h2(c.g) + h2(c.b)
                }

                readonly property string hexNow: hexOf(hue, sat, bri)

                function syncFromHex(hex) {
                    const c = Qt.color(hex)
                    if (c.hsvSaturation > 0 && c.hsvValue > 0) hue = c.hsvHue
                    sat = c.hsvSaturation
                    bri = Math.min(c.hsvValue, maxBrightness)
                }

                function commit() {
                    picker.lastEmitted = picker.hexNow
                    picker.picked(picker.hexNow)
                }

                onValueChanged: {
                    if (picker.value.toLowerCase() !== picker.lastEmitted) picker.syncFromHex(picker.value)
                }
                Component.onCompleted: syncFromHex(value)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 6
                        color: picker.hexNow
                        border.color: Colors.border
                        border.width: 1
                    }

                    Rectangle {
                        implicitWidth: 100
                        implicitHeight: 28
                        radius: 6
                        color: Colors.surface0
                        border.color: hexInput.activeFocus ? Colors.accent : Colors.border
                        border.width: 1

                        TextInput {
                            id: hexInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#F5F5F5"
                            font.pixelSize: 12
                            maximumLength: 7
                            selectByMouse: true
                            text: picker.hexNow

                            onTextEdited: {
                                const m = text.match(/^#?([0-9a-fA-F]{6})$/)
                                if (m) {
                                    picker.syncFromHex("#" + m[1])
                                    picker.commit()
                                }
                            }
                        }
                    }
                }

                HsvSlider {
                    rainbow: true
                    ratio: picker.hue
                    onMoved: (r) => { picker.hue = r; picker.commit() }
                }

                HsvSlider {
                    ratio: picker.sat
                    startColor: Qt.hsva(picker.hue, 0, 1, 1)
                    endColor: Qt.hsva(picker.hue, 1, 1, 1)
                    onMoved: (r) => { picker.sat = r; picker.commit() }
                }

                HsvSlider {
                    ratio: picker.maxBrightness > 0 ? picker.bri / picker.maxBrightness : 0
                    startColor: "#000000"
                    endColor: Qt.hsva(picker.hue, picker.sat, picker.maxBrightness, 1)
                    onMoved: (r) => { picker.bri = r * picker.maxBrightness; picker.commit() }
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

            component FieldBox: Rectangle {
                id: fb
                property alias text: input.text
                property string placeholder: ""
                readonly property bool focused: input.activeFocus
                signal accepted()
                signal edited()

                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: Colors.surface0
                border.color: input.activeFocus ? Colors.accent : Colors.border
                border.width: 1

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#F5F5F5"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    onAccepted: fb.accepted()
                    onTextEdited: fb.edited()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: fb.placeholder
                    color: Colors.foregroundMuted
                    font.pixelSize: 12
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
                    width: Math.min(780, parent.width * 0.88)
                    height: Math.min(700, parent.height * 0.9)
                    radius: 16
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        // ---------- SOL MENÜ ----------
                        ColumnLayout {
                            width: 150
                            height: parent.height
                            spacing: 6

                            Text {
                                text: I18n.t("settings")
                                color: "#F5F5F5"
                                font.pixelSize: 18
                                font.bold: true
                                Layout.bottomMargin: 10
                            }

                            Repeater {
                                model: settingsWindow.tabDefs

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    radius: 8
                                    color: settingsWindow.tab === modelData.key
                                        ? Colors.accent
                                        : (tabHover.containsMouse ? Colors.hover : "transparent")

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        color: settingsWindow.tab === modelData.key ? Colors.accentText : "#F5F5F5"
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsWindow.tab = modelData.key
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Dikey Çizgi
                        Rectangle {
                            width: 1
                            height: parent.height
                            color: Colors.border
                        }

                        // ---------- İÇERİK (FLICKABLE) ----------
                        Flickable {
                            id: flick
                            width: parent.width - 150 - 1 - 32 // Toplam genişlik - sol menü - çizgi - boşluklar
                            height: parent.height
                            contentWidth: width
                            contentHeight: col.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: col
                                width: flick.width
                                spacing: 18
                                // =============== GÖRÜNÜM ===============
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: settingsWindow.tab === "appearance"
                                    spacing: 18

                                    // ---- Tema ----
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
                                                    SettingsState.applyFixedTheme()
                                                } else if (WallpaperService.currentWallpaperPath) {
                                                    DynamicTheme.generateFromWallpaper(WallpaperService.currentWallpaperPath)
                                                }
                                                SettingsState.save()
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            visible: !SettingsState.useDynamicTheme
                                            spacing: 10

                                            SubLabel { text: I18n.t("accentColor") }

                                            SwatchRow {
                                                colors: settingsWindow.accentPresets
                                                current: SettingsState.fixedAccentColor
                                                onChosen: (hex) => {
                                                    SettingsState.fixedAccentColor = hex
                                                    SettingsState.applyFixedTheme()
                                                    SettingsState.save()
                                                }
                                            }

                                            ColorPicker {
                                                value: SettingsState.fixedAccentColor
                                                onPicked: (hex) => {
                                                    SettingsState.fixedAccentColor = hex
                                                    SettingsState.applyFixedTheme()
                                                    SettingsState.save()
                                                }
                                            }

                                            SubLabel {
                                                text: I18n.t("backgroundColor")
                                                Layout.topMargin: 6
                                            }

                                            SubLabel { text: I18n.t("darkOnlyHint") }

                                            SwatchRow {
                                                colors: settingsWindow.backgroundPresets
                                                current: SettingsState.fixedBackgroundColor
                                                onChosen: (hex) => {
                                                    SettingsState.fixedBackgroundColor = hex
                                                    SettingsState.applyFixedTheme()
                                                    SettingsState.save()
                                                }
                                            }

                                            ColorPicker {
                                                maxBrightness: 0.35
                                                value: SettingsState.fixedBackgroundColor
                                                onPicked: (hex) => {
                                                    SettingsState.fixedBackgroundColor = hex
                                                    SettingsState.applyFixedTheme()
                                                    SettingsState.save()
                                                }
                                            }
                                        }
                                    }

                                    Divider {}

                                    // ---- Bar ----
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        SectionTitle { text: I18n.t("barAppearance") }

                                        StepperRow {
                                            label: I18n.t("barHeight")
                                            settingKey: "barHeight"
                                            minValue: 28
                                            maxValue: 40
                                            stepValue: 2
                                        }

                                        StepperRow {
                                            label: I18n.t("barOpacity")
                                            settingKey: "barOpacity"
                                            minValue: 30
                                            maxValue: 100
                                            stepValue: 5
                                        }

                                        SectionTitle {
                                            text: I18n.t("barWidgets")
                                            Layout.topMargin: 6
                                        }

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

                                    // ---- Duvar kağıdı ----
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        SectionTitle { text: I18n.t("wallpaperSection") }

                                        SubLabel { text: I18n.t("wallpaperFolder") }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            FieldBox {
                                                id: wpField
                                                placeholder: "~/Pictures/wallpaper"
                                                onAccepted: {
                                                    SettingsState.wallpaperDir = text.trim()
                                                    SettingsState.save()
                                                }
                                            }

                                            Binding {
                                                target: wpField
                                                property: "text"
                                                value: SettingsState.wallpaperDir
                                                when: !wpField.focused
                                            }

                                            Rectangle {
                                                implicitWidth: applyText.implicitWidth + 20
                                                implicitHeight: 30
                                                radius: 6
                                                color: Colors.accent

                                                Text {
                                                    id: applyText
                                                    anchors.centerIn: parent
                                                    text: I18n.t("apply")
                                                    color: Colors.accentText
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        SettingsState.wallpaperDir = wpField.text.trim()
                                                        SettingsState.save()
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            text: WallpaperThumbs.imageCount < 0
                                                ? I18n.t("folderNotFound")
                                                : WallpaperThumbs.imageCount + " " + I18n.t("imagesFound")
                                            color: WallpaperThumbs.imageCount < 0 ? Colors.danger : Colors.foregroundMuted
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // =============== MASAÜSTÜ ===============
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: settingsWindow.tab === "desktop"
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

                                // =============== TARİH VE SAAT ===============
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: settingsWindow.tab === "datetime"
                                    spacing: 14

                                    SectionTitle { text: I18n.t("timeSection") }

                                    SubLabel { text: I18n.t("timeFormat") }

                                    ChoiceRow {
                                        options: settingsWindow.timeFormatOptions
                                        current: SettingsState.use24h ? "24" : "12"
                                        onChosen: (key) => {
                                            SettingsState.use24h = (key === "24")
                                            SettingsState.save()
                                        }
                                    }

                                    ToggleRow {
                                        label: I18n.t("barClockSeconds")
                                        checked: SettingsState.barClockSeconds
                                        onToggled: {
                                            SettingsState.barClockSeconds = !SettingsState.barClockSeconds
                                            SettingsState.save()
                                        }
                                    }

                                    ToggleRow {
                                        label: I18n.t("deskClockSeconds")
                                        checked: SettingsState.deskClockSeconds
                                        onToggled: {
                                            SettingsState.deskClockSeconds = !SettingsState.deskClockSeconds
                                            SettingsState.save()
                                        }
                                    }

                                    SubLabel { text: I18n.t("dateFormat") }

                                    ChoiceRow {
                                        options: settingsWindow.dateFormatOptions
                                        current: SettingsState.dateFormat
                                        onChosen: (key) => {
                                            SettingsState.dateFormat = key
                                            SettingsState.save()
                                        }
                                    }

                                    SubLabel { text: I18n.t("weekStart") }

                                    ChoiceRow {
                                        options: settingsWindow.weekStartOptions
                                        current: SettingsState.weekStart
                                        onChosen: (key) => {
                                            SettingsState.weekStart = key
                                            SettingsState.save()
                                        }
                                    }

                                    Divider {}

                                    // ---- Saat dilimi ve NTP ----
                                    ColumnLayout {
                                        id: tzBox
                                        Layout.fillWidth: true
                                        spacing: 8

                                        property string filterText: ""
                                        readonly property var matches: {
                                            const q = filterText.toLowerCase().trim()
                                            if (q === "") return []
                                            return TimeSettings.timezones.filter(z => z.toLowerCase().includes(q)).slice(0, 8)
                                        }

                                        SectionTitle { text: I18n.t("timezone") }

                                        Text {
                                            text: I18n.t("currentLabel") + ": " + (TimeSettings.currentTimezone || "-")
                                            color: Colors.foregroundMuted
                                            font.pixelSize: 11
                                        }

                                        FieldBox {
                                            placeholder: I18n.t("searchTimezone")
                                            onEdited: tzBox.filterText = text
                                        }

                                        Repeater {
                                            model: tzBox.matches

                                            Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: 28
                                                radius: 6
                                                color: modelData === TimeSettings.currentTimezone
                                                    ? Colors.accent
                                                    : (zoneHover.containsMouse ? Colors.hover : Colors.surface0)

                                                Text {
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData
                                                    color: modelData === TimeSettings.currentTimezone ? Colors.accentText : "#F5F5F5"
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    id: zoneHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: TimeSettings.setTimezone(modelData)
                                                }
                                            }
                                        }

                                        ToggleRow {
                                            Layout.topMargin: 6
                                            label: I18n.t("autoTime")
                                            checked: TimeSettings.ntpEnabled
                                            onToggled: TimeSettings.setNtp(!TimeSettings.ntpEnabled)
                                        }

                                        Text {
                                            visible: TimeSettings.message !== ""
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            text: TimeSettings.message
                                                + (TimeSettings.message.toLowerCase().includes("authentic")
                                                    ? "\n" + I18n.t("polkitHint") : "")
                                            color: Colors.danger
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // =============== BİLDİRİMLER ===============
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: settingsWindow.tab === "notifications"
                                    spacing: 14

                                    SectionTitle { text: I18n.t("notificationsTitle") }

                                    StepperRow {
                                        label: I18n.t("notifTimeout")
                                        settingKey: "notificationTimeout"
                                        minValue: 2
                                        maxValue: 15
                                        stepValue: 1
                                    }

                                    SubLabel { text: I18n.t("notifTimeoutHint") }

                                    StepperRow {
                                        label: I18n.t("notifHistoryLimit")
                                        settingKey: "notificationHistoryLimit"
                                        minValue: 10
                                        maxValue: 200
                                        stepValue: 10
                                    }
                                }

                                // =============== GENEL ===============
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: settingsWindow.tab === "general"
                                    spacing: 14

                                    SectionTitle { text: I18n.t("language") }

                                    ChoiceRow {
                                        options: settingsWindow.languageOptions
                                        current: SettingsState.language
                                        onChosen: (key) => {
                                            SettingsState.language = key
                                            SettingsState.save()
                                        }
                                    }

                                    Divider {}

                                    SectionTitle { text: I18n.t("general") }

                                    Repeater {
                                        model: settingsWindow.pollStepperDefs

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
}