// services/KeybindsState.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false
    property bool loading: false
    property var binds: []

    function decodeModmask(mask) {
        const mods = []
        if (mask & 64) mods.push("SUPER")
        if (mask & 4) mods.push("CTRL")
        if (mask & 8) mods.push("ALT")
        if (mask & 1) mods.push("SHIFT")
        return mods.join(" ")
    }

    function formatKey(rawKey) {
        if (!rawKey) return ""
        const map = {
            "Return": "Enter",
            "Escape": "Esc",
            "space": "Space",
            "Space": "Space",
            "Tab": "Tab",
            "BackSpace": "Backspace",
            "Delete": "Del",
            "Prior": "PgUp",
            "Next": "PgDn",
            "Left": "←",
            "Right": "→",
            "Up": "↑",
            "Down": "↓",
            "Print": "PrintSc",
            "mouse:272": "LMB",
            "mouse:273": "RMB",
            "mouse:274": "MMB",
            "mouse_down": "Scroll ↓",
            "mouse_up": "Scroll ↑",
            "XF86AudioRaiseVolume": "Vol +",
            "XF86AudioLowerVolume": "Vol -",
            "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic Mute",
            "XF86AudioPlay": "Play/Pause",
            "XF86AudioPause": "Pause",
            "XF86AudioNext": "Next",
            "XF86AudioPrev": "Prev",
            "XF86MonBrightnessUp": "Bright +",
            "XF86MonBrightnessDown": "Bright -"
        }
        if (map[rawKey] !== undefined) return map[rawKey]
        if (rawKey.length === 1) return rawKey.toUpperCase()
        return rawKey
    }

    function formatLabel(dispatcher, args, desc) {
        if (desc && desc.trim().length > 0) return desc.trim()
        const a = (args || "").trim()

        if (dispatcher === "exec") {
            const ipc = a.match(/qs\s+ipc\s+call\s+(\S+)\s+(\S+)/)
            if (ipc) return ipc[1].charAt(0).toUpperCase() + ipc[1].slice(1) + ": " + ipc[2]
            return a.split("/").pop() || a
        }

        const dispMap = {
            "killactive": "Close Active Window",
            "exit": "Exit Hyprland",
            "fullscreen": "Toggle Fullscreen",
            "togglefloating": "Toggle Floating",
            "pin": "Pin Window",
            "pseudo": "Toggle Pseudo-Tile",
            "togglesplit": "Toggle Split",
            "movewindow": "Move Window",
            "resizewindow": "Resize Window",
            "movefocus": "Focus Window",
            "workspace": "Workspace",
            "movetoworkspace": "Move to Workspace",
            "movetoworkspacesilent": "Move Silently to Workspace",
            "togglespecialworkspace": "Toggle Scratchpad"
        }
        const nice = dispMap[dispatcher] || dispatcher
        return a ? (nice + " " + a) : nice
    }

    function categorize(dispatcher, args) {
        const d = dispatcher || ""
        const a = args || ""
        if (d.startsWith("workspace") || d.startsWith("movetoworkspace") || d === "togglespecialworkspace")
            return "catWorkspaces"
        if (["killactive", "exit", "fullscreen", "togglefloating", "movewindow", "resizewindow",
             "movefocus", "pin", "pseudo", "togglesplit", "centerwindow", "swapwindow"].includes(d))
            return "catWindowManagement"
        if (d === "exec") {
            if (a.includes("ipc call")) return "catQuickshellTools"
            if (a.includes("screenshot") || a.includes("grim") || a.includes("hyprlock") ||
                a.includes("pactl") || a.includes("wpctl") || a.includes("brightnessctl") ||
                a.includes("playerctl") || a.includes("cliphist"))
                return "catSystem"
            return "catApps"
        }
        return "catOther"
    }

    function compactNumericWorkspaces(items) {
        const grouped = {}
        const result = []

        for (const item of items) {
            const d = item.dispatcher
            const a = (item.args || "").trim()
            const isNumWs = (d === "workspace" || d === "movetoworkspace" || d === "movetoworkspacesilent") &&
                            /^(10|[1-9])$/.test(a) &&
                            /^[0-9]$/.test(item.rawKey)
            if (isNumWs) {
                const gKey = item.mods + "|" + d
                if (!grouped[gKey]) {
                    grouped[gKey] = { mods: item.mods, dispatcher: d, nums: [], keys: [], category: item.category }
                }
                grouped[gKey].nums.push(parseInt(a, 10))
                grouped[gKey].keys.push(item.rawKey)
            } else {
                result.push(item)
            }
        }

        for (const k in grouped) {
            const g = grouped[k]
            if (g.nums.length >= 4) {
                g.nums.sort((x, y) => x - y)
                const rangeLabel = g.nums[0] + "–" + g.nums[g.nums.length - 1]
                const keyRange = g.keys.includes("1") && g.keys.includes("0") ? "1..0" : (g.keys[0] + ".." + g.keys[g.keys.length - 1])
                result.push({
                    mods: g.mods,
                    key: keyRange,
                    rawKey: g.keys.join(" "),
                    dispatcher: g.dispatcher,
                    args: rangeLabel,
                    label: formatLabel(g.dispatcher, rangeLabel, ""),
                    command: g.dispatcher + " " + g.nums.join(","),
                    category: g.category
                })
            } else {
                for (let i = 0; i < g.nums.length; i++) {
                    const a = String(g.nums[i])
                    const rk = g.keys[i]
                    result.push({
                        mods: g.mods,
                        key: formatKey(rk),
                        rawKey: rk,
                        dispatcher: g.dispatcher,
                        args: a,
                        label: formatLabel(g.dispatcher, a, ""),
                        command: g.dispatcher + " " + a,
                        category: g.category
                    })
                }
            }
        }

        return result
    }

    function parseJsonBinds(jsonText) {
        try {
            const arr = JSON.parse(jsonText)
            if (!Array.isArray(arr) || arr.length === 0) return null
            const out = []
            const seen = {}
            for (const b of arr) {
                if (!b.key && !b.keycode) continue
                const rawKey = b.key || ("code:" + b.keycode)
                const mods = decodeModmask(b.modmask || 0)
                const dispatcher = (b.dispatcher || "").trim()
                const args = (b.arg || "").trim()
                const dedupKey = mods + "|" + rawKey + "|" + dispatcher + "|" + args
                if (seen[dedupKey]) continue
                seen[dedupKey] = true

                const desc = b.has_description ? b.description : ""
                out.push({
                    mods: mods,
                    key: formatKey(rawKey),
                    rawKey: rawKey,
                    dispatcher: dispatcher,
                    args: args,
                    label: formatLabel(dispatcher, args, desc),
                    command: dispatcher === "exec" ? args : (dispatcher + (args ? " " + args : "")),
                    category: categorize(dispatcher, args)
                })
            }
            return compactNumericWorkspaces(out)
        } catch (e) {
            return null
        }
    }

    function parseConfFallback(confText) {
        const lines = confText.split("\n")
        const out = []
        const seen = {}
        for (const rawLine of lines) {
            const line = rawLine.trim()
            if (line.startsWith("#")) continue
            const isDesc = /^bindd[a-z]*\s*=/.test(line)
            const m = line.match(/^bind[a-z]*\s*=\s*(.+)$/)
            if (!m) continue
            const parts = m[1].split(",")
            if (parts.length < 3) continue

            const mods = parts[0].trim().replace(/\$mainMod/g, "SUPER")
            const rawKey = parts[1].trim()
            let desc = ""
            let dispatcher = ""
            let args = ""

            if (isDesc && parts.length >= 4) {
                desc = parts[2].trim()
                dispatcher = parts[3].trim()
                args = parts.slice(4).join(",").trim()
            } else {
                dispatcher = parts[2].trim()
                args = parts.slice(3).join(",").trim()
            }

            const dedupKey = mods + "|" + rawKey + "|" + dispatcher + "|" + args
            if (seen[dedupKey]) continue
            seen[dedupKey] = true

            out.push({
                mods: mods,
                key: formatKey(rawKey),
                rawKey: rawKey,
                dispatcher: dispatcher,
                args: args,
                label: formatLabel(dispatcher, args, desc),
                command: dispatcher === "exec" ? args : (dispatcher + (args ? " " + args : "")),
                category: categorize(dispatcher, args)
            })
        }
        return compactNumericWorkspaces(out)
    }

    property Process readProc: Process {
        command: [
            "sh", "-c",
            "hyprctl binds -j 2>/dev/null || true; echo '___FALLBACK_SPLIT___'; cat ~/.config/hypr/hyprland-quickshell.conf ~/.config/hypr/hyprland/keybinds.conf ~/.config/hypr/hyprland.conf 2>/dev/null || true"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const chunks = this.text.split("___FALLBACK_SPLIT___")
                const jsonPart = (chunks[0] || "").trim()
                const confPart = (chunks[1] || "").trim()

                let parsed = jsonPart.startsWith("[") ? root.parseJsonBinds(jsonPart) : null
                if (!parsed || parsed.length === 0) {
                    parsed = root.parseConfFallback(confPart)
                }
                root.binds = parsed || []
                root.loading = false
            }
        }
    }

    function refresh() {
        if (readProc.running) return
        root.loading = true
        readProc.running = true
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) refresh()
    }
}
