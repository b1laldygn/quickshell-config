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
            readonly property var dateLocale: Qt.locale(SettingsState.language === "en" ? "en_US" : "tr_TR")
            property date now: new Date()

            anchors {
                top: corner.includes("top")
                bottom: corner.includes("bottom")
                left: corner.includes("left")
                right: corner.includes("right")
            }
            readonly property real stackOffset: DesktopLayout.offsetFor("clock")

            margins {
                top: 60 + (corner.includes("top") ? stackOffset : 0)
                bottom: 40 + (corner.includes("bottom") ? stackOffset : 0)
                left: 30
                right: 30
            }
            implicitWidth: isAnalog ? 210 : digitalCol.implicitWidth + 48
            implicitHeight: (isAnalog ? analogCol.implicitHeight : digitalCol.implicitHeight) + 32
            function publish() { DesktopLayout.report("clock", visible ? implicitHeight : 0) }
            onImplicitHeightChanged: publish()
            onVisibleChanged: publish()
            Component.onCompleted: publish()
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Timer {
                interval: 1000
                running: clockWindow.visible
                repeat: true
                onTriggered: clockWindow.now = new Date()
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.82)
                border.color: Colors.border
                border.width: 1

                // ---------------- DİJİTAL ----------------
                ColumnLayout {
                    id: digitalCol
                    visible: !clockWindow.isAnalog
                    anchors.centerIn: parent
                    spacing: 2

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: Qt.formatTime(clockWindow.now, "HH:mm")
                            color: "#F5F5F5"
                            font.pixelSize: 56
                            font.bold: true
                        }

                        Text {
                            text: Qt.formatTime(clockWindow.now, "ss")
                            color: Colors.accent
                            font.pixelSize: 22
                            font.bold: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 10
                        }
                    }

                    Text {
                        text: clockWindow.dateLocale.toString(clockWindow.now, "dddd, d MMMM")
                        color: Colors.foregroundMuted
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // ---------------- ANALOG ----------------
                ColumnLayout {
                    id: analogCol
                    visible: clockWindow.isAnalog
                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        id: face
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.45)
                            border.color: Colors.border
                            border.width: 2
                        }

                        // saat çizgileri
                        Repeater {
                            model: 12

                            Item {
                                anchors.fill: parent
                                rotation: index * 30

                                Rectangle {
                                    width: index % 3 === 0 ? 3 : 2
                                    height: index % 3 === 0 ? 10 : 6
                                    radius: 1
                                    color: index % 3 === 0 ? Colors.accent : Colors.foregroundMuted
                                    x: (parent.width - width) / 2
                                    y: 6
                                }
                            }
                        }

                        // akrep
                        Item {
                            anchors.fill: parent
                            rotation: (clockWindow.now.getHours() % 12) * 30 + clockWindow.now.getMinutes() * 0.5

                            Rectangle {
                                width: 5
                                height: face.height * 0.24
                                radius: 2.5
                                color: "#F5F5F5"
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - height
                            }
                        }

                        // yelkovan
                        Item {
                            anchors.fill: parent
                            rotation: clockWindow.now.getMinutes() * 6 + clockWindow.now.getSeconds() * 0.1

                            Rectangle {
                                width: 4
                                height: face.height * 0.36
                                radius: 2
                                color: "#F5F5F5"
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - height
                            }
                        }

                        // saniye ibresi
                        Item {
                            anchors.fill: parent
                            rotation: clockWindow.now.getSeconds() * 6

                            Rectangle {
                                width: 2
                                height: face.height * 0.42 + 14
                                radius: 1
                                color: Colors.accent
                                x: (parent.width - width) / 2
                                y: parent.height / 2 - face.height * 0.42
                            }
                        }

                        // orta başlık
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Colors.accent
                            anchors.centerIn: parent
                        }
                    }

                    Text {
                        text: clockWindow.dateLocale.toString(clockWindow.now, "dddd, d MMMM")
                        color: Colors.foregroundMuted
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}