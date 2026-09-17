// modules/launcher/Launcher.qml
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
            id: launcherWindow
            property var modelData
            screen: modelData

            visible: LauncherState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property string searchText: ""
            property int selectedIndex: 0

            property var filteredApps: {
    const all = DesktopEntries.applications.values
    const query = searchText.toLowerCase().trim()
    if (query === "") {
        return all.slice().sort((a, b) => (a.name || "").localeCompare(b.name || ""))
    }
    const list = all.filter(app => {
        const name = (app.name || "").toLowerCase()
        const generic = (app.genericName || "").toLowerCase()
        const keywords = (app.keywords || []).join(" ").toLowerCase()
        return name.includes(query) || generic.includes(query) || keywords.includes(query)
    })
    list.sort((a, b) => {
        const aName = (a.name || "").toLowerCase()
        const bName = (b.name || "").toLowerCase()
        const aStarts = aName.startsWith(query) ? 0 : 1
        const bStarts = bName.startsWith(query) ? 0 : 1
        if (aStarts !== bStarts) return aStarts - bStarts
        return aName.localeCompare(bName)
    })
    return list
}

            function launchSelected() {
                const list = filteredApps
                if (list.length === 0) return
                const idx = Math.min(selectedIndex, list.length - 1)
                list[idx].execute()
                closeAndReset()
            }

            function closeAndReset() {
                LauncherState.visible = false
                searchText = ""
                selectedIndex = 0
            }

            onVisibleChanged: {
                if (visible) {
                searchText = ""
                selectedIndex = 0
                Qt.callLater(() => searchInput.forceActiveFocus())
    }
}

            Item {
                anchors.fill: parent
                focus: launcherWindow.visible

                Keys.onEscapePressed: launcherWindow.closeAndReset()

                MouseArea {
                    anchors.fill: parent
                    onClicked: launcherWindow.closeAndReset()
                }

                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -80
                    width: 480
                    height: 440
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: Colors.surface0
                            border.color: Colors.accent
                            border.width: 1

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                anchors.margins: 10
                                color: "#F5F5F5"
                                font.pixelSize: 14
                                clip: true
                                focus: true // Uygulama açıldığında odağı kabul etmesini sağlar
                                onTextChanged: {
                                    launcherWindow.searchText = text
                                    launcherWindow.selectedIndex = 0
                                }
                                Keys.onDownPressed: {
                                    if (launcherWindow.selectedIndex < launcherWindow.filteredApps.length - 1)
                                        launcherWindow.selectedIndex++
                                }
                                Keys.onUpPressed: {
                                    if (launcherWindow.selectedIndex > 0)
                                        launcherWindow.selectedIndex--
                                }
                                Keys.onReturnPressed: launcherWindow.launchSelected()
                                Keys.onEnterPressed: launcherWindow.launchSelected()
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Uygulama ara..."
                                color: Colors.foregroundMuted
                                font.pixelSize: 14
                                visible: searchInput.text.length === 0
                            }
                        }

                        ListView {
                            id: appList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: launcherWindow.filteredApps
                            currentIndex: launcherWindow.selectedIndex

                            highlightMoveDuration: 100
                            highlightFollowsCurrentItem: true

                            delegate: Rectangle {
                                width: appList.width
                                height: 48
                                radius: 8
                                color: index === launcherWindow.selectedIndex ? Colors.accent : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Image {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        visible: source !== ""
                                    }

                                    Text {
                                        visible: !parent.children[0].visible
                                        text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                        color: "#F5F5F5"
                                        font.pixelSize: 16
                                        font.bold: true
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            text: modelData.name || ""
                                            color: index === launcherWindow.selectedIndex ? Colors.accentText : "#F5F5F5"
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.genericName || ""
                                            color: index === launcherWindow.selectedIndex ? Colors.accentText : Colors.foregroundMuted
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: launcherWindow.selectedIndex = index
                                    onClicked: {
                                        modelData.execute()
                                        launcherWindow.closeAndReset()
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appList.count === 0
                                text: "Sonuç bulunamadı"
                                color: Colors.foregroundMuted
                                font.pixelSize: 12
                                font.italic: true
                            }
                        }
                    }
                }
            }
        }
    }
}