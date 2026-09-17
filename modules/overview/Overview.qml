// modules/overview/Overview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewWindow
            property var modelData
            screen: modelData

            visible: OverviewState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                anchors.fill: parent
                focus: overviewWindow.visible

                Keys.onEscapePressed: OverviewState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: OverviewState.visible = false
                }

                GridLayout {
                    anchors.centerIn: parent
                    columns: 5
                    rowSpacing: 14
                    columnSpacing: 14

                    Repeater {
                        model: 10

                        Rectangle {
                            id: wsCell
                            property int wsId: index + 1
                            property var wsData: {
                                const found = Hyprland.workspaces.values.find(w => w.id === wsId)
                                return found || null
                            }
                            property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                            Layout.preferredWidth: 220
                            Layout.preferredHeight: 140
                            radius: 10
                            color: Colors.backgroundAlt
                            border.color: isActive ? Colors.accent : Colors.border
                            border.width: isActive ? 2 : 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: WallpaperService.currentWallpaperPath
                                    ? "file://" + WallpaperService.currentWallpaperPath
                                    : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: source !== ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "#55000000"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Hyprland.dispatch("workspace " + wsCell.wsId)
                                    OverviewState.visible = false
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Text {
                                    text: wsCell.wsId
                                    color: wsCell.isActive ? Colors.accent : "#F5F5F5"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 10

                                        Repeater {
                                            model: wsCell.wsData?.toplevels?.values || []

                                            Rectangle {
                                                width: 52
                                                height: 52
                                                radius: 12
                                                color: modelData.activated ? Colors.accent : "#40000000"
                                                border.color: modelData.activated ? Colors.accent : "transparent"
                                                border.width: 2

                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                property string appId: modelData.wayland?.appId || ""
                                                property var iconOverrides: ({
                                                    "code": "vscode",
                                                    "com.anthropic.Claude": "claude-desktop",
                                                    "YouTube Music Desktop App": "youtube-music-desktop-app"
                                                })
                                                property string iconSrc: {
                                                    if (!appId) return ""
                                                    const override = iconOverrides[appId]
                                                    if (override) {
                                                        const path = Quickshell.iconPath(override, true)
                                                        if (path) return path
                                                    }
                                                    let path = Quickshell.iconPath(appId, true)
                                                    if (path) return path
                                                    path = Quickshell.iconPath(appId.toLowerCase(), true)
                                                    if (path) return path
                                                    const lastSeg = appId.split(".").pop()
                                                    return Quickshell.iconPath(lastSeg.toLowerCase(), true)
                                                }

                                                Image {
                                                    anchors.centerIn: parent
                                                    width: 36
                                                    height: 36
                                                    source: parent.iconSrc
                                                    fillMode: Image.PreserveAspectFit
                                                    asynchronous: true
                                                    visible: parent.iconSrc !== ""
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: parent.iconSrc === ""
                                                    text: parent.appId ? parent.appId.charAt(0).toUpperCase() : "?"
                                                    color: "#F5F5F5"
                                                    font.pixelSize: 20
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: !wsCell.wsData || (wsCell.wsData.toplevels?.values.length ?? 0) === 0
                                    text: "Boş"
                                    color: "#cdd6f4"
                                    font.pixelSize: 10
                                    font.italic: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}