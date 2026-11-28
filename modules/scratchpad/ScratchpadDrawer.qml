// modules/scratchpad/ScratchpadDrawer.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: spWindow
            property var modelData
            screen: modelData

            visible: fx.shown

            PopupFx {
                id: fx
                open: ScratchpadState.visible
            }

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ScratchpadState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            function iconFor(appClass) {
                if (!appClass) return ""
                let p = Quickshell.iconPath(appClass, true)
                if (p) return p
                p = Quickshell.iconPath(appClass.toLowerCase(), true)
                if (p) return p
                const last = appClass.split(".").pop()
                return Quickshell.iconPath(last.toLowerCase(), true)
            }

            Item {
                anchors.fill: parent
                focus: ScratchpadState.visible
                Keys.onEscapePressed: ScratchpadState.visible = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: ScratchpadState.visible = false
                }

                Rectangle {
                    id: card
                    readonly property real s: SettingsState.scaleFactor
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Math.round((SettingsState.barHeight + 8) * s)
                    anchors.rightMargin: Math.round(12 * s)
                    width: Math.round(330 * s)
                    height: Math.min(Math.round(500 * s), mainCol.implicitHeight + Math.round(28 * s))
                    radius: Math.round(14 * s)
                    opacity: fx.cardOpacity
                    scale: fx.cardScale
                    transformOrigin: Item.TopRight
                    transform: Translate { y: fx.cardY }
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        id: mainCol
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: Math.round(14 * card.s)
                        }
                        spacing: Math.round(10 * card.s)

                        // ── Başlık ───────────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(8 * card.s)

                            Rectangle {
                                width: Math.round(26 * card.s)
                                height: width
                                radius: Math.round(8 * card.s)
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰘸"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(14 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            Text {
                                text: I18n.t("scratchpad")
                                color: Colors.foreground
                                font.pixelSize: Math.round(14 * card.s)
                                font.bold: true
                            }

                            Rectangle {
                                visible: ScratchpadState.count > 0
                                height: Math.round(20 * card.s)
                                width: Math.max(height, countTxt.implicitWidth + Math.round(12 * card.s))
                                radius: height / 2
                                color: Colors.surface0

                                Text {
                                    id: countTxt
                                    anchors.centerIn: parent
                                    text: ScratchpadState.count
                                    color: Colors.accent
                                    font.pixelSize: Math.round(10 * card.s)
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: refreshHover.containsMouse ? Colors.hover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    color: ScratchpadState.loading ? Colors.accent : Colors.foregroundMuted
                                    font.pixelSize: Math.round(13 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: refreshHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ScratchpadState.refresh()
                                }
                            }

                            Rectangle {
                                width: Math.round(24 * card.s)
                                height: width
                                radius: Math.round(6 * card.s)
                                color: closeHover.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * card.s)
                                }

                                MouseArea {
                                    id: closeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ScratchpadState.visible = false
                                }
                            }
                        }

                        // ── Aktif Pencereyi Sakla Butonu ─────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(44 * card.s)
                            radius: Math.round(10 * card.s)
                            color: stashMouse.containsMouse
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24)
                                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                            border.width: 1
                            visible: ScratchpadState.activeAddress !== ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(10 * card.s)
                                anchors.rightMargin: Math.round(10 * card.s)
                                spacing: Math.round(8 * card.s)

                                Text {
                                    text: "󰐕"
                                    color: Colors.accent
                                    font.pixelSize: Math.round(15 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: I18n.t("stashActive")
                                        color: Colors.accent
                                        font.pixelSize: Math.round(11 * card.s)
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: ScratchpadState.activeTitle
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(10 * card.s)
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: stashMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ScratchpadState.stashActive()
                            }
                        }

                        // ── Saklı Pencereler Listesi ─────────────────────────
                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScratchpadState.count > 0
                                ? Math.min(Math.round(330 * card.s), contentHeight)
                                : Math.round(110 * card.s)
                            clip: true
                            spacing: Math.round(6 * card.s)
                            model: ScratchpadState.items

                            delegate: Rectangle {
                                width: listView.width
                                height: Math.round(52 * card.s)
                                radius: Math.round(10 * card.s)
                                color: itemHover.containsMouse ? Colors.hover : Colors.surface0
                                border.color: itemHover.containsMouse ? Colors.accent : Colors.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(10 * card.s)
                                    anchors.rightMargin: Math.round(8 * card.s)
                                    spacing: Math.round(10 * card.s)

                                    // Uygulama ikonu
                                    Item {
                                        width: Math.round(26 * SettingsState.scaleFactor)
                                        height: width

                                        readonly property string iconSrc: modelData ? spWindow.iconFor(modelData.appClass) : ""

                                        Image {
                                            anchors.fill: parent
                                            source: parent.iconSrc
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: parent.iconSrc !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: parent.iconSrc === ""
                                            text: "󰖯"
                                            color: Colors.accent
                                            font.pixelSize: Math.round(16 * SettingsState.scaleFactor)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }

                                    // Başlık & Sınıf
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(1 * SettingsState.scaleFactor)

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData ? modelData.title : ""
                                            color: Colors.foreground
                                            font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Math.round(6 * SettingsState.scaleFactor)

                                            Text {
                                                text: modelData ? modelData.appClass : ""
                                                color: Colors.foregroundMuted
                                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                visible: modelData && modelData.workspaceName !== ""
                                                height: Math.round(15 * SettingsState.scaleFactor)
                                                width: wsTag.implicitWidth + Math.round(8 * SettingsState.scaleFactor)
                                                radius: Math.round(4 * SettingsState.scaleFactor)
                                                color: Colors.backgroundAlt

                                                Text {
                                                    id: wsTag
                                                    anchors.centerIn: parent
                                                    text: modelData ? modelData.workspaceName : ""
                                                    color: Colors.foregroundMuted
                                                    font.pixelSize: Math.round(9 * SettingsState.scaleFactor)
                                                }
                                            }
                                        }
                                    }

                                    // Pencereyi Kapat Butonu
                                    Rectangle {
                                        width: Math.round(24 * card.s)
                                        height: width
                                        radius: Math.round(6 * card.s)
                                        color: delHover.containsMouse ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.22) : "transparent"
                                        z: 2

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: delHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * card.s)
                                        }

                                        MouseArea {
                                            id: delHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (modelData) ScratchpadState.closeWindow(modelData.address)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (modelData) ScratchpadState.restoreWindow(modelData.address)
                                }
                            }

                            // Boş Durum
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: ScratchpadState.count === 0
                                spacing: Math.round(6 * card.s)

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰘸"
                                    color: Colors.foregroundMuted
                                    opacity: 0.45
                                    font.pixelSize: Math.round(26 * card.s)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: I18n.t("scratchpadEmpty")
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * card.s)
                                    font.italic: true
                                }
                            }
                        }

                        // ── Alt İpucu ────────────────────────────────────────
                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("scratchpadHint")
                            color: Colors.foregroundMuted
                            font.pixelSize: Math.round(10 * card.s)
                            opacity: 0.8
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
