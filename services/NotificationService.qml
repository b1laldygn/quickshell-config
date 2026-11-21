// services/NotificationService.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications
import "root:/services"

QtObject {
    id: root

    property var notifications: []
    property var history: []
    property int unreadCount: 0
    property int maxHistory: SettingsState.notificationHistoryLimit
    property bool centerVisible: false

    signal notificationAdded(var notification)
    signal notificationRemoved(int id)

    property Process soundProc: Process {
        command: []
    }

    function playSound(type) {
        if (!SettingsState.notificationSounds) return
        if (SettingsState.dndEnabled && (!SettingsState.dndAllowCritical || type !== "critical")) return

        const soundFile = (type === "critical")
            ? "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
            : "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"

        soundProc.command = [
            "sh", "-c",
            'file="$1"; (pw-play "$file" || paplay "$file") >/dev/null 2>&1 &',
            "_", soundFile
        ]
        soundProc.running = true
    }

    function toggleDnd() {
        SettingsState.dndEnabled = !SettingsState.dndEnabled
        SettingsState.save()
    }

    function isAppBlocked(appName) {
        if (!appName) return false
        const target = appName.trim().toLowerCase()
        return (SettingsState.blockedApps || []).some(a => a.toLowerCase() === target)
    }

    function isAppMuted(appName) {
        if (!appName) return false
        const target = appName.trim().toLowerCase()
        return (SettingsState.mutedApps || []).some(a => a.toLowerCase() === target)
    }

    function muteApp(appName) {
        if (!appName) return
        const target = appName.trim()
        if (isAppMuted(target)) return
        SettingsState.mutedApps = [...(SettingsState.mutedApps || []), target]
        SettingsState.save()
    }

    function unmuteApp(appName) {
        if (!appName) return
        const target = appName.trim().toLowerCase()
        SettingsState.mutedApps = (SettingsState.mutedApps || []).filter(a => a.toLowerCase() !== target)
        SettingsState.save()
    }

    function blockApp(appName) {
        if (!appName) return
        const target = appName.trim()
        if (isAppBlocked(target)) return
        SettingsState.blockedApps = [...(SettingsState.blockedApps || []), target]
        SettingsState.save()
        // Engellenen uygulamanın açık popup'larını anında kapat
        for (const n of root.notifications) {
            if ((n.appName || "").trim().toLowerCase() === target.toLowerCase()) {
                n.dismiss()
            }
        }
    }

    function unblockApp(appName) {
        if (!appName) return
        const target = appName.trim().toLowerCase()
        SettingsState.blockedApps = (SettingsState.blockedApps || []).filter(a => a.toLowerCase() !== target)
        SettingsState.save()
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: (notification) => {
            const app = (notification.appName || "Bildirim").trim()
            const isCritical = notification.urgency === 2

            // 1. Engellenen Uygulama Kontrolü (Blacklist)
            if (root.isAppBlocked(app)) {
                notification.dismiss()
                return
            }

            notification.tracked = true

            // 2. Ses Çalma Kontrolü
            if (!root.isAppMuted(app)) {
                root.playSound(isCritical ? "critical" : "normal")
            }

            const notifId = notification.id

            // Uygulama bildirimi kapattığında listeden düş
            notification.closed.connect(function() {
                root.notifications = root.notifications.filter(n => n !== notification)
                root.notificationRemoved(notifId)
            })

            // 3. Rahatsız Etmeyin (DND) Kontrolü
            const allowPopup = !SettingsState.dndEnabled || (isCritical && SettingsState.dndAllowCritical)
            if (allowPopup) {
                root.notifications = [...root.notifications, notification]
                root.notificationAdded(notification)
            }

            // 4. Geçmişe Kaydetme
            const snapshot = {
                id: notifId,
                appName: app,
                summary: notification.summary || "",
                body: notification.body || "",
                image: notification.image || "",
                urgency: notification.urgency !== undefined ? notification.urgency : 1,
                time: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
            }
            let newHistory = [snapshot, ...root.history]
            if (newHistory.length > root.maxHistory) {
                newHistory = newHistory.slice(0, root.maxHistory)
            }
            root.history = newHistory

            if (!root.centerVisible) {
                root.unreadCount++
            }
        }
    }

    function dismiss(notificationId) {
        const target = root.notifications.find(n => n.id === notificationId)
        if (target) target.dismiss()
    }

    function clearHistory() {
        root.history = []
    }

    function removeHistoryEntry(index) {
        let newHistory = root.history.slice()
        newHistory.splice(index, 1)
        root.history = newHistory
    }

    function toggleCenter() {
        root.centerVisible = !root.centerVisible
        if (root.centerVisible) {
            root.unreadCount = 0
        }
    }
}
