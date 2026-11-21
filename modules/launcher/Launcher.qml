// modules/launcher/Launcher.qml
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

            // ---- HARİCİ İŞLEMLER (Kopyalama, URL açma, Komut çalıştırma) ----
            Process { id: copyProc; command: [] }
            function copyText(str) {
                copyProc.command = ["wl-copy", String(str)]
                copyProc.running = true
            }

            Process { id: openProc; command: [] }
            function openUrl(url) {
                openProc.command = ["xdg-open", url]
                openProc.running = true
            }

            Process { id: runProc; command: [] }
            function runCmd(cmd) {
                runProc.command = ["sh", "-c", cmd]
                runProc.running = true
            }

            // ---- GÜVENLİ MATEMATİKSEL İFADE HESAPLAYICI ----
            function evaluateMath(raw) {
                if (!raw || raw.length < 2) return null
                let s = raw.trim()
                if (s.startsWith("=")) s = s.substring(1).trim()
                if (!s) return null

                s = s.replace(/\^/g, "**")
                     .replace(/×/g, "*")
                     .replace(/÷/g, "/")
                     .replace(/%/g, "*0.01")
                     .replace(/\bpi\b/gi, "Math.PI")
                     .replace(/\be\b/gi, "Math.E")
                     .replace(/\bsqrt\(/gi, "Math.sqrt(")
                     .replace(/\babs\(/gi, "Math.abs(")
                     .replace(/\bround\(/gi, "Math.round(")
                     .replace(/\bsin\(/gi, "Math.sin(")
                     .replace(/\bcos\(/gi, "Math.cos(")
                     .replace(/\btan\(/gi, "Math.tan(")

                const safePattern = /^([0-9\s\+\-\*\/\%\(\)\.]|Math\.(PI|E|sqrt|abs|round|sin|cos|tan))+$/
                if (!safePattern.test(s)) return null
                if (!/\d/.test(s)) return null
                if (!/[\+\-\*\/\%]|Math\./.test(s)) return null

                try {
                    const fn = new Function("return (" + s + ")")
                    const res = fn()
                    if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                        return Math.round(res * 100000000) / 100000000
                    }
                } catch (e) {
                    return null
                }
                return null
            }

            // ---- AKILLI FUZZY VE KISALTMA EŞLEŞTİRİCİ ----
            function fuzzyScore(name, generic, keywords, query) {
                name = (name || "").toLowerCase()
                generic = (generic || "").toLowerCase()
                keywords = (keywords || []).join(" ").toLowerCase()
                query = query.toLowerCase()

                if (name === query) return 150
                if (name.startsWith(query)) return 100 - (name.length - query.length)
                if (name.includes(query)) return 75 - (name.indexOf(query) * 2)

                // Baş harf / Kısaltma eşleşmesi (örn: "vsc" -> "Visual Studio Code")
                const words = name.split(/[\s\-_\.]+/)
                const initials = words.map(w => w ? w[0] : "").join("")
                if (initials.includes(query)) return 65

                // Sıralı harf (Subsequence) eşleşmesi (örn: "ffox" -> "firefox")
                let nIdx = 0, qIdx = 0, seq = 0, score = 0
                while (nIdx < name.length && qIdx < query.length) {
                    if (name[nIdx] === query[qIdx]) {
                        qIdx++
                        seq++
                        score += 4 + seq * 2
                    } else {
                        seq = 0
                    }
                    nIdx++
                }
                if (qIdx === query.length) {
                    return Math.max(20, score)
                }

                if (generic.includes(query)) return 30
                if (keywords.includes(query)) return 20

                return 0
            }

            // ---- BİRLEŞTİRİLMİŞ ÖĞE LİSTESİ ----
            readonly property var items: {
                const raw = searchText.trim()
                const query = raw.toLowerCase()
                const list = []

                // 1. Matematiksel Hesaplama
                const mathResult = evaluateMath(raw)
                if (mathResult !== null) {
                    list.push({
                        id: "calc",
                        type: "calc",
                        name: "= " + mathResult,
                        subtitle: I18n.t("calcResultSubtitle"),
                        icon: "󰪚",
                        isGlyph: true,
                        execute: () => {
                            copyText(mathResult)
                        }
                    })
                }

                // 2. Terminal Komutu Modu (">" veya "$" ile başlarsa)
                if (raw.startsWith(">") || raw.startsWith("$")) {
                    const cmd = raw.substring(1).trim()
                    if (cmd.length > 0) {
                        list.push({
                            id: "cmd",
                            type: "cmd",
                            name: cmd,
                            subtitle: I18n.t("runCommandSubtitle"),
                            icon: "󰞷",
                            isGlyph: true,
                            execute: () => {
                                runCmd(cmd)
                            }
                        })
                    }
                }

                // 3. Web Bangs & URL Arama
                let isWebBang = false
                let webUrl = ""
                let webTitle = ""
                let webProvider = ""

                if (raw.startsWith("!g ")) {
                    isWebBang = true
                    webProvider = "Google"
                    const q = raw.substring(3).trim()
                    webUrl = "https://www.google.com/search?q=" + encodeURIComponent(q)
                    webTitle = q
                } else if (raw.startsWith("!yt ")) {
                    isWebBang = true
                    webProvider = "YouTube"
                    const q = raw.substring(4).trim()
                    webUrl = "https://www.youtube.com/results?search_query=" + encodeURIComponent(q)
                    webTitle = q
                } else if (raw.startsWith("!gh ")) {
                    isWebBang = true
                    webProvider = "GitHub"
                    const q = raw.substring(4).trim()
                    webUrl = "https://github.com/search?q=" + encodeURIComponent(q)
                    webTitle = q
                } else if (raw.startsWith("!w ")) {
                    isWebBang = true
                    webProvider = "Wikipedia"
                    const q = raw.substring(3).trim()
                    webUrl = "https://en.wikipedia.org/wiki/Special:Search?search=" + encodeURIComponent(q)
                    webTitle = q
                } else if (raw.startsWith("!ddg ")) {
                    isWebBang = true
                    webProvider = "DuckDuckGo"
                    const q = raw.substring(5).trim()
                    webUrl = "https://duckduckgo.com/?q=" + encodeURIComponent(q)
                    webTitle = q
                } else if (/^https?:\/\//i.test(raw) || /^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/.*)?$/.test(raw)) {
                    isWebBang = true
                    webProvider = "Web"
                    webUrl = /^https?:\/\//i.test(raw) ? raw : ("https://" + raw)
                    webTitle = raw
                }

                if (isWebBang && webTitle.length > 0) {
                    list.push({
                        id: "web",
                        type: "web",
                        name: webTitle,
                        subtitle: webProvider + " · " + I18n.t("searchWebSubtitle"),
                        icon: "󰖟",
                        isGlyph: true,
                        execute: () => {
                            openUrl(webUrl)
                        }
                    })
                }

                // 4. Uygulamalar (Fuzzy Filtreleme)
                const allApps = DesktopEntries.applications.values
                if (query === "") {
                    const sorted = allApps.slice().sort((a, b) => (a.name || "").localeCompare(b.name || ""))
                    for (const app of sorted) {
                        list.push({
                            id: app.id || app.name,
                            type: "app",
                            name: app.name || "",
                            subtitle: app.genericName || "",
                            icon: app.icon || "",
                            isGlyph: false,
                            execute: () => app.execute()
                        })
                    }
                } else {
                    const scored = []
                    for (const app of allApps) {
                        const score = fuzzyScore(app.name, app.genericName, app.keywords, query)
                        if (score > 0) {
                            scored.push({ app: app, score: score })
                        }
                    }
                    scored.sort((a, b) => {
                        if (b.score !== a.score) return b.score - a.score
                        return (a.app.name || "").localeCompare(b.app.name || "")
                    })

                    for (const item of scored) {
                        list.push({
                            id: item.app.id || item.app.name,
                            type: "app",
                            name: item.app.name || "",
                            subtitle: item.app.genericName || "",
                            icon: item.app.icon || "",
                            isGlyph: false,
                            execute: () => item.app.execute()
                        })
                    }

                    // Hiçbir uygulama eşleşmezse ve özel komut değilse web arama önerisi ekle
                    if (list.length === 0 && !isWebBang && mathResult === null && !raw.startsWith(">") && !raw.startsWith("$")) {
                        list.push({
                            id: "web_fallback",
                            type: "web",
                            name: raw,
                            subtitle: "Google · " + I18n.t("searchWebSubtitle"),
                            icon: "󰖟",
                            isGlyph: true,
                            execute: () => {
                                openUrl("https://www.google.com/search?q=" + encodeURIComponent(raw))
                            }
                        })
                    }
                }

                return list
            }

            function launchSelected() {
                const list = items
                if (list.length === 0) return
                const idx = Math.min(selectedIndex, list.length - 1)
                if (list[idx] && typeof list[idx].execute === "function") {
                    list[idx].execute()
                }
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
                    searchInput.text = ""
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
                    width: Math.round(500 * SettingsState.scaleFactor)
                    height: Math.round(450 * SettingsState.scaleFactor)
                    radius: 14
                    color: Colors.backgroundAlt
                    border.color: Colors.border
                    border.width: 1

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Arama Giriş Çubuğu
                        Rectangle {
                            Layout.fillWidth: true
                            height: 42
                            radius: 8
                            color: Colors.surface0
                            border.color: Colors.accent
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: "󰍉"
                                    color: Colors.accent
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Colors.foreground
                                        font.pixelSize: 14
                                        clip: true
                                        focus: true
                                        onTextChanged: {
                                            launcherWindow.searchText = text
                                            launcherWindow.selectedIndex = 0
                                        }
                                        Keys.onDownPressed: {
                                            if (launcherWindow.selectedIndex < launcherWindow.items.length - 1)
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
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: I18n.t("appSearchPlaceholder")
                                        color: Colors.foregroundMuted
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }

                        // Liste Görünümü
                        ListView {
                            id: appList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: launcherWindow.items
                            currentIndex: launcherWindow.selectedIndex

                            highlightMoveDuration: 100
                            highlightFollowsCurrentItem: true

                            delegate: Rectangle {
                                width: appList.width
                                height: 50
                                radius: 8
                                color: index === launcherWindow.selectedIndex ? Colors.accent : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 12

                                    // İkon Alanı
                                    Rectangle {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        radius: 8
                                        color: modelData.isGlyph ? Colors.surface1 : "transparent"

                                        Image {
                                            anchors.centerIn: parent
                                            width: 30
                                            height: 30
                                            source: !modelData.isGlyph && modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: source !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: modelData.isGlyph || !parent.children[0].visible
                                            text: modelData.isGlyph ? modelData.icon : (modelData.name ? modelData.name.charAt(0).toUpperCase() : "?")
                                            color: index === launcherWindow.selectedIndex && modelData.isGlyph ? Colors.accentText : Colors.foreground
                                            font.pixelSize: modelData.isGlyph ? 16 : 14
                                            font.family: modelData.isGlyph ? "JetBrainsMono Nerd Font" : ""
                                            font.bold: true
                                        }
                                    }

                                    // Başlık ve Açıklama
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.name || ""
                                            color: index === launcherWindow.selectedIndex ? Colors.accentText : Colors.foreground
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.subtitle || ""
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
                                        if (typeof modelData.execute === "function") {
                                            modelData.execute()
                                        }
                                        launcherWindow.closeAndReset()
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appList.count === 0
                                text: I18n.t("noResults")
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
