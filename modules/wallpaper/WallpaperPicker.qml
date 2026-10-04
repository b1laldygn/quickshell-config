// modules/wallpaper/WallpaperPicker.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import "root:/config"
import "root:/services"

Scope {
    PanelWindow {
        id: pickerWindow
        screen: Quickshell.screens[0]

        visible: WallpaperPickerState.visible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "#cc11111b"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        property string hoveredName: ""

        readonly property string activeName: WallpaperService.currentWallpaperPath.split("/").pop()
        readonly property string shownOriginal: hoveredName !== "" ? hoveredName.slice(0, -4) : activeName
        readonly property string shownThumb: shownOriginal !== ""
            ? "file://" + WallpaperThumbs.thumbDir + "/" + shownOriginal + ".jpg"
            : ""

        property var transitionOptions: [
            { key: "none", label: I18n.t("tNone") },
            { key: "fade", label: I18n.t("tFade") },
            { key: "wipe", label: I18n.t("tWipe") },
            { key: "wave", label: I18n.t("tWave") },
            { key: "grow", label: I18n.t("tGrow") },
            { key: "outer", label: I18n.t("tOuter") },
            { key: "center", label: I18n.t("tCenter") },
            { key: "random", label: I18n.t("tRandom") }
        ]

        onVisibleChanged: {
            if (visible) {
                WallpaperThumbs.generate()
            } else {
                hoveredName = ""
            }
        }

        Item {
            anchors.fill: parent
            focus: pickerWindow.visible

            Keys.onEscapePressed: WallpaperPickerState.visible = false

            MouseArea {
                anchors.fill: parent
                onClicked: WallpaperPickerState.visible = false
            }

            Rectangle {
                anchors.centerIn: parent
                // Pencere genişliğini Grid (5 sütun * 160px = 800px) + Sağ Panel (300px) + Aralıklar kadar daraltıyoruz
                width: 1160
                height: 640
                radius: 12
                color: Colors.backgroundAlt
                border.color: Colors.border
                border.width: 1
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                FolderListModel {
                    id: folderModel
                    folder: "file://" + WallpaperThumbs.thumbDir
                    nameFilters: ["*.jpg"]
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: I18n.t("pickWallpaper")
                        color: Colors.foreground
                        font.pixelSize: 20
                        font.bold: true
                    }

                    // Düz Row kullanarak elemanların arasına boşluk girmesini önlüyoruz
                    Row {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16

                        // ---------- SOL: GRID ----------
                        GridView {
                            id: grid
                            width: 800 // 5 adet 160px kart için tam genişlik
                            height: parent.height
                            model: folderModel
                            clip: true
                            cellWidth: 160
                            cellHeight: 110

                            delegate: Rectangle {
                                id: cell
                                readonly property string originalName: fileName.slice(0, -4)
                                readonly property bool isActive: originalName === pickerWindow.activeName

                                width: grid.cellWidth - 10
                                height: grid.cellHeight - 10
                                radius: 8
                                color: Colors.surface0
                                border.color: isActive
                                    ? Colors.accent
                                    : (hoverArea.containsMouse ? Colors.foregroundMuted : "transparent")
                                border.width: 2
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    visible: cell.isActive
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#cc000000"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#F5F5F5"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onEntered: pickerWindow.hoveredName = fileName
                                    onExited: {
                                        if (pickerWindow.hoveredName === fileName) pickerWindow.hoveredName = ""
                                    }

                                    onClicked: {
                                        WallpaperService.setWallpaper(WallpaperThumbs.sourceDir + "/" + cell.originalName)
                                        WallpaperPickerState.visible = false
                                    }
                                }
                            }
                        }

                        // Dikey Ayrım Çizgisi
                        Rectangle {
                            width: 1
                            height: parent.height
                            color: Colors.border
                        }

                        // ---------- SAĞ: ÖNİZLEME + AYARLAR ----------
                        ColumnLayout {
                            width: 300
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 169
                                radius: 8
                                color: Colors.surface0
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: pickerWindow.shownThumb
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: pickerWindow.shownOriginal
                                    color: "#F5F5F5"
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    visible: pickerWindow.shownOriginal !== ""
                                             && pickerWindow.shownOriginal === pickerWindow.activeName
                                    implicitWidth: activeText.implicitWidth + 14
                                    implicitHeight: 20
                                    radius: 10
                                    color: Colors.accent

                                    Text {
                                        id: activeText
                                        anchors.centerIn: parent
                                        text: I18n.t("activeLabel")
                                        color: Colors.accentText
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Colors.border
                            }

                            Text {
                                text: I18n.t("transition")
                                color: Colors.accent
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: pickerWindow.transitionOptions

                                    Rectangle {
                                        implicitWidth: chipText.implicitWidth + 16
                                        implicitHeight: 28
                                        radius: 6
                                        color: SettingsState.wallpaperTransition === modelData.key
                                            ? Colors.accent : Colors.surface0

                                        Text {
                                            id: chipText
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: SettingsState.wallpaperTransition === modelData.key
                                                ? Colors.accentText : "#F5F5F5"
                                            font.pixelSize: 11
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                SettingsState.wallpaperTransition = modelData.key
                                                SettingsState.save()
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: SettingsState.wallpaperTransition !== "none"
                                spacing: 8

                                Text {
                                    text: I18n.t("duration")
                                    color: "#F5F5F5"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: Colors.surface0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        color: "#F5F5F5"
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const v = SettingsState.wallpaperTransitionDuration - 0.5
                                            SettingsState.wallpaperTransitionDuration = Math.max(0.5, Math.round(v * 10) / 10)
                                            SettingsState.save()
                                        }
                                    }
                                }

                                Text {
                                    text: Number(SettingsState.wallpaperTransitionDuration).toFixed(1) + " s"
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.preferredWidth: 40
                                }

                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: Colors.surface0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: "#F5F5F5"
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const v = SettingsState.wallpaperTransitionDuration + 0.5
                                            SettingsState.wallpaperTransitionDuration = Math.min(3.0, Math.round(v * 10) / 10)
                                            SettingsState.save()
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