// modules/keybinds/KeybindsOverlay.qml
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
            id: overlayWindow
            property var modelData
            screen: modelData

            visible: KeybindsState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property string filterText: ""

            property var filteredBinds: {
                const query = filterText.toLowerCase().trim()
                if (query === "") return KeybindsState.binds
                return KeybindsState.binds.filter(b => {
                    const combined = (b.mods + " " + b.key + " " + b.dispatcher + " " + b.args).toLowerCase()
                    return combined.includes(query)
                })
            }
            property var groupedBinds: {
                const categoryOrder = ["Uygulamalar", "Quickshell Araçları", "Sistem", "Pencere Yönetimi", "Çalışma Alanları", "Diğer"]
                const buckets = {}
                for (const cat of categoryOrder) buckets[cat] = []

                function categorize(b) {
                    const d = b.dispatcher
                    const a = b.args || ""
                    if (d.startsWith("workspace") || d.startsWith("movetoworkspace")) return "Çalışma Alanları"
                    if (["killactive", "exit", "fullscreen", "togglefloating", "movewindow", "resizewindow"].includes(d)) return "Pencere Yönetimi"
                    if (d === "exec") {
                        if (a.includes("ipc call")) return "Quickshell Araçları"
                        if (a.includes("screenshot") || a.includes("hyprlock") || a.includes("pactl") || a.includes("brightnessctl")) return "Sistem"
                        return "Uygulamalar"
                    }
                    return "Diğer"
                }

                for (const b of filteredBinds) {
                    const cat = categorize(b)
                    buckets[cat].push(b)
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
                focus: overlayWindow.visible

                Keys.onEscapePressed: KeybindsState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: KeybindsState.visible = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.95
                    height: parent.height * 0.9
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "Kısayollar"
                            color: "#F5F5F5"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 8
                            color: Colors.surface0
                            border.color: Colors.border
                            border.width: 1

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                anchors.margins: 8
                                color: "#F5F5F5"
                                font.pixelSize: 12
                                clip: true
                                focus: overlayWindow.visible

                                onTextChanged: overlayWindow.filterText = text
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Ara..."
                                color: Colors.foregroundMuted
                                font.pixelSize: 12
                                visible: searchInput.text.length === 0
                            }
                        }

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
                                spacing: 16

                                Repeater {
                                    model: overlayWindow.groupedBinds

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: modelData.category
                                            color: Colors.accent
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                model: modelData.items

                                                Rectangle {
                                                    height: 36
                                                    radius: 8
                                                    color: Colors.surface0
                                                    width: rowContent.implicitWidth + 20

                                                    RowLayout {
                                                        id: rowContent
                                                        anchors.centerIn: parent
                                                        spacing: 10

                                                        Row {
                                                            spacing: 4

                                                            Repeater {
                                                                model: (modelData.mods.length > 0 ? modelData.mods.split(" ").filter(s => s.length > 0) : []).concat([modelData.key])

                                                                Rectangle {
                                                                    height: 20
                                                                    width: keyText.implicitWidth + 12
                                                                    radius: 5
                                                                    color: Colors.hover
                                                                    border.color: Colors.border
                                                                    border.width: 1

                                                                    Text {
                                                                        id: keyText
                                                                        anchors.centerIn: parent
                                                                        text: modelData
                                                                        color: "#F5F5F5"
                                                                        font.pixelSize: 10
                                                                        font.bold: true
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            text: modelData.dispatcher === "exec" ? modelData.args : (modelData.dispatcher + (modelData.args ? " " + modelData.args : ""))
                                                            color: Colors.foregroundMuted
                                                            font.pixelSize: 11
                                                            elide: Text.ElideRight
                                                            Layout.maximumWidth: 260
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: overlayWindow.groupedBinds.length === 0
                                    text: "Sonuç bulunamadı"
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
}