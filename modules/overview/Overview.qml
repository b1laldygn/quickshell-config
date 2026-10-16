// modules/overview/Overview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
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

            // ---- Boyutlar (Ayarlar'dan) ----
            readonly property int gap: 14
            readonly property int wsCount: SettingsState.overviewWorkspaceCount
            readonly property int plannedCols: Math.max(1, Math.min(SettingsState.overviewColumns, wsCount))
            readonly property int cellW: Math.max(120, Math.min(SettingsState.overviewCellWidth,
                Math.floor((modelData.width * 0.92 - (plannedCols - 1) * gap) / plannedCols)))
            readonly property int drawW: cellW - 30
            readonly property int drawH: Math.max(40, Math.round(drawW * modelData.height / modelData.width))
            readonly property int cellH: drawH + 40
            readonly property int effCols: Math.max(1, Math.min(SettingsState.overviewColumns, renderData.length))

            // ---- Durum ----
            property var renderData: []
            property string lastSig: ""
            property int previewTick: 0
            property real openAmount: 0
            property int selectedWsId: 1
            property string hoverWindowText: ""

            // sürükleme
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

            // sağ tık menüsü
            property bool menuOpen: false
            property string menuAddress: ""
            property int menuWsId: -1
            property real menuX: 0
            property real menuY: 0

            property var cellRefs: ({})
            property var drawAreaRefs: ({})

            property var iconOverrides: ({
                "code": "vscode",
                "com.anthropic.Claude": "claude-desktop",
                "YouTube Music Desktop App": "youtube-music-desktop-app"
            })

            readonly property string wsCaption: {
                const e = renderData.find(x => x.wsId === selectedWsId)
                if (!e) return ""
                return I18n.t("workspaceWord") + " " + e.wsId + " · " + e.windows.length + " " + I18n.t("windowsUnit")
            }
            readonly property string captionText: hoverWindowText !== "" ? hoverWindowText : wsCaption

            // ---- Yardımcılar ----
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

            function windowLabel(w) {
                const id = w.wl ? (w.wl.appId || "") : (w.appId || "")
                const title = w.wl ? (w.wl.title || "") : ""
                if (title !== "" && id !== "") return id + " · " + title
                return title !== "" ? title : id
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

            // Veriyi ve bir "imza" üretir. İmza değişmedikçe kutular yeniden kurulmaz,
            // böylece canlı önizlemeler titremez.
            function buildRenderData() {
                Hyprland.refreshMonitors()
                Hyprland.refreshWorkspaces()
                Hyprland.refreshToplevels()

                const focusedId = Hyprland.focusedWorkspace?.id
                const data = []
                const sigParts = [drawW + "x" + drawH]

                for (let i = 1; i <= wsCount; i++) {
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

                            const w = {
                                address: g.address || "",
                                appId: t.wayland?.appId || "",
                                hypr: t,
                                wl: t.wayland || null,
                                activated: !!t.activated,
                                rx: Math.round((g.at[0] - monGeom.x) * scaleX),
                                ry: Math.round((g.at[1] - monGeom.y) * scaleY),
                                rw: Math.max(6, Math.round(g.size[0] * scaleX)),
                                rh: Math.max(6, Math.round(g.size[1] * scaleY)),
                                realX: g.at[0],
                                realY: g.at[1]
                            }
                            windows.push(w)
                        }
                    }

                    if (SettingsState.overviewHideEmpty && windows.length === 0 && i !== focusedId) continue

                    data.push({ wsId: i, windows: windows })
                    sigParts.push(i + ":" + windows.map(w =>
                        w.address + "," + w.rx + "," + w.ry + "," + w.rw + "," + w.rh
                        + "," + (w.wl ? 1 : 0) + "," + (w.activated ? 1 : 0)).join(";"))
                }

                if (data.length === 0) {
                    data.push({ wsId: 1, windows: [] })
                    sigParts.push("1:")
                }

                return { data: data, sig: sigParts.join("|") }
            }

            function refreshData(force) {
                if (dragActive && force !== true) return
                const built = buildRenderData()
                if (force === true || built.sig !== lastSig) {
                    lastSig = built.sig
                    renderData = built.data
                }
            }

            function scheduleRefresh() {
                postActionRefreshFast.restart()
                postActionRefresh.restart()
                postActionRefreshSafety.restart()
            }

            // ---- Eylemler ----
            function activateWorkspace(id) {
                Hyprland.dispatch("workspace " + id)
                OverviewState.visible = false
            }

            function moveWindowToWorkspace(address, targetWsId) {
                Hyprland.dispatch("movetoworkspacesilent " + targetWsId + ",address:" + address)
                scheduleRefresh()
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
                scheduleRefresh()
            }

            function closeWindow(address) {
                Hyprland.dispatch("closewindow address:" + address)
                scheduleRefresh()
            }

            function toggleFloating(address) {
                Hyprland.dispatch("togglefloating address:" + address)
                scheduleRefresh()
            }

            function openMenu(address, wsId, gx, gy) {
                menuAddress = address
                menuWsId = wsId
                menuX = gx
                menuY = gy
                menuOpen = true
            }

            function closeMenu() { menuOpen = false }

            // ---- Klavye ----
            function moveSelection(dx, dy) {
                const list = renderData
                if (list.length === 0) return
                let idx = list.findIndex(e => e.wsId === selectedWsId)
                if (idx < 0) idx = 0
                const cols = effCols
                const rows = Math.ceil(list.length / cols)
                let row = Math.floor(idx / cols)
                let col = idx % cols
                col = Math.max(0, Math.min(cols - 1, col + dx))
                row = Math.max(0, Math.min(rows - 1, row + dy))
                let ni = row * cols + col
                if (ni >= list.length) ni = list.length - 1
                selectedWsId = list[ni].wsId
            }

            function handleKey(event) {
                let handled = true
                if (event.key === Qt.Key_Escape) {
                    if (menuOpen) closeMenu()
                    else OverviewState.visible = false
                } else if (event.key === Qt.Key_Left) {
                    moveSelection(-1, 0)
                } else if (event.key === Qt.Key_Right) {
                    moveSelection(1, 0)
                } else if (event.key === Qt.Key_Up) {
                    moveSelection(0, -1)
                } else if (event.key === Qt.Key_Down) {
                    moveSelection(0, 1)
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    activateWorkspace(selectedWsId)
                } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                    const n = event.key === Qt.Key_0 ? 10 : event.key - Qt.Key_0
                    if (n <= wsCount) activateWorkspace(n)
                } else {
                    handled = false
                }
                event.accepted = handled
            }

            // ---- Sürükle-bırak (elle fare takibi) ----
            function findDropTarget(gx, gy) {
                for (const wsIdStr in overviewWindow.cellRefs) {
                    const wsId = parseInt(wsIdStr)
                    const cellRef = overviewWindow.cellRefs[wsId]
                    if (!cellRef) continue

                    const local = cellRef.mapFromItem(null, gx, gy)
                    if (local.x < 0 || local.x > cellRef.width || local.y < 0 || local.y > cellRef.height) continue

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
                const dist = Math.hypot(gx - pressGlobalX, gy - pressGlobalY)

                if (dist < 8) {
                    // Sürükleme değil, tıklama: pencereye odaklan
                    Hyprland.dispatch("focuswindow address:" + dragAddress)
                    OverviewState.visible = false
                    dragActive = false
                    return
                }

                const target = findDropTarget(gx, gy)
                dragActive = false

                if (!target) return

                if (target.window && target.wsId === dragOriginWsId) {
                    swapWindows(dragAddress, dragRealX, dragRealY, target.window.realX, target.window.realY)
                } else if (target.wsId !== dragOriginWsId) {
                    moveWindowToWorkspace(dragAddress, target.wsId)
                } else {
                    refreshData(true)
                }
            }

            // ---- Açılış / kapanış ----
            onVisibleChanged: {
                menuOpen = false
                dragActive = false
                hoverWindowText = ""
                if (visible) {
                    selectedWsId = Hyprland.focusedWorkspace?.id ?? 1
                    refreshData(true)
                    openAmount = 0
                    openAnim.restart()
                }
            }

            NumberAnimation {
                id: openAnim
                target: overviewWindow
                property: "openAmount"
                from: 0
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }

            // ---- Zamanlayıcılar ----
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
                id: postActionRefreshSafety
                interval: 400
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
                id: previewTimer
                interval: 1000
                running: OverviewState.visible && SettingsState.overviewLivePreview
                repeat: true
                onTriggered: overviewWindow.previewTick++
            }

            // ---- Menü satırı bileşeni ----
            component MenuRow: Rectangle {
                id: mrow
                property string label: ""
                property color labelColor: "#F5F5F5"
                signal triggered()

                width: parent ? parent.width : 0
                height: 28
                radius: 6
                color: mrowArea.containsMouse ? Colors.hover : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: mrow.label
                    color: mrow.labelColor
                    font.pixelSize: 12
                }

                MouseArea {
                    id: mrowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mrow.triggered()
                }
            }

            // ---- Ekran ----
            Item {
                id: overviewRoot
                anchors.fill: parent
                focus: overviewWindow.visible

                Keys.onPressed: (event) => overviewWindow.handleKey(event)

                MouseArea {
                    anchors.fill: parent
                    enabled: !overviewWindow.dragActive
                    onClicked: OverviewState.visible = false
                }

                Item {
                    id: gridBox
                    anchors.centerIn: parent
                    width: grid.width
                    height: grid.height + (SettingsState.overviewShowCaption ? 36 : 0)
                    opacity: overviewWindow.openAmount
                    scale: 0.96 + 0.04 * overviewWindow.openAmount

                    Grid {
                        id: grid
                        columns: overviewWindow.effCols
                        spacing: overviewWindow.gap

                        Repeater {
                            model: overviewWindow.renderData

                            Rectangle {
                                id: wsCell
                                property int wsId: modelData.wsId
                                property var cellWindows: modelData.windows
                                readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                                readonly property bool isSelected: overviewWindow.selectedWsId === wsId

                                width: overviewWindow.cellW
                                height: overviewWindow.cellH
                                radius: 10
                                color: Colors.backgroundAlt
                                border.color: isSelected ? "#F5F5F5" : (isActive ? Colors.accent : Colors.border)
                                border.width: (isSelected || isActive) ? 2 : 1
                                clip: true

                                Component.onCompleted: overviewWindow.cellRefs[wsId] = wsCell
                                Component.onDestruction: {
                                    if (overviewWindow.cellRefs[wsId] === wsCell) delete overviewWindow.cellRefs[wsId]
                                }

                                Image {
                                    anchors.fill: parent
                                    source: WallpaperService.currentWallpaperPath
                                        ? "file://" + WallpaperService.currentWallpaperPath
                                        : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 480
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
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !overviewWindow.dragActive
                                    onEntered: overviewWindow.selectedWsId = wsCell.wsId
                                    onClicked: overviewWindow.activateWorkspace(wsCell.wsId)
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
                                    x: Math.round((parent.width - width) / 2)
                                    y: 28
                                    width: overviewWindow.drawW
                                    height: overviewWindow.drawH

                                    Component.onCompleted: overviewWindow.drawAreaRefs[wsCell.wsId] = drawArea
                                    Component.onDestruction: {
                                        if (overviewWindow.drawAreaRefs[wsCell.wsId] === drawArea)
                                            delete overviewWindow.drawAreaRefs[wsCell.wsId]
                                    }

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
                                            clip: true
                                            opacity: (overviewWindow.dragActive && overviewWindow.dragAddress === modelData.address) ? 0.25 : 1

                                            // Canlı önizleme (saniyede bir kare yakalanır)
                                            ScreencopyView {
                                                id: preview
                                                anchors.fill: parent
                                                visible: SettingsState.overviewLivePreview && hasContent
                                                captureSource: SettingsState.overviewLivePreview ? modelData.wl : null
                                                live: false

                                                function grab() {
                                                    if (captureSource) captureFrame()
                                                }

                                                Component.onCompleted: grab()
                                                onCaptureSourceChanged: grab()

                                                Connections {
                                                    target: overviewWindow
                                                    function onPreviewTickChanged() { preview.grab() }
                                                }
                                            }

                                            // Önizleme yoksa uygulama ikonu
                                            Image {
                                                anchors.centerIn: parent
                                                width: Math.min(parent.width - 6, 28)
                                                height: width
                                                source: (!preview.visible && parent.width > 24 && parent.height > 24)
                                                    ? overviewWindow.iconFor(modelData.appId) : ""
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                visible: source !== ""
                                            }

                                            // Çerçeve (aktif pencere vurgulu)
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: chip.radius
                                                color: "transparent"
                                                border.width: modelData.activated ? 2 : 1
                                                border.color: modelData.activated ? Colors.accent : "#66ffffff"
                                            }

                                            MouseArea {
                                                id: chipMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                                                onEntered: overviewWindow.hoverWindowText = overviewWindow.windowLabel(modelData)
                                                onExited: overviewWindow.hoverWindowText = ""

                                                onPressed: (mouse) => {
                                                    if (mouse.button !== Qt.LeftButton) return
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
                                                    if (mouse.button !== Qt.LeftButton) return
                                                    const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                    overviewWindow.finishDrag(g.x, g.y)
                                                }

                                                onClicked: (mouse) => {
                                                    if (mouse.button === Qt.RightButton) {
                                                        const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                        overviewWindow.openMenu(modelData.address, wsCell.wsId, g.x, g.y)
                                                    } else if (mouse.button === Qt.MiddleButton) {
                                                        overviewWindow.closeWindow(modelData.address)
                                                    }
                                                }
                                            }

                                            // Kapatma düğmesi (üzerine gelince görünür)
                                            Rectangle {
                                                visible: (chipMouse.containsMouse || closeArea.containsMouse)
                                                         && !overviewWindow.dragActive
                                                         && chip.width > 44 && chip.height > 30
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 3
                                                width: 18
                                                height: 18
                                                radius: 9
                                                color: closeArea.containsMouse ? Colors.danger : "#cc000000"
                                                z: 5

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    color: "#F5F5F5"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: closeArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: overviewWindow.closeWindow(modelData.address)
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

                    // Alt satır: pencere başlığı ya da çalışma alanı bilgisi
                    Text {
                        visible: SettingsState.overviewShowCaption && overviewWindow.captionText !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: Math.min(implicitWidth, parent.width)
                        text: overviewWindow.captionText
                        color: "#F5F5F5"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Menü açıkken dışarı basınca menüyü kapatır
                MouseArea {
                    anchors.fill: parent
                    z: 900
                    visible: overviewWindow.menuOpen
                    onPressed: overviewWindow.closeMenu()
                }

                // Sağ tık menüsü
                Rectangle {
                    id: ctxMenu
                    visible: overviewWindow.menuOpen
                    z: 1000
                    width: 210
                    height: menuCol.height + 16
                    x: Math.max(8, Math.min(overviewWindow.menuX, overviewRoot.width - width - 8))
                    y: Math.max(8, Math.min(overviewWindow.menuY, overviewRoot.height - height - 8))
                    radius: 10
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    Column {
                        id: menuCol
                        x: 8
                        y: 8
                        width: parent.width - 16
                        spacing: 2

                        MenuRow {
                            label: I18n.t("menuToggleFloat")
                            onTriggered: {
                                overviewWindow.toggleFloating(overviewWindow.menuAddress)
                                overviewWindow.closeMenu()
                            }
                        }

                        MenuRow {
                            label: I18n.t("menuClose")
                            labelColor: Colors.danger
                            onTriggered: {
                                overviewWindow.closeWindow(overviewWindow.menuAddress)
                                overviewWindow.closeMenu()
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Colors.border
                        }

                        Text {
                            text: I18n.t("menuMoveTo")
                            color: Colors.foregroundMuted
                            font.pixelSize: 10
                            leftPadding: 10
                            topPadding: 4
                        }

                        Flow {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: overviewWindow.wsCount

                                Rectangle {
                                    id: numBtn
                                    readonly property int n: index + 1
                                    readonly property bool isCurrent: n === overviewWindow.menuWsId

                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: isCurrent ? Colors.surface0 : (numArea.containsMouse ? Colors.accent : Colors.hover)
                                    opacity: isCurrent ? 0.4 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: numBtn.n
                                        color: numArea.containsMouse && !numBtn.isCurrent ? Colors.accentText : "#F5F5F5"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: numArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !numBtn.isCurrent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            overviewWindow.moveWindowToWorkspace(overviewWindow.menuAddress, numBtn.n)
                                            overviewWindow.closeMenu()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Sürüklenen pencerenin fareyi takip eden "hayalet" görseli
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