// modules/keybinds/KeybindsOverlay.qml
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
            id: overlayWindow
            property var modelData
            screen: modelData

            PopupFx {
                id: fx
                open: KeybindsState.visible
            }

            visible: fx.shown

            anchors { top: true; bottom: true; left: true; right: true }
            color: Qt.rgba(0.05, 0.05, 0.08, 0.72 * fx.cardOpacity)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: KeybindsState.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property string filterText: ""
            property string selectedCategory: "all"

            readonly property var categoryOrder: [
                "catQuickshellTools",
                "catWindowManagement",
                "catWorkspaces",
                "catSystem",
                "catApps",
                "catOther"
            ]

            onVisibleChanged: {
                if (visible) {
                    filterText = ""
                    selectedCategory = "all"
                    searchInput.text = ""
                    searchInput.forceActiveFocus()
                }
            }

            property var availableCategories: {
                const counts = {}
                for (const b of KeybindsState.binds) {
                    counts[b.category] = (counts[b.category] || 0) + 1
                }
                const list = [{ id: "all", label: I18n.t("filterAll"), count: KeybindsState.binds.length }]
                for (const c of categoryOrder) {
                    if (counts[c] > 0) {
                        list.push({ id: c, label: I18n.t(c), count: counts[c] })
                    }
                }
                return list
            }

            property var filteredBinds: {
                const query = filterText.toLowerCase().trim()
                return KeybindsState.binds.filter(b => {
                    if (selectedCategory !== "all" && b.category !== selectedCategory) return false
                    if (query === "") return true
                    const combined = (b.mods + " " + b.key + " " + b.rawKey + " " + b.label + " " + b.command).toLowerCase()
                    return combined.includes(query)
                })
            }

            property var groupedBinds: {
                const buckets = {}
                for (const cat of categoryOrder) buckets[cat] = []

                for (const b of filteredBinds) {
                    const c = buckets[b.category] ? b.category : "catOther"
                    buckets[c].push(b)
                }

                const result = []
                for (const cat of categoryOrder) {
                    if (buckets[cat].length > 0) {
                        result.push({ category: cat, items: buckets[cat] })
                    }
                }
                return result
            }

            Item {
                anchors.fill: parent
                focus: KeybindsState.visible

                Keys.onEscapePressed: {
                    if (searchInput.text.length > 0) {
                        searchInput.text = ""
                    } else {
                        KeybindsState.visible = false
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: KeybindsState.visible = false
                }

                Rectangle {
                    id: overlayCard
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.90, Math.round(1220 * SettingsState.scaleFactor))
                    height: Math.min(parent.height * 0.88, Math.round(820 * SettingsState.scaleFactor))
                    radius: Math.round(18 * SettingsState.scaleFactor)
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transform: Translate { y: fx.cardY }

                    // İçerideki tıklamaların arka plana geçmesini engelle
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.round(18 * SettingsState.scaleFactor)
                        spacing: Math.round(12 * SettingsState.scaleFactor)

                        // ── Üst Başlık ───────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(10 * SettingsState.scaleFactor)

                            Rectangle {
                                width: Math.round(32 * SettingsState.scaleFactor)
                                height: width
                                radius: Math.round(10 * SettingsState.scaleFactor)
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌌"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(16 * SettingsState.scaleFactor)
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            Text {
                                text: I18n.t("keybindsTitle")
                                color: Colors.foreground
                                font.pixelSize: Math.round(17 * SettingsState.scaleFactor)
                                font.bold: true
                            }

                            Rectangle {
                                height: Math.round(22 * SettingsState.scaleFactor)
                                width: countBadgeText.implicitWidth + Math.round(16 * SettingsState.scaleFactor)
                                radius: height / 2
                                color: Colors.surface0

                                Text {
                                    id: countBadgeText
                                    anchors.centerIn: parent
                                    text: overlayWindow.filteredBinds.length + " " + I18n.t("keybindsCount")
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Yenile Butonu
                            Rectangle {
                                width: Math.round(32 * SettingsState.scaleFactor)
                                height: width
                                radius: Math.round(9 * SettingsState.scaleFactor)
                                color: refreshMouse.containsMouse ? Colors.hover : Colors.surface0
                                border.color: Colors.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑐"
                                    color: KeybindsState.loading ? Colors.accent : Colors.foreground
                                    font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: refreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeybindsState.refresh()
                                }
                            }

                            // Kapat Butonu
                            Rectangle {
                                width: Math.round(32 * SettingsState.scaleFactor)
                                height: width
                                radius: Math.round(9 * SettingsState.scaleFactor)
                                color: closeMouse.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.22) : Colors.surface0
                                border.color: closeMouse.containsMouse ? Colors.danger : Colors.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeMouse.containsMouse ? Colors.danger : Colors.foregroundMuted
                                    font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                    font.bold: true
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KeybindsState.visible = false
                                }
                            }
                        }

                        // ── Arama Çubuğu ─────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            height: Math.round(38 * SettingsState.scaleFactor)
                            radius: Math.round(10 * SettingsState.scaleFactor)
                            color: Colors.surface0
                            border.color: searchInput.activeFocus ? Colors.accent : Colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(12 * SettingsState.scaleFactor)
                                anchors.rightMargin: Math.round(10 * SettingsState.scaleFactor)
                                spacing: Math.round(8 * SettingsState.scaleFactor)

                                Text {
                                    text: "󰍉"
                                    color: searchInput.activeFocus ? Colors.accent : Colors.foregroundMuted
                                    font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                        clip: true
                                        selectByMouse: true
                                        onTextChanged: overlayWindow.filterText = text
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: I18n.t("searchPlaceholder")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                        visible: searchInput.text.length === 0
                                    }
                                }

                                Rectangle {
                                    visible: searchInput.text.length > 0
                                    width: Math.round(20 * SettingsState.scaleFactor)
                                    height: width
                                    radius: width / 2
                                    color: clearMouse.containsMouse ? Colors.active : Colors.surface1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: Colors.foreground
                                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                    }

                                    MouseArea {
                                        id: clearMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: searchInput.text = ""
                                    }
                                }
                            }
                        }

                        // ── Kategori Filtre Chip'leri ────────────────────────
                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(30 * SettingsState.scaleFactor)
                            contentWidth: catRow.implicitWidth
                            contentHeight: height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Row {
                                id: catRow
                                spacing: Math.round(6 * SettingsState.scaleFactor)

                                Repeater {
                                    model: overlayWindow.availableCategories

                                    Rectangle {
                                        readonly property bool isSel: overlayWindow.selectedCategory === modelData.id
                                        height: Math.round(28 * SettingsState.scaleFactor)
                                        width: chipRow.implicitWidth + Math.round(18 * SettingsState.scaleFactor)
                                        radius: height / 2
                                        color: isSel ? Colors.accent : (catChipMouse.containsMouse ? Colors.hover : Colors.surface0)
                                        border.color: isSel ? Colors.accent : Colors.border
                                        border.width: 1

                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: Math.round(5 * SettingsState.scaleFactor)

                                            Text {
                                                text: modelData.label
                                                color: isSel ? Colors.accentText : Colors.foreground
                                                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                                font.bold: isSel
                                            }

                                            Text {
                                                text: modelData.count
                                                color: isSel ? Colors.accentText : Colors.foregroundMuted
                                                opacity: 0.8
                                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                            }
                                        }

                                        MouseArea {
                                            id: catChipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: overlayWindow.selectedCategory = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // ── Kısayol Listesi (2/3 Sütunlu Grid) ───────────────
                        Flickable {
                            id: bindsFlick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: groupedColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: groupedColumn
                                width: bindsFlick.width
                                spacing: Math.round(18 * SettingsState.scaleFactor)

                                Repeater {
                                    model: overlayWindow.groupedBinds

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(8 * SettingsState.scaleFactor)

                                        // Kategori Başlığı
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Math.round(8 * SettingsState.scaleFactor)

                                            Text {
                                                text: I18n.t(modelData.category)
                                                color: Colors.accent
                                                font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                                                font.bold: true
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 1
                                                color: Colors.border
                                                opacity: 0.6
                                            }
                                        }

                                        // Düzenli Grid
                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: overlayCard.width > Math.round(1080 * SettingsState.scaleFactor) ? 3 : 2
                                            columnSpacing: Math.round(10 * SettingsState.scaleFactor)
                                            rowSpacing: Math.round(8 * SettingsState.scaleFactor)

                                            Repeater {
                                                model: modelData.items

                                                Rectangle {
                                                    id: bindCard
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: Math.round(50 * SettingsState.scaleFactor)
                                                    radius: Math.round(10 * SettingsState.scaleFactor)
                                                    color: cardMouse.containsMouse ? Colors.hover : Colors.surface0
                                                    border.color: cardMouse.containsMouse ? Colors.accent : Colors.border
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: Math.round(12 * SettingsState.scaleFactor)
                                                        anchors.rightMargin: Math.round(12 * SettingsState.scaleFactor)
                                                        spacing: Math.round(10 * SettingsState.scaleFactor)

                                                        // Tuş Kombinasyonu Keycap'leri
                                                        Row {
                                                            spacing: Math.round(4 * SettingsState.scaleFactor)
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Repeater {
                                                                model: (modelData.mods.length > 0 ? modelData.mods.split(" ").filter(s => s.length > 0) : []).concat([modelData.key])

                                                                Rectangle {
                                                                    readonly property bool isSuper: modelData === "SUPER"
                                                                    height: Math.round(24 * SettingsState.scaleFactor)
                                                                    width: Math.max(height, keyText.implicitWidth + Math.round(12 * SettingsState.scaleFactor))
                                                                    radius: Math.round(6 * SettingsState.scaleFactor)
                                                                    color: isSuper
                                                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.20)
                                                                        : Colors.backgroundAlt
                                                                    border.color: isSuper ? Colors.accent : Colors.border
                                                                    border.width: 1

                                                                    Text {
                                                                        id: keyText
                                                                        anchors.centerIn: parent
                                                                        text: isSuper ? "󰖳" : modelData
                                                                        color: isSuper ? Colors.accent : Colors.foreground
                                                                        font.pixelSize: Math.round((isSuper ? 12 : 10) * SettingsState.scaleFactor)
                                                                        font.family: isSuper ? "JetBrainsMono Nerd Font" : ""
                                                                        font.bold: true
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // Açıklama + Komut
                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                            spacing: Math.round(1 * SettingsState.scaleFactor)

                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: modelData.label
                                                                color: Colors.foreground
                                                                font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                                                                font.bold: true
                                                                elide: Text.ElideRight
                                                            }

                                                            Text {
                                                                Layout.fillWidth: true
                                                                visible: modelData.command !== modelData.label && modelData.command.length > 0
                                                                text: modelData.command
                                                                color: Colors.foregroundMuted
                                                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                                                elide: Text.ElideRight
                                                                opacity: 0.78
                                                            }
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: cardMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: Math.round(30 * SettingsState.scaleFactor)
                                    visible: overlayWindow.groupedBinds.length === 0
                                    text: I18n.t("noResults")
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                    font.italic: true
                                }
                            }
                        }

                        // ── Alt Bilgi Çubuğu ──────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: I18n.t("keybindsHint")
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
