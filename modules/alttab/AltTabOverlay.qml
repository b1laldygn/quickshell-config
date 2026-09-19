// modules/alttab/AltTabOverlay.qml
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

            // 'visible' yerine 'isOpen' kullanıyoruz (çakışmayı önlemek için)
            visible: AltTabState.isOpen

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#aa11111b"

            WlrLayershell.layer: WlrLayer.Overlay

            // --- DIŞARI TIKLANDIĞINDA KAPANMASI İÇİN MOUSEAREA BURAYA EKLENDİ ---
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: AltTabState.cancel()
            }
            // -----------------------------------------------------------------

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.8, Math.max(360, rowLayout.implicitWidth + 40))
                height: 140
                radius: 16
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                RowLayout {
                    id: rowLayout
                    anchors.centerIn: parent
                    spacing: 12

                    Repeater {
                        model: AltTabState.windowList

                        ColumnLayout {
                            spacing: 6

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 64
                                height: 64
                                radius: 12
                                color: index === AltTabState.selectedIndex ? Colors.accent : Colors.surface0
                                border.color: index === AltTabState.selectedIndex ? Colors.accent : "transparent"
                                border.width: 2

                                Behavior on color { ColorAnimation { duration: 120 } }

                                property string appId: modelData.wayland?.appId || ""
                                property string iconSrc: {
                                    if (!appId) return ""
                                    const path = Quickshell.iconPath(appId, true)
                                    if (path) return path
                                    return Quickshell.iconPath(appId.toLowerCase(), true)
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 40
                                    height: 40
                                    source: parent.iconSrc
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.iconSrc === ""
                                    text: parent.appId ? parent.appId.charAt(0).toUpperCase() : "?"
                                    color: "#F5F5F5"
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AltTabState.selectAt(index)
                                        AltTabState.commit()
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: 80
                                text: modelData.wayland?.title || ""
                                color: index === AltTabState.selectedIndex ? "#F5F5F5" : Colors.foregroundMuted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Text {
                        visible: AltTabState.windowList.length === 0
                        text: "Açık pencere yok"
                        color: Colors.foregroundMuted
                        font.pixelSize: 12
                        font.italic: true
                    }
                }
            }
        }
    }
}