// modules/notifications/NotificationCenter.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    id: rootCenter

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: centerWin
            property var modelData
            screen: modelData

            visible: NotificationService.centerVisible

            anchors { top: true; right: true }
            margins {
                top: Math.round(44 * SettingsState.scaleFactor)
                right: Math.round(12 * SettingsState.scaleFactor)
            }

            implicitWidth: Math.round(360 * SettingsState.scaleFactor)
            implicitHeight: Math.min(
                Math.round(580 * SettingsState.scaleFactor),
                headerCol.implicitHeight + (filteredHistory.length > 0 ? historyList.contentHeight + 20 : 80)
            )
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1

            property string searchQuery: ""
            property string selectedApp: "all"

            readonly property var availableApps: {
                const map = {}
                for (let i = 0; i < NotificationService.history.length; i++) {
                    const name = NotificationService.history[i].appName
                    if (name) map[name] = true
                }
                return ["all", ...Object.keys(map)]
            }

            readonly property var filteredHistory: {
                const list = NotificationService.history || []
                const q = centerWin.searchQuery.trim().toLowerCase()
                const sel = centerWin.selectedApp

                return list.filter(item => {
                    if (sel !== "all" && (item.appName || "").toLowerCase() !== sel.toLowerCase()) {
                        return false
                    }
                    if (q === "") return true
                    const mApp = (item.appName || "").toLowerCase().includes(q)
                    const mSum = (item.summary || "").toLowerCase().includes(q)
                    const mBody = (item.body || "").toLowerCase().includes(q)
                    return mApp || mSum || mBody
                })
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.round(12 * SettingsState.scaleFactor)
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: headerCol
                    anchors.fill: parent
                    anchors.margins: Math.round(12 * SettingsState.scaleFactor)
                    spacing: Math.round(8 * SettingsState.scaleFactor)

                    // 1. Üst Bar: Başlık, DND Toggle & Tümünü Sil
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: I18n.t("notificationHistory")
                            color: "#F5F5F5"
                            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // DND Hızlı Toggle Hapı
                        Rectangle {
                            Layout.preferredHeight: Math.round(24 * SettingsState.scaleFactor)
                            Layout.preferredWidth: dndRow.implicitWidth + Math.round(16 * SettingsState.scaleFactor)
                            radius: Math.round(12 * SettingsState.scaleFactor)
                            color: SettingsState.dndEnabled
                                ? (Colors.warning || "#fab387")
                                : (dndHover.containsMouse ? Colors.hover : Colors.surface0)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                id: dndRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: SettingsState.dndEnabled ? "󰂛" : "󰂚"
                                    color: SettingsState.dndEnabled ? "#11111b" : Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    text: "DND"
                                    color: SettingsState.dndEnabled ? "#11111b" : Colors.foregroundMuted
                                    font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: dndHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.toggleDnd()
                            }
                        }

                        // Tümünü Sil butonu
                        Rectangle {
                            visible: NotificationService.history.length > 0
                            Layout.preferredHeight: Math.round(24 * SettingsState.scaleFactor)
                            Layout.preferredWidth: clearText.implicitWidth + Math.round(12 * SettingsState.scaleFactor)
                            radius: Math.round(6 * SettingsState.scaleFactor)
                            color: clearHover.containsMouse ? Colors.hover : "transparent"

                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: I18n.t("clearAll")
                                color: clearHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.clearHistory()
                            }
                        }
                    }

                    // 2. Arama Çubuğu
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(30 * SettingsState.scaleFactor)
                        radius: Math.round(6 * SettingsState.scaleFactor)
                        color: Colors.surface0
                        border.color: searchInput.activeFocus ? Colors.accent : Colors.border
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "󰍉"
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#F5F5F5"
                                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                clip: true
                                selectByMouse: true
                                text: centerWin.searchQuery
                                onTextChanged: centerWin.searchQuery = text

                                Text {
                                    visible: searchInput.text === "" && !searchInput.activeFocus
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: I18n.t("searchNotifications")
                                    color: Colors.foregroundMuted
                                    font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                }
                            }

                            Text {
                                visible: searchInput.text !== ""
                                text: "✕"
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = ""
                                        centerWin.searchQuery = ""
                                    }
                                }
                            }
                        }
                    }

                    // 3. Uygulama Filtre Hapları (Birden fazla uygulama varsa göster)
                    Flickable {
                        visible: centerWin.availableApps.length > 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(26 * SettingsState.scaleFactor)
                        contentWidth: chipsRow.implicitWidth
                        clip: true

                        RowLayout {
                            id: chipsRow
                            spacing: 6

                            Repeater {
                                model: centerWin.availableApps

                                delegate: Rectangle {
                                    readonly property bool isSelected: centerWin.selectedApp === modelData
                                    Layout.preferredHeight: Math.round(22 * SettingsState.scaleFactor)
                                    Layout.preferredWidth: chipText.implicitWidth + Math.round(14 * SettingsState.scaleFactor)
                                    radius: Math.round(11 * SettingsState.scaleFactor)
                                    color: isSelected ? Colors.accent : (chipHover.containsMouse ? Colors.hover : Colors.surface0)

                                    Text {
                                        id: chipText
                                        anchors.centerIn: parent
                                        text: modelData === "all" ? I18n.t("filterAll") : modelData
                                        color: isSelected ? Colors.accentText : (chipHover.containsMouse ? "#F5F5F5" : Colors.foregroundMuted)
                                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                        font.bold: isSelected
                                    }

                                    MouseArea {
                                        id: chipHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: centerWin.selectedApp = modelData
                                    }
                                }
                            }
                        }
                    }

                    // 4. Boş Durum
                    Text {
                        visible: centerWin.filteredHistory.length === 0
                        text: NotificationService.history.length === 0
                            ? I18n.t("noNotifications")
                            : "Eşleşen bildirim bulunamadı."
                        color: Colors.foregroundMuted
                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                        font.italic: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Math.round(20 * SettingsState.scaleFactor)
                        Layout.bottomMargin: Math.round(20 * SettingsState.scaleFactor)
                    }

                    // 5. Bildirim Geçmişi Listesi
                    ListView {
                        id: historyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Math.round(6 * SettingsState.scaleFactor)
                        model: centerWin.filteredHistory

                        delegate: Rectangle {
                            id: entryRect
                            width: historyList.width
                            implicitHeight: entryContent.implicitHeight + Math.round(16 * SettingsState.scaleFactor)
                            radius: Math.round(8 * SettingsState.scaleFactor)
                            color: Colors.surface0
                            border.color: modelData.urgency === 2 ? Colors.danger : "transparent"
                            border.width: modelData.urgency === 2 ? 1 : 0

                            readonly property bool isMuted: NotificationService.isAppMuted(modelData.appName)

                            // Sol aciliyet çizgisi
                            Rectangle {
                                width: Math.round(3 * SettingsState.scaleFactor)
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: Math.round(2 * SettingsState.scaleFactor)
                                radius: 1
                                color: modelData.urgency === 2
                                    ? Colors.danger
                                    : (modelData.urgency === 0 ? Colors.border : Colors.accent)
                            }

                            RowLayout {
                                id: entryContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(8 * SettingsState.scaleFactor)
                                anchors.leftMargin: Math.round(12 * SettingsState.scaleFactor)
                                spacing: Math.round(8 * SettingsState.scaleFactor)

                                Image {
                                    source: modelData.image || ""
                                    visible: source !== ""
                                    Layout.preferredWidth: Math.round(28 * SettingsState.scaleFactor)
                                    Layout.preferredHeight: Math.round(28 * SettingsState.scaleFactor)
                                    fillMode: Image.PreserveAspectFit
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(2 * SettingsState.scaleFactor)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: modelData.appName
                                            color: Colors.accent
                                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                            font.bold: true
                                        }

                                        Text {
                                            visible: entryRect.isMuted
                                            text: "󰝟"
                                            color: Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: modelData.time
                                            color: Colors.foregroundMuted
                                            font.pixelSize: Math.round(9 * SettingsState.scaleFactor)
                                        }
                                    }

                                    Text {
                                        text: modelData.summary
                                        color: "#F5F5F5"
                                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                        font.bold: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: modelData.body
                                        color: Colors.foregroundMuted
                                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }

                                // Eylem Butonları
                                RowLayout {
                                    spacing: 4
                                    Layout.alignment: Qt.AlignTop

                                    // Sessize Al / Sesi Aç Butonu
                                    Rectangle {
                                        width: Math.round(18 * SettingsState.scaleFactor)
                                        height: Math.round(18 * SettingsState.scaleFactor)
                                        radius: 3
                                        color: actMuteHover.containsMouse ? Colors.hover : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: entryRect.isMuted ? "󰕾" : "󰝟"
                                            color: entryRect.isMuted ? Colors.accent : Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        MouseArea {
                                            id: actMuteHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (entryRect.isMuted) {
                                                    NotificationService.unmuteApp(modelData.appName)
                                                } else {
                                                    NotificationService.muteApp(modelData.appName)
                                                }
                                            }
                                        }
                                    }

                                    // Bildirimi Sil Butonu
                                    Rectangle {
                                        width: Math.round(18 * SettingsState.scaleFactor)
                                        height: Math.round(18 * SettingsState.scaleFactor)
                                        radius: 3
                                        color: actDelHover.containsMouse ? Colors.hover : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: actDelHover.containsMouse ? Colors.danger : Colors.foregroundMuted
                                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                        }

                                        MouseArea {
                                            id: actDelHover
                                            anchors.fill: parent
                                            hoverEnabled: true
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
}
