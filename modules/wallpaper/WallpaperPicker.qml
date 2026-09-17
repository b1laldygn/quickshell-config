// modules/wallpaper/WallpaperPicker.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pickerWindow
            property var modelData
            screen: modelData

            visible: WallpaperPickerState.visible

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                anchors.fill: parent
                focus: pickerWindow.visible

                Keys.onEscapePressed: WallpaperPickerState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: WallpaperPickerState.visible = false
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: parent.height * 0.85
                    spacing: 12

                    Text {
                        text: "Duvar Kağıdı Seç"
                        color: Colors.foreground
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: Colors.backgroundAlt
                        border.color: Colors.border
                        border.width: 1
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {}
                        }

                        FolderListModel {
                            id: folderModel
                            folder: "file:///home/bilal/Pictures"
                            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                            showDirs: false
                            sortField: FolderListModel.Name
                        }

                        GridView {
                            id: grid
                            anchors.fill: parent
                            anchors.margins: 12
                            model: folderModel
                            clip: true
                            reuseItems: true
                            property int columns: Math.max(1, Math.floor(width / 180))
                            cellWidth: width / columns
                            cellHeight: 110

                            delegate: Rectangle {
                                width: grid.cellWidth - 8
                                height: grid.cellHeight - 8
                                radius: 8
                                color: Colors.surface0
                                border.color: hoverArea.containsMouse ? Colors.accent : "transparent"
                                border.width: 2
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 200
                                    sourceSize.height: 130
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WallpaperService.setWallpaper(filePath)
                                        WallpaperPickerState.visible = false
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