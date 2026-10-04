// modules/overview/Overview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewWindow
            property var modelData
            screen: modelData

            visible: OverviewState.visible

            anchors { top: true; bottom: true; left: true; right: true }
            color: "#cc11111b"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property int drawW: 190
            readonly property int drawH: 100

            // ---- Sürükleme state'i ----
            property bool dragActive: false
            property string dragAddress: ""
            property int dragOriginWsId: -1
            property real dragRealX: 0
            property real dragRealY: 0
            property real dragGlobalX: 0
            property real dragGlobalY: 0
            property real pressGlobalX: 0
            property real pressGlobalY: 0
            property string dragAppId: ""

            property var cellRefs: ({})
            property var drawAreaRefs: ({})

            property var iconOverrides: ({
                "code": "vscode",
                "com.anthropic.Claude": "claude-desktop",
                "YouTube Music Desktop App": "youtube-music-desktop-app"
            })

            function iconFor(appId) {
                if (!appId) return ""
                const override = iconOverrides[appId]
                if (override) {
                    const p = Quickshell.iconPath(override, true)
                    if (p) return p
                }
                let p = Quickshell.iconPath(appId, true)
                if (p) return p
                p = Quickshell.iconPath(appId.toLowerCase(), true)
                if (p) return p
                const lastSeg = appId.split(".").pop()
                return Quickshell.iconPath(lastSeg.toLowerCase(), true)
            }

            function monitorGeometryFor(ws) {
                const monName = ws?.lastIpcObject?.monitor
                if (!monName) return null
                const mon = Hyprland.monitors.values.find(m => m.name === monName)
                if (!mon || !mon.lastIpcObject) return null
                return {
                    x: mon.lastIpcObject.x,
                    y: mon.lastIpcObject.y,
                    width: mon.lastIpcObject.width,
                    height: mon.lastIpcObject.height
                }
            }

            function buildRenderData() {
                Hyprland.refreshMonitors()
                Hyprland.refreshWorkspaces()
                Hyprland.refreshToplevels()

                const result = []
                for (let i = 1; i <= 10; i++) {
                    const ws = Hyprland.workspaces.values.find(w => w.id === i) || null
                    const monGeom = ws ? monitorGeometryFor(ws) : null
                    const windows = []

                    if (ws && monGeom && monGeom.width > 0 && monGeom.height > 0) {
                        const scaleX = drawW / monGeom.width
                        const scaleY = drawH / monGeom.height
                        const tls = ws.toplevels ? ws.toplevels.values : []

                        for (const t of tls) {
                            const g = t.lastIpcObject
                            if (!g || !g.at || !g.size) continue

                            windows.push({
                                address: g.address || "",
                                appId: t.wayland?.appId || "",
                                title: t.wayland?.title || "",
                                activated: !!t.activated,
                                rx: (g.at[0] - monGeom.x) * scaleX,
                                ry: (g.at[1] - monGeom.y) * scaleY,
                                rw: Math.max(6, g.size[0] * scaleX),
                                rh: Math.max(6, g.size[1] * scaleY),
                                realX: g.at[0],
                                realY: g.at[1]
                            })
                        }
                    }

                    result.push({
                        wsId: i,
                        isActive: Hyprland.focusedWorkspace?.id === i,
                        windows: windows
                    })
                }
                return result
            }

            property var renderData: []

            function refreshData() {
                renderData = buildRenderData()
            }

            onVisibleChanged: {
                if (visible) refreshData()
            }

            Timer {
                id: postActionRefreshFast
                interval: 40
                onTriggered: overviewWindow.refreshData()
            }

            Timer {
                id: postActionRefresh
                interval: 150
                onTriggered: overviewWindow.refreshData()
            }
            
            Timer {
                id: liveRefresh
                interval: 500
                running: OverviewState.visible
                repeat: true
                onTriggered: overviewWindow.refreshData()
            }

            Timer {
                id: postActionRefreshSafety
                interval: 400
                onTriggered: overviewWindow.refreshData()
            }

            function moveWindowToWorkspace(address, targetWsId) {
                Hyprland.dispatch("movetoworkspacesilent " + targetWsId + ",address:" + address)
                postActionRefreshFast.restart()
                postActionRefresh.restart()
                postActionRefreshSafety.restart()
            }

            function swapWindows(draggedAddress, draggedX, draggedY, targetX, targetY) {
                const dx = targetX - draggedX
                const dy = targetY - draggedY
                let direction
                if (Math.abs(dx) > Math.abs(dy)) {
                    direction = dx > 0 ? "r" : "l"
                } else {
                    direction = dy > 0 ? "d" : "u"
                }
                Hyprland.dispatch("focuswindow address:" + draggedAddress)
                Hyprland.dispatch("swapwindow " + direction)
                postActionRefreshFast.restart()
                postActionRefresh.restart()
                postActionRefreshSafety.restart()
            }

            // Bırakma noktasındaki hedef workspace'i ve varsa üzerine bırakılan pencereyi bul
            function findDropTarget(gx, gy) {
                for (const wsIdStr in overviewWindow.cellRefs) {
                    const wsId = parseInt(wsIdStr)
                    const cellRef = overviewWindow.cellRefs[wsId]
                    if (!cellRef) continue

                    const local = cellRef.mapFromItem(null, gx, gy)
                    if (local.x < 0 || local.x > cellRef.width || local.y < 0 || local.y > cellRef.height) continue

                    // Bu workspace içinde, spesifik bir pencerenin üzerine mi denk geldi?
                    let targetWindow = null
                    const drawRef = overviewWindow.drawAreaRefs[wsId]
                    if (drawRef) {
                        const localDraw = drawRef.mapFromItem(null, gx, gy)
                        const wsData = overviewWindow.renderData.find(w => w.wsId === wsId)
                        if (wsData) {
                            for (const w of wsData.windows) {
                                if (w.address === overviewWindow.dragAddress) continue
                                if (localDraw.x >= w.rx && localDraw.x <= w.rx + w.rw &&
                                    localDraw.y >= w.ry && localDraw.y <= w.ry + w.rh) {
                                    targetWindow = w
                                    break
                                }
                            }
                        }
                    }

                    return { wsId: wsId, window: targetWindow }
                }
                return null
            }

            function finishDrag(gx, gy) {
                const dist = Math.hypot(gx - overviewWindow.pressGlobalX, gy - overviewWindow.pressGlobalY)

                if (dist < 8) {
                    // Basit tıklama — sürükleme yok
                    Hyprland.dispatch("focuswindow address:" + overviewWindow.dragAddress)
                    OverviewState.visible = false
                    overviewWindow.dragActive = false
                    return
                }

                const target = overviewWindow.findDropTarget(gx, gy)
                overviewWindow.dragActive = false

                if (!target) return

                if (target.window && target.wsId === overviewWindow.dragOriginWsId) {
                    overviewWindow.swapWindows(
                        overviewWindow.dragAddress, overviewWindow.dragRealX, overviewWindow.dragRealY,
                        target.window.realX, target.window.realY
                    )
                } else if (target.wsId !== overviewWindow.dragOriginWsId) {
                    overviewWindow.moveWindowToWorkspace(overviewWindow.dragAddress, target.wsId)
                } else {
                    overviewWindow.refreshData()
                }
            }

            Item {
                id: overviewRoot
                anchors.fill: parent
                focus: overviewWindow.visible

                Keys.onEscapePressed: OverviewState.visible = false

                MouseArea {
                    anchors.fill: parent
                    enabled: !overviewWindow.dragActive
                    onClicked: OverviewState.visible = false
                }

                GridLayout {
                    id: gridLayout
                    anchors.centerIn: parent
                    columns: 5
                    rowSpacing: 14
                    columnSpacing: 14

                    Repeater {
                        model: overviewWindow.renderData

                        Rectangle {
                            id: wsCell
                            property int wsId: modelData.wsId
                            property bool isActive: modelData.isActive
                            property var cellWindows: modelData.windows

                            Layout.preferredWidth: 220
                            Layout.preferredHeight: 140
                            radius: 10
                            color: Colors.backgroundAlt
                            border.color: isActive ? Colors.accent : Colors.border
                            border.width: isActive ? 2 : 1
                            clip: true

                            Component.onCompleted: overviewWindow.cellRefs[wsId] = wsCell

                            Image {
                                anchors.fill: parent
                                source: WallpaperService.currentWallpaperPath
                                    ? "file://" + WallpaperService.currentWallpaperPath
                                    : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: source !== ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "#55000000"
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                enabled: !overviewWindow.dragActive
                                onClicked: {
                                    Hyprland.dispatch("workspace " + wsCell.wsId)
                                    OverviewState.visible = false
                                }
                            }

                            Text {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 6
                                text: wsCell.wsId
                                color: wsCell.isActive ? Colors.accent : "#F5F5F5"
                                font.pixelSize: 11
                                font.bold: true
                                z: 5
                            }

                            Item {
                                id: drawArea
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 8
                                width: overviewWindow.drawW
                                height: overviewWindow.drawH

                                Component.onCompleted: overviewWindow.drawAreaRefs[wsCell.wsId] = drawArea

                                Repeater {
                                    model: wsCell.cellWindows

                                    Rectangle {
                                        id: chip
                                        x: modelData.rx
                                        y: modelData.ry
                                        width: modelData.rw
                                        height: modelData.rh
                                        radius: 4
                                        color: modelData.activated ? Colors.accent : Colors.surface0
                                        border.color: modelData.activated ? Colors.accent : Colors.border
                                        border.width: 1
                                        opacity: (overviewWindow.dragActive && overviewWindow.dragAddress === modelData.address) ? 0.25 : 1

                                        Image {
                                            anchors.centerIn: parent
                                            width: Math.min(parent.width - 6, 22)
                                            height: width
                                            source: parent.width > 24 ? overviewWindow.iconFor(modelData.appId) : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: source !== ""
                                        }

                                        MouseArea {
                                            id: chipMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            onPressed: (mouse) => {
                                                const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                overviewWindow.dragActive = true
                                                overviewWindow.dragAddress = modelData.address
                                                overviewWindow.dragOriginWsId = wsCell.wsId
                                                overviewWindow.dragRealX = modelData.realX
                                                overviewWindow.dragRealY = modelData.realY
                                                overviewWindow.dragAppId = modelData.appId
                                                overviewWindow.pressGlobalX = g.x
                                                overviewWindow.pressGlobalY = g.y
                                                overviewWindow.dragGlobalX = g.x
                                                overviewWindow.dragGlobalY = g.y
                                            }

                                            onPositionChanged: (mouse) => {
                                                if (!overviewWindow.dragActive) return
                                                const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                overviewWindow.dragGlobalX = g.x
                                                overviewWindow.dragGlobalY = g.y
                                            }

                                            onReleased: (mouse) => {
                                                const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                overviewWindow.finishDrag(g.x, g.y)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: wsCell.cellWindows.length === 0
                                    text: I18n.t("empty")
                                    color: Colors.foregroundMuted
                                    font.pixelSize: 10
                                    font.italic: true
                                }
                            }
                        }
                    }
                }

                // ---- Sürüklenen pencerenin fareyi takip eden "hayalet" görseli ----
                Rectangle {
                    visible: overviewWindow.dragActive
                    width: 40
                    height: 40
                    radius: 6
                    color: Colors.accent
                    border.color: "#F5F5F5"
                    border.width: 2
                    opacity: 0.85
                    z: 999
                    x: overviewWindow.dragGlobalX - width / 2
                    y: overviewWindow.dragGlobalY - height / 2

                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: overviewWindow.iconFor(overviewWindow.dragAppId)
                        fillMode: Image.PreserveAspectFit
                        visible: source !== ""
                    }
                }
            }
        }
    }
}