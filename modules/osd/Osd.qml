// modules/osd/Osd.qml
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

            anchors { bottom: true }
            margins.bottom: 60

            implicitWidth: 220
            implicitHeight: 56
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

                        Rectangle {
                id: card
                anchors.fill: parent
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                opacity: OsdService.visible ? 1 : 0
                scale: OsdService.visible ? 1 : 0.85

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: OsdService.type === "volume" ? "󰕾" : "󰃞"
                        color: "#F5F5F5"
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Colors.surface0

                        Rectangle {
                            width: parent.width * OsdService.value
                            height: parent.height
                            radius: 3
                            color: Colors.accent

                            Behavior on width {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Text {
                        text: Math.round(OsdService.value * 100) + "%"
                        color: Colors.foregroundMuted
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}