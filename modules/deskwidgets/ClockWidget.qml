// modules/deskwidgets/ClockWidget.qml
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
            id: clockWindow
            property var modelData
            screen: modelData

            visible: SettingsState.showClockWidget

            readonly property string corner: SettingsState.clockWidgetCorner
            readonly property bool isAnalog: SettingsState.clockStyle === "analog"
            readonly property bool showSecs: SettingsState.deskClockSeconds
            readonly property real stackOffset: DesktopLayout.offsetFor("clock")
            property date now: new Date()

            anchors {
                top: corner.includes("top")
                bottom: corner.includes("bottom")
                left: corner.includes("left")
                right: corner.includes("right")
            }
            margins {
                top: Math.round(60 * SettingsState.scaleFactor) + (corner.includes("top") ? stackOffset : 0)
                bottom: Math.round(40 * SettingsState.scaleFactor) + (corner.includes("bottom") ? stackOffset : 0)
                left: Math.round(30 * SettingsState.scaleFactor)
                right: Math.round(30 * SettingsState.scaleFactor)
            }

            implicitWidth: isAnalog ? Math.round(210 * SettingsState.scaleFactor) : digitalCol.implicitWidth + Math.round(48 * SettingsState.scaleFactor)
            implicitHeight: (isAnalog ? analogCol.implicitHeight : digitalCol.implicitHeight) + Math.round(32 * SettingsState.scaleFactor)
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            function publish() { DesktopLayout.report("clock", visible ? implicitHeight : 0) }
            onImplicitHeightChanged: publish()
            onVisibleChanged: publish()
            Component.onCompleted: publish()

            Timer {
                interval: 1000
                running: clockWindow.visible
                repeat: true
                onTriggered: clockWindow.now = new Date()
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.round(16 * SettingsState.scaleFactor)
                color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.82)
                border.color: Colors.border
                border.width: 1

                // ---------------- DİJİTAL ----------------
                ColumnLayout {
                    id: digitalCol
                    visible: !clockWindow.isAnalog
                    anchors.centerIn: parent
                    spacing: Math.round(2 * SettingsState.scaleFactor)

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Math.round(6 * SettingsState.scaleFactor)

                        Text {
                            text: TimeFormat.hm(clockWindow.now)
                            color: "#F5F5F5"
                            font.pixelSize: Math.round(56 * SettingsState.scaleFactor)
                            font.bold: true
                        }

                        ColumnLayout {
                            visible: clockWindow.showSecs || TimeFormat.suffix(clockWindow.now) !== ""
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: Math.round(10 * SettingsState.scaleFactor)
                            spacing: 0

                            Text {
                                visible: clockWindow.showSecs
                                text: TimeFormat.seconds(clockWindow.now)
                                color: Colors.accent
                                font.pixelSize: Math.round(22 * SettingsState.scaleFactor)
                                font.bold: true
                                Layout.preferredWidth: Math.round(34 * SettingsState.scaleFactor)
                            }

                            Text {
                                visible: text !== ""
                                text: TimeFormat.suffix(clockWindow.now)
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: TimeFormat.dateText(clockWindow.now)
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // ---------------- ANALOG ----------------
                ColumnLayout {
                    id: analogCol
                    visible: clockWindow.isAnalog
                    anchors.centerIn: parent
                    spacing: Math.round(8 * SettingsState.scaleFactor)

                    Item {
                        id: face
                        Layout.preferredWidth: Math.round(150 * SettingsState.scaleFactor)
                        Layout.preferredHeight: Math.round(150 * SettingsState.scaleFactor)
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.45)
                            border.color: Colors.border
                            border.width: 2
                        }

                        Repeater {
                            model: 12

                            Item {
                                anchors.fill: parent
                                rotation: index * 30

                                Rectangle {
                                    width: index % 3 === 0 ? Math.max(2, Math.round(3 * SettingsState.scaleFactor)) : Math.max(1, Math.round(2 * SettingsState.scaleFactor))
                                    height: index % 3 === 0 ? Math.round(10 * SettingsState.scaleFactor) : Math.round(6 * SettingsState.scaleFactor)
                                    radius: 1
                                    color: index % 3 === 0 ? Colors.accent : Colors.foregroundMuted
                                    x: (parent.width - width) / 2
                                    y: Math.round(6 * SettingsState.scaleFactor)
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            rotation: (clockWindow.now.getHours() % 12) * 30 + clockWindow.now.getMinutes() * 0.5

                            Rectangle {
                                width: Math.max(2, Math.round(5 * SettingsState.scaleFactor))
                                height: face.height * 0.24
                                radius: width / 2
                                color: "#F5F5F5"
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - height
                            }
                        }

                        Item {
                            anchors.fill: parent
                            rotation: clockWindow.now.getMinutes() * 6 + clockWindow.now.getSeconds() * 0.1

                            Rectangle {
                                width: Math.max(2, Math.round(4 * SettingsState.scaleFactor))
                                height: face.height * 0.36
                                radius: width / 2
                                color: "#F5F5F5"
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - height
                            }
                        }

                        Item {
                            visible: clockWindow.showSecs
                            anchors.fill: parent
                            rotation: clockWindow.now.getSeconds() * 6

                            Rectangle {
                                width: Math.max(1, Math.round(2 * SettingsState.scaleFactor))
                                height: face.height * 0.42 + Math.round(14 * SettingsState.scaleFactor)
                                radius: 1
                                color: Colors.accent
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - face.height * 0.42
                            }
                        }

                        Rectangle {
                            width: Math.round(10 * SettingsState.scaleFactor)
                            height: Math.round(10 * SettingsState.scaleFactor)
                            radius: width / 2
                            color: Colors.accent
                            anchors.centerIn: parent
                        }
                    }

                    Text {
                        text: TimeFormat.dateText(clockWindow.now)
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
