// modules/overview/Overview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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
            color: Qt.rgba(0.06, 0.06, 0.09, 0.88)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // ---- Boyutlar (Ayarlar ve GUI Scale ile uyumlu) ----
            readonly property int gap: Math.round(16 * SettingsState.scaleFactor)
            readonly property int wsCount: SettingsState.overviewWorkspaceCount
            readonly property int plannedCols: Math.max(1, Math.min(SettingsState.overviewColumns, wsCount))
            readonly property int cellW: Math.max(140, Math.min(
                Math.round(SettingsState.overviewCellWidth * SettingsState.scaleFactor),
                Math.floor((modelData.width * 0.90 - (plannedCols - 1) * gap) / plannedCols)
            ))
            readonly property int drawW: cellW - Math.round(28 * SettingsState.scaleFactor)
            readonly property int drawH: Math.max(48, Math.round(drawW * modelData.height / modelData.width))
            readonly property int cellH: drawH + Math.round(48 * SettingsState.scaleFactor)
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
            property int dropTargetWsId: -1

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

            readonly property int totalWindows: {
                let count = 0
                for (let i = 0; i < renderData.length; i++) {
                    count += (renderData[i].windows || []).length
                }
                return count
            }

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

            // ---- Sürükle-bırak ----
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
                overviewWindow.dropTargetWsId = -1

                if (dist < 8) {
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

            // ---- Açılış / Kapanış ----
            onVisibleChanged: {
                menuOpen = false
                dragActive = false
                dropTargetWsId = -1
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
                duration: 220
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

            // ---- Menü Satırı ----
            component MenuRow: Rectangle {
                id: mrow
                property string label: ""
                property color labelColor: "#F5F5F5"
                signal triggered()

                width: parent ? parent.width : 0
                height: Math.round(30 * SettingsState.scaleFactor)
                radius: Math.round(8 * SettingsState.scaleFactor)
                color: mrowArea.containsMouse ? Colors.hover : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(10 * SettingsState.scaleFactor)
                    anchors.verticalCenter: parent.verticalCenter
                    text: mrow.label
                    color: mrow.labelColor
                    font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: mrowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mrow.triggered()
                }
            }

            // ---- Arayüz Kökü ----
            Item {
                id: overviewRoot
                anchors.fill: parent
                focus: overviewWindow.visible

                Keys.onPressed: (event) => overviewWindow.handleKey(event)

                // Dış tıkla kapatma
                MouseArea {
                    anchors.fill: parent
                    enabled: !overviewWindow.dragActive
                    onClicked: OverviewState.visible = false
                }

                // ==================== ÜST BAŞLIK BARI ====================
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: Math.round(28 * SettingsState.scaleFactor)
                    height: Math.round(40 * SettingsState.scaleFactor)
                    width: topRow.implicitWidth + Math.round(32 * SettingsState.scaleFactor)
                    radius: Math.round(20 * SettingsState.scaleFactor)
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.90)
                    border.color: Colors.border
                    border.width: 1
                    z: 100
                    opacity: overviewWindow.openAmount
                    scale: 0.95 + 0.05 * overviewWindow.openAmount

                    RowLayout {
                        id: topRow
                        anchors.centerIn: parent
                        spacing: Math.round(14 * SettingsState.scaleFactor)

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰍹"
                                color: Colors.accent
                                font.pixelSize: Math.round(15 * SettingsState.scaleFactor)
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                text: I18n.t("tabOverview")
                                color: "#F5F5F5"
                                font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: Math.round(22 * SettingsState.scaleFactor)
                            Layout.preferredWidth: totalWinText.implicitWidth + Math.round(14 * SettingsState.scaleFactor)
                            radius: Math.round(11 * SettingsState.scaleFactor)
                            color: Colors.surface0

                            Text {
                                id: totalWinText
                                anchors.centerIn: parent
                                text: overviewWindow.totalWindows + " " + I18n.t("windowsUnit")
                                color: Colors.foregroundMuted
                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(22 * SettingsState.scaleFactor)
                            Layout.preferredHeight: Math.round(22 * SettingsState.scaleFactor)
                            radius: width / 2
                            color: topCloseHover.containsMouse ? Colors.danger : Colors.surface0
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: topCloseHover.containsMouse ? "#F5F5F5" : Colors.foregroundMuted
                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                            }

                            MouseArea {
                                id: topCloseHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: OverviewState.visible = false
                            }
                        }
                    }
                }

                // ==================== MERKEZ ÇALIŞMA ALANLARI IZGARASI ====================
                Item {
                    id: gridBox
                    anchors.centerIn: parent
                    width: grid.width
                    height: grid.height
                    opacity: overviewWindow.openAmount
                    scale: 0.94 + 0.06 * overviewWindow.openAmount

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
                                readonly property bool isDropTarget: overviewWindow.dragActive && overviewWindow.dropTargetWsId === wsId

                                width: overviewWindow.cellW
                                height: overviewWindow.cellH
                                radius: Math.round(20 * SettingsState.scaleFactor)
                                color: "transparent"
                                border.color: isDropTarget
                                    ? "#a6e3a1"
                                    : (isActive ? Colors.accent : (isSelected ? "#F5F5F5" : Colors.border))
                                border.width: (isDropTarget || isActive || isSelected) ? 2 : 1

                                scale: isDropTarget ? 1.03 : (isSelected ? 1.025 : (cellMouse.containsMouse ? 1.012 : 1.0))
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                Component.onCompleted: overviewWindow.cellRefs[wsId] = wsCell
                                Component.onDestruction: {
                                    if (overviewWindow.cellRefs[wsId] === wsCell) delete overviewWindow.cellRefs[wsId]
                                }

                                // ── Mask şekli: rounded rect (görünmez) ──────────────────
                                Rectangle {
                                    id: wsCellMask
                                    anchors.fill: parent
                                    radius: wsCell.radius
                                    color: "white"
                                    visible: false
                                    layer.enabled: true
                                }

                                // ── İçerik katmanı: mask ile kırpılır ───────────────────
                                Item {
                                    id: wsCellContent
                                    anchors.fill: parent
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: wsCellMask
                                    }

                                    // Arka plan rengi
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Colors.backgroundAlt
                                    }

                                    // Duvarkağıdı
                                    Image {
                                        anchors.fill: parent
                                        source: WallpaperService.currentWallpaperPath
                                            ? "file://" + WallpaperService.currentWallpaperPath
                                            : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 480
                                        asynchronous: true
                                        opacity: 0.28
                                        visible: source !== ""
                                    }

                                    // Koyu overlay
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.76)
                                    }

                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        z: -1
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !overviewWindow.dragActive
                                        onEntered: overviewWindow.selectedWsId = wsCell.wsId
                                        onClicked: overviewWindow.activateWorkspace(wsCell.wsId)
                                    }

                                } // wsCellContent

                                // Kart Üst Başlık Şeridi
                                RowLayout {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: Math.round(8 * SettingsState.scaleFactor)
                                    z: 10

                                    Rectangle {
                                        Layout.preferredHeight: Math.round(22 * SettingsState.scaleFactor)
                                        Layout.preferredWidth: wsBadgeRow.implicitWidth + Math.round(12 * SettingsState.scaleFactor)
                                        radius: Math.round(12 * SettingsState.scaleFactor)
                                        color: wsCell.isActive ? Colors.accent : (wsCell.isSelected ? "#ffffff" : Colors.surface0)

                                        RowLayout {
                                            id: wsBadgeRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: "󰍹"
                                                color: wsCell.isActive ? Colors.accentText : (wsCell.isSelected ? "#11111b" : Colors.foregroundMuted)
                                                font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                                font.family: "JetBrainsMono Nerd Font"
                                            }
                                            Text {
                                                text: wsCell.wsId
                                                color: wsCell.isActive ? Colors.accentText : (wsCell.isSelected ? "#11111b" : "#F5F5F5")
                                                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: wsCell.cellWindows.length > 0
                                            ? wsCell.cellWindows.length + " " + I18n.t("windowsUnit")
                                            : I18n.t("empty")
                                        color: wsCell.isActive ? Colors.accent : Colors.foregroundMuted
                                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                        font.bold: wsCell.isActive
                                    }
                                }

                                // Pencere Çizim Alanı
                                Item {
                                    id: drawArea
                                    x: Math.round((parent.width - width) / 2)
                                    y: Math.round(36 * SettingsState.scaleFactor)
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
                                            radius: Math.round(12 * SettingsState.scaleFactor)
                                            color: modelData.activated ? Colors.accent : Colors.surface0
                                            clip: true
                                            opacity: (overviewWindow.dragActive && overviewWindow.dragAddress === modelData.address) ? 0.25 : 1

                                            // Canlı Önizleme
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

                                            // Önizleme yoksa veya küçükse uygulama ikonu
                                            Image {
                                                anchors.centerIn: parent
                                                width: Math.min(parent.width - 6, Math.round(28 * SettingsState.scaleFactor))
                                                height: width
                                                source: (!preview.visible && parent.width > 22 && parent.height > 22)
                                                    ? overviewWindow.iconFor(modelData.appId) : ""
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                visible: source !== ""
                                            }

                                            // Alt minyatür başlık şeridi (Mission Control stili)
                                            Rectangle {
                                                visible: chip.height >= Math.round(34 * SettingsState.scaleFactor) && chip.width >= Math.round(48 * SettingsState.scaleFactor)
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                height: Math.round(18 * SettingsState.scaleFactor)
                                                color: Qt.rgba(0, 0, 0, 0.72)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 4
                                                    anchors.rightMargin: 4
                                                    spacing: 4

                                                    Image {
                                                        Layout.preferredWidth: Math.round(12 * SettingsState.scaleFactor)
                                                        Layout.preferredHeight: Math.round(12 * SettingsState.scaleFactor)
                                                        source: overviewWindow.iconFor(modelData.appId)
                                                        fillMode: Image.PreserveAspectFit
                                                        visible: source !== ""
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.wl?.title || modelData.appId || ""
                                                        color: "#F5F5F5"
                                                        font.pixelSize: Math.round(9 * SettingsState.scaleFactor)
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }

                                            // Çerçeve (aktif pencere vurgulu)
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: chip.radius
                                                color: "transparent"
                                                border.width: modelData.activated ? 2 : 1
                                                border.color: modelData.activated ? Colors.accent : Qt.rgba(1, 1, 1, 0.22)
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
                                                    overviewWindow.dropTargetWsId = wsCell.wsId
                                                }

                                                onPositionChanged: (mouse) => {
                                                    if (!overviewWindow.dragActive) return
                                                    const g = chipMouse.mapToItem(null, mouse.x, mouse.y)
                                                    overviewWindow.dragGlobalX = g.x
                                                    overviewWindow.dragGlobalY = g.y
                                                    const target = overviewWindow.findDropTarget(g.x, g.y)
                                                    overviewWindow.dropTargetWsId = target ? target.wsId : -1
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

                                            // Kapatma düğmesi (hover durumunda belirir)
                                            Rectangle {
                                                visible: (chipMouse.containsMouse || closeArea.containsMouse)
                                                         && !overviewWindow.dragActive
                                                         && chip.width > 40 && chip.height > 28
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: Math.round(3 * SettingsState.scaleFactor)
                                                width: Math.round(18 * SettingsState.scaleFactor)
                                                height: Math.round(18 * SettingsState.scaleFactor)
                                                radius: width / 2
                                                color: closeArea.containsMouse ? Colors.danger : Qt.rgba(0, 0, 0, 0.75)
                                                border.color: closeArea.containsMouse ? Colors.danger : Qt.rgba(1, 1, 1, 0.2)
                                                border.width: 1
                                                z: 5

                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    color: "#F5F5F5"
                                                    font.pixelSize: Math.round(9 * SettingsState.scaleFactor)
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
                                        font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                                        font.italic: true
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== ALT BİLGİ & KISAYOL ŞERİDİ ====================
                Rectangle {
                    visible: SettingsState.overviewShowCaption
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: Math.round(24 * SettingsState.scaleFactor)
                    height: Math.round(36 * SettingsState.scaleFactor)
                    width: Math.min(parent.width - 40, bottomRow.implicitWidth + Math.round(32 * SettingsState.scaleFactor))
                    radius: Math.round(18 * SettingsState.scaleFactor)
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.90)
                    border.color: Colors.border
                    border.width: 1
                    z: 100
                    opacity: overviewWindow.openAmount

                    RowLayout {
                        id: bottomRow
                        anchors.centerIn: parent
                        spacing: Math.round(16 * SettingsState.scaleFactor)

                        RowLayout {
                            spacing: 6
                            Text {
                                text: overviewWindow.hoverWindowText !== "" ? "󰖲" : "󰍹"
                                color: Colors.accent
                                font.pixelSize: Math.round(13 * SettingsState.scaleFactor)
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                text: overviewWindow.captionText
                                color: "#F5F5F5"
                                font.pixelSize: Math.round(12 * SettingsState.scaleFactor)
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.maximumWidth: Math.round(340 * SettingsState.scaleFactor)
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Math.round(16 * SettingsState.scaleFactor)
                            color: Colors.border
                        }

                        Text {
                            text: I18n.t("overviewShortcutsHint")
                            color: Colors.foregroundMuted
                            font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                // Menü açıkken dışarı basınca kapatma
                MouseArea {
                    anchors.fill: parent
                    z: 900
                    visible: overviewWindow.menuOpen
                    onPressed: overviewWindow.closeMenu()
                }

                // ==================== SAĞ TIK MENÜSÜ ====================
                Rectangle {
                    id: ctxMenu
                    visible: overviewWindow.menuOpen
                    z: 1000
                    width: Math.round(220 * SettingsState.scaleFactor)
                    height: menuCol.height + Math.round(16 * SettingsState.scaleFactor)
                    x: Math.max(8, Math.min(overviewWindow.menuX, overviewRoot.width - width - 8))
                    y: Math.max(8, Math.min(overviewWindow.menuY, overviewRoot.height - height - 8))
                    radius: Math.round(16 * SettingsState.scaleFactor)
                    color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.96)
                    border.color: Colors.accent
                    border.width: 1

                    Column {
                        id: menuCol
                        x: Math.round(8 * SettingsState.scaleFactor)
                        y: Math.round(8 * SettingsState.scaleFactor)
                        width: parent.width - Math.round(16 * SettingsState.scaleFactor)
                        spacing: Math.round(4 * SettingsState.scaleFactor)

                        MenuRow {
                            label: "󰖲  " + I18n.t("menuToggleFloat")
                            onTriggered: {
                                overviewWindow.toggleFloating(overviewWindow.menuAddress)
                                overviewWindow.closeMenu()
                            }
                        }

                        MenuRow {
                            label: "󰅖  " + I18n.t("menuClose")
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
                            font.pixelSize: Math.round(10 * SettingsState.scaleFactor)
                            leftPadding: Math.round(10 * SettingsState.scaleFactor)
                            topPadding: Math.round(4 * SettingsState.scaleFactor)
                        }

                        Flow {
                            width: parent.width
                            spacing: Math.round(4 * SettingsState.scaleFactor)

                            Repeater {
                                model: overviewWindow.wsCount

                                Rectangle {
                                    id: numBtn
                                    readonly property int n: index + 1
                                    readonly property bool isCurrent: n === overviewWindow.menuWsId

                                    width: Math.round(28 * SettingsState.scaleFactor)
                                    height: Math.round(28 * SettingsState.scaleFactor)
                                    radius: Math.round(8 * SettingsState.scaleFactor)
                                    color: isCurrent ? Colors.surface0 : (numArea.containsMouse ? Colors.accent : Colors.hover)
                                    opacity: isCurrent ? 0.4 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: numBtn.n
                                        color: numArea.containsMouse && !numBtn.isCurrent ? Colors.accentText : "#F5F5F5"
                                        font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
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

                // ==================== SÜRÜKLEME HAYALETİ ====================
                Rectangle {
                    visible: overviewWindow.dragActive
                    width: Math.round(54 * SettingsState.scaleFactor)
                    height: Math.round(42 * SettingsState.scaleFactor)
                    radius: Math.round(12 * SettingsState.scaleFactor)
                    color: Colors.accent
                    border.color: "#FFFFFF"
                    border.width: 2
                    opacity: 0.92
                    z: 999
                    x: overviewWindow.dragGlobalX - width / 2
                    y: overviewWindow.dragGlobalY - height / 2

                    Image {
                        anchors.centerIn: parent
                        width: Math.round(24 * SettingsState.scaleFactor)
                        height: width
                        source: overviewWindow.iconFor(overviewWindow.dragAppId)
                        fillMode: Image.PreserveAspectFit
                        visible: source !== ""
                    }
                }
            }
        }
    }
}
