// services/ClipboardState.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "root:/config"

QtObject {
    id: root

    property bool visible: false
    property var historyEntries: []
    property var pinnedEntries: []
    property var allEntries: []

    // ---- SABİTLENENLERİ DİSKTEN YÜKLEME ----
    property Process loadPinnedProc: Process {
        command: ["sh", "-c", 'cat "$HOME/.config/quickshell/myconfig/pinned_clipboard.json" 2>/dev/null || echo "[]"']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text)
                    if (Array.isArray(parsed)) {
                        root.pinnedEntries = parsed
                    }
                } catch (e) {
                    root.pinnedEntries = []
                }
                root.combineEntries()
            }
        }
    }

    // ---- SABİTLENENLERİ DİSKE KAYDETME ----
    property Process savePinnedProc: Process { command: [] }
    function savePinned() {
        savePinnedProc.command = [
            "sh", "-c",
            'mkdir -p "$HOME/.config/quickshell/myconfig/pinned_images" && printf "%s" "$1" > "$HOME/.config/quickshell/myconfig/pinned_clipboard.json"',
            "_", JSON.stringify(root.pinnedEntries)
        ]
        savePinnedProc.running = true
    }

    // ---- CLIPHIST LİSTESİ VE RESİM ÖNİZLEMELERİNİ AYIKLAMA ----
    property Process listProc: Process {
        command: [
            "sh", "-c",
            `mkdir -p /tmp/quickshell-clipboard
cliphist list | while IFS=$'\t' read -r id text; do
    printf "%s\t%s\n" "$id" "$text"
    if echo "$text" | grep -q '\[\[ binary data'; then
        if [ ! -f "/tmp/quickshell-clipboard/$id.png" ]; then
            cliphist decode "$id" > "/tmp/quickshell-clipboard/$id.png" 2>/dev/null || true
        fi
    fi
done`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0)
                const result = []
                for (const line of lines) {
                    const tabIndex = line.indexOf("\t")
                    if (tabIndex === -1) continue
                    const id = line.substring(0, tabIndex).trim()
                    const preview = line.substring(tabIndex + 1).trim()
                    const isImg = preview.includes("[[ binary data")

                    let imgInfo = ""
                    if (isImg) {
                        const m = preview.match(/binary data\s+([0-9.]+\s*\w+)\s*(\w+)\s*(\d+x\d+)/i)
                        if (m) imgInfo = m[2].toUpperCase() + " · " + m[3] + " (" + m[1] + ")"
                        else imgInfo = "Görsel"
                    }

                    result.push({
                        id: id,
                        raw: line,
                        preview: preview,
                        isImage: isImg,
                        imageInfo: imgInfo,
                        imagePath: isImg ? ("/tmp/quickshell-clipboard/" + id + ".png") : "",
                        isPinned: false
                    })
                }
                root.historyEntries = result
                root.combineEntries()
            }
        }
    }

    function refresh() {
        if (!listProc.running) listProc.running = true
        if (!loadPinnedProc.running) loadPinnedProc.running = true
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) refresh()
    }

    // Sabitlenenler ile geçmişi birleştir
    function combineEntries() {
        const pinnedList = root.pinnedEntries.map(p => Object.assign({}, p, { isPinned: true }))

        // Geçmişteki öğeleri sabitlenmişlerle eşleştir
        const historyList = root.historyEntries.map(h => {
            const isP = pinnedList.some(p => p.content === (h.isImage ? h.id : h.preview))
            return Object.assign({}, h, { isPinned: isP })
        })

        // Sabitlenmemiş geçmiş öğeleri
        const unpinnedOnly = historyList.filter(h => !h.isPinned)
        root.allEntries = [...pinnedList, ...unpinnedOnly]
    }

    // ---- SABİTLEME / SABİTLEMEYİ KALDIRMA ----
    property Process pinImageProc: Process { command: [] }
    function togglePin(entry) {
        const contentKey = entry.isImage ? (entry.id || entry.content) : entry.preview
        const existingIdx = root.pinnedEntries.findIndex(p => p.content === contentKey)

        if (existingIdx >= 0) {
            // Zaten sabitlenmişse sabitlemeyi kaldır
            const updated = root.pinnedEntries.slice()
            updated.splice(existingIdx, 1)
            root.pinnedEntries = updated
            root.savePinned()
            root.combineEntries()
        } else {
            // Sabitle
            const newPin = {
                id: "pin_" + Date.now(),
                isPinned: true,
                isImage: !!entry.isImage,
                preview: entry.preview,
                content: contentKey,
                imageInfo: entry.imageInfo || "",
                time: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
            }

            if (entry.isImage) {
                const targetImg = "/home/bilal/.config/quickshell/myconfig/pinned_images/" + (entry.id || Date.now()) + ".png"
                newPin.imagePath = targetImg
                // Görseli kalıcı depolama klasörüne kopyala
                pinImageProc.command = [
                    "sh", "-c",
                    'mkdir -p "$HOME/.config/quickshell/myconfig/pinned_images" && cp "$1" "$2"',
                    "_", (entry.imagePath || ("/tmp/quickshell-clipboard/" + entry.id + ".png")), targetImg
                ]
                pinImageProc.running = true
            }

            root.pinnedEntries = [newPin, ...root.pinnedEntries]
            root.savePinned()
            root.combineEntries()
        }
    }

    // ---- SEÇME / PANOLAMA (COPY) ----
    property Process selectProc: Process { command: [] }
    function selectEntry(entry) {
        if (entry.isImage) {
            const src = entry.imagePath || ("/tmp/quickshell-clipboard/" + entry.id + ".png")
            selectProc.command = ["sh", "-c", 'wl-copy -t image/png < "$1"', "_", src]
        } else {
            const textToCopy = entry.content || entry.preview
            selectProc.command = ["sh", "-c", 'printf "%s" "$1" | wl-copy', "_", textToCopy]
        }
        selectProc.running = true
        root.visible = false
    }

    // ---- SİLME ----
    property Process deleteProc: Process {
        command: []
        onExited: root.refresh()
    }
    function deleteEntry(entry) {
        if (entry.isPinned) {
            root.pinnedEntries = root.pinnedEntries.filter(p => p.id !== entry.id && p.content !== entry.content)
            root.savePinned()
            root.combineEntries()
        }
        if (entry.raw) {
            deleteProc.command = ["sh", "-c", 'printf "%s" "$1" | cliphist delete', "_", entry.raw]
            deleteProc.running = true
        }
    }

    // ---- GEÇMİŞİ TEMİZLE (Sabitlenenleri korur) ----
    property Process wipeProc: Process {
        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
    function wipeAll() {
        wipeProc.running = true
    }

    Component.onCompleted: {
        root.loadPinnedProc.running = true
    }
}
