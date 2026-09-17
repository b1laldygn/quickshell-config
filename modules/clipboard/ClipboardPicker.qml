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
                    width: 480
                    height: 520
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Pano Geçmişi"
                                color: "#F5F5F5"
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Tümünü sil"
                                color: Colors.danger
                                font.pixelSize: 11
                                visible: ClipboardState.entries.length > 0

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardState.wipeAll()
                                }
                            }
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
                                focus: pickerWindow.visible

                                onTextChanged: pickerWindow.filterText = text
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

                        ListView {
                            id: entryList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6

                            model: ClipboardState.entries.filter(e =>
                                pickerWindow.filterText === "" ||
                                e.preview.toLowerCase().includes(pickerWindow.filterText.toLowerCase())
                            )

                            delegate: Rectangle {
                                width: entryList.width
                                implicitHeight: 44
                                radius: 8
                                color: entryHover.containsMouse ? Colors.hover : Colors.surface0

                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: entryHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardState.selectEntry(modelData.raw)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: modelData.preview
                                        color: "#F5F5F5"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "✕"
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 11

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ClipboardState.deleteEntry(modelData.raw)
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: entryList.count === 0
                                text: "Pano geçmişi boş"
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