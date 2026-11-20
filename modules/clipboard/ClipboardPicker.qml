// modules/clipboard/ClipboardPicker.qml
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
            id: pickerWindow
            property var modelData
            screen: modelData

            visible: ClipboardState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property string filterText: ""
            property string activeTab: "all" // all | pinned | images
            property int selectedIndex: 0

            readonly property var displayedEntries: {
                return ClipboardState.allEntries.filter(e => {
                    if (pickerWindow.activeTab === "pinned" && !e.isPinned) return false
                    if (pickerWindow.activeTab === "images" && !e.isImage) return false

                    if (pickerWindow.filterText === "") return true
                    const q = pickerWindow.filterText.toLowerCase()
                    const textToSearch = (e.preview || "") + " " + (e.imageInfo || "")
                    return textToSearch.toLowerCase().includes(q)
                })
            }

            function selectCurrent() {
                const list = displayedEntries
                if (list.length === 0) return
                const idx = Math.min(selectedIndex, list.length - 1)
                if (list[idx]) ClipboardState.selectEntry(list[idx])
            }

            onVisibleChanged: {
                if (visible) {
                    filterText = ""
                    selectedIndex = 0
                    searchInput.text = ""
                    Qt.callLater(() => searchInput.forceActiveFocus())
                }
            }

            Item {
                anchors.fill: parent
                focus: pickerWindow.visible

                Keys.onEscapePressed: ClipboardState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: ClipboardState.visible = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 520
                    height: 580
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // ---- BAŞLIK VE TÜMÜNÜ SİL BUTONU ----
                        RowLayout {
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true

                                Text {
                                    text: "󰅍"
                                    color: Colors.accent
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    text: I18n.t("clipboardTitle")
                                    color: Colors.foreground
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                implicitWidth: clearBtnText.width + 16
                                implicitHeight: 26
                                radius: 6
                                color: clearHover.containsMouse ? Colors.surface1 : "transparent"
                                visible: ClipboardState.historyEntries.length > 0

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "󰃢"
                                        color: Colors.danger
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    Text {
                                        id: clearBtnText
                                        text: I18n.t("clearAll")
                                        color: Colors.danger
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: clearHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardState.wipeAll()
                                }
                            }
                        }

                        // ---- FİLTRELEME SEKMELERİ (Tümü / Sabitlenenler / Resimler) ----
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { key: "all", label: I18n.t("clipboardAll"), icon: "󰅍" },
                                    { key: "pinned", label: I18n.t("clipboardPinned"), icon: "󰤰" },
                                    { key: "images", label: I18n.t("clipboardImages"), icon: "󰋩" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 6
                                    color: pickerWindow.activeTab === modelData.key ? Colors.accent : (tabHover.containsMouse ? Colors.surface1 : Colors.surface0)

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: modelData.icon
                                            color: pickerWindow.activeTab === modelData.key ? Colors.accentText : Colors.foreground
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        Text {
                                            text: modelData.label
                                            color: pickerWindow.activeTab === modelData.key ? Colors.accentText : Colors.foreground
                                            font.pixelSize: 11
                                            font.bold: pickerWindow.activeTab === modelData.key
                                        }
                                    }

                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            pickerWindow.activeTab = modelData.key
                                            pickerWindow.selectedIndex = 0
                                        }
                                    }
                                }
                            }
                        }

                        // ---- ARAMA KUTUSU ----
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: Colors.surface0
                            border.color: Colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: "󰍉"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 14
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
                                        font.pixelSize: 12
                                        clip: true
                                        focus: true
                                        onTextChanged: {
                                            pickerWindow.filterText = text
                                            pickerWindow.selectedIndex = 0
                                        }
                                        Keys.onDownPressed: {
                                            if (pickerWindow.selectedIndex < pickerWindow.displayedEntries.length - 1)
                                                pickerWindow.selectedIndex++
                                        }
                                        Keys.onUpPressed: {
                                            if (pickerWindow.selectedIndex > 0)
                                                pickerWindow.selectedIndex--
                                        }
                                        Keys.onReturnPressed: pickerWindow.selectCurrent()
                                        Keys.onEnterPressed: pickerWindow.selectCurrent()
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: I18n.t("searchPlaceholder")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 12
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }

                        // ---- PANO LİSTESİ ----
                        ListView {
                            id: entryList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: pickerWindow.displayedEntries
                            currentIndex: pickerWindow.selectedIndex

                            highlightMoveDuration: 100
                            highlightFollowsCurrentItem: true

                            delegate: Rectangle {
                                id: card
                                width: entryList.width
                                implicitHeight: modelData.isImage ? 80 : 54
                                radius: 8
                                color: index === pickerWindow.selectedIndex ? Colors.accent : (entryHover.containsMouse ? Colors.hover : Colors.surface0)
                                border.color: modelData.isPinned ? Colors.accent : "transparent"
                                border.width: modelData.isPinned ? 1 : 0

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    // ---- GÖRSEL ÖNİZLEME (RESİM İSE) ----
                                    Rectangle {
                                        visible: modelData.isImage
                                        Layout.preferredWidth: 64
                                        Layout.preferredHeight: 64
                                        radius: 6
                                        color: Colors.surface1
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.imagePath ? ("file://" + modelData.imagePath) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            visible: source !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰋩"
                                            color: Colors.foregroundMuted
                                            font.pixelSize: 22
                                            font.family: "JetBrainsMono Nerd Font"
                                            visible: !parent.children[0].visible
                                        }
                                    }

                                    // ---- METİN İKONU (METİN İSE) ----
                                    Rectangle {
                                        visible: !modelData.isImage
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 6
                                        color: index === pickerWindow.selectedIndex ? Colors.surface1 : Colors.surface1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅍"
                                            color: index === pickerWindow.selectedIndex ? Colors.accentText : Colors.accent
                                            font.pixelSize: 16
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }

                                    // ---- İÇERİK METNİ / GÖRSEL BİLGİSİ ----
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        // Sabitlendi Rozeti
                                        RowLayout {
                                            visible: modelData.isPinned
                                            spacing: 4

                                            Text {
                                                text: "󰤰"
                                                color: index === pickerWindow.selectedIndex ? Colors.accentText : Colors.accent
                                                font.pixelSize: 10
                                                font.family: "JetBrainsMono Nerd Font"
                                            }

                                            Text {
                                                text: I18n.t("clipboardPinned")
                                                color: index === pickerWindow.selectedIndex ? Colors.accentText : Colors.accent
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Text {
                                            text: modelData.isImage ? (modelData.imageInfo || I18n.t("imageItem")) : modelData.preview
                                            color: index === pickerWindow.selectedIndex ? Colors.accentText : Colors.foreground
                                            font.pixelSize: 11
                                            font.bold: modelData.isImage
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WrapAnywhere
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // ---- EYLEM BUTONLARI (Sabitleme & Silme) ----
                                    RowLayout {
                                        spacing: 6

                                        // Sabitleme Butonu
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 6
                                            color: pinHover.containsMouse ? Colors.surface1 : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.isPinned ? "󰤰" : "󰤱"
                                                color: modelData.isPinned ? (index === pickerWindow.selectedIndex ? Colors.accentText : Colors.accent) : Colors.foregroundMuted
                                                font.pixelSize: 14
                                                font.family: "JetBrainsMono Nerd Font"
                                            }

                                            MouseArea {
                                                id: pinHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ClipboardState.togglePin(modelData)
                                            }
                                        }

                                        // Silme Butonu
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 6
                                            color: delHover.containsMouse ? Colors.surface1 : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: delHover.containsMouse ? Colors.danger : (index === pickerWindow.selectedIndex ? Colors.accentText : Colors.foregroundMuted)
                                                font.pixelSize: 11
                                            }

                                            MouseArea {
                                                id: delHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ClipboardState.deleteEntry(modelData)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: entryHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: pickerWindow.selectedIndex = index
                                    onClicked: ClipboardState.selectEntry(modelData)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: entryList.count === 0
                                text: I18n.t("clipboardEmpty")
                                color: Colors.foregroundMuted
                                font.pixelSize: 12
                                font.italic: true
                            }
                        }
                    }
                }
            }
        }
    }
}
