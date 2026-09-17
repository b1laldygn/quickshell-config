// modules/notifications/NotificationCenter.qml
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
            property var modelData
            screen: modelData

            visible: NotificationService.centerVisible

            anchors { top: true; right: true }
            margins { top: 44; right: 12 }

            implicitWidth: 340
            implicitHeight: Math.min(500, 60 + historyList.contentHeight)
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Notification History"
                            color: "#F5F5F5"
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Clear All"
                            color: Colors.foregroundMuted
                            font.pixelSize: 10
                            visible: NotificationService.history.length > 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.clearHistory()
                            }
                        }
                    }

                    Text {
                        visible: NotificationService.history.length === 0
                        text: "No notifications"
                        color: Colors.foregroundMuted
                        font.pixelSize: 11
                        font.italic: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                    }

                    ListView {
                        id: historyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: NotificationService.history

                        delegate: Rectangle {
                            width: historyList.width
                            implicitHeight: entryContent.implicitHeight + 16
                            radius: 8
                            color: Colors.surface0

                            RowLayout {
                                id: entryContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 8

                                Image {
                                    source: modelData.image || ""
                                    visible: source !== ""
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    fillMode: Image.PreserveAspectFit
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.appName
                                            color: Colors.accent
                                            font.pixelSize: 10
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.time
                                            color: Colors.foregroundMuted
                                            font.pixelSize: 9
                                        }
                                    }

                                    Text {
                                        text: modelData.summary
                                        color: "#F5F5F5"
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: modelData.body
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 10
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }

                                Text {
                                    text: "✕"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 10

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.removeHistoryEntry(index)
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