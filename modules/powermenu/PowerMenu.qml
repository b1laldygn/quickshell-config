import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: powerWindow
            property var modelData
            screen: modelData

            visible: PowerMenuState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            function close() { PowerMenuState.visible = false }

            Item {
                anchors.fill: parent
                focus: powerWindow.visible
                Keys.onEscapePressed: powerWindow.close()

                MouseArea { anchors.fill: parent; onClicked: powerWindow.close() }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    //MouseArea { anchors.fill: parent; onClicked: {} } // dummy to eat clicks — bkz. not

                    Repeater {
                        model: [
                            { icon: "󰤄", label: "Kilitle",    cmd: ["hyprlock"] },
                            { icon: "󰤁", label: "Uyku",       cmd: ["systemctl", "suspend"] },
                            { icon: "󰑐", label: "Yeniden Başlat", cmd: ["systemctl", "reboot"] },
                            { icon: "󰐥", label: "Kapat",      cmd: ["systemctl", "poweroff"] },
                            { icon: "󰍃", label: "Çıkış Yap",  cmd: ["hyprctl", "dispatch", "exit"] }
                        ]

                        delegate: Rectangle {
                            width: 110; height: 130
                            radius: 14
                            color: hoverArea.containsMouse ? Colors.accent : Colors.surface0
                            border.color: Colors.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 34
                                    color: "#F5F5F5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.label
                                    font.pixelSize: 12
                                    color: hoverArea.containsMouse ? Colors.accentText : "#F5F5F5"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    confirmProcess.command = modelData.cmd
                                    confirmProcess.running = true
                                    powerWindow.close()
                                }
                            }
                        }
                    }
                }
            }

            Process { id: confirmProcess }
        }
    }
}