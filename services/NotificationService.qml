// services/NotificationService.qml
pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var notifications: []
    property var history: []
    property int unreadCount: 0
    property int maxHistory: 50
    property bool centerVisible: false

    signal notificationAdded(var notification)
    signal notificationRemoved(int id)

    property NotificationServer server: NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            root.notifications = [...root.notifications, notification]
            root.notificationAdded(notification)

            const notifId = notification.id

            // Uygulama bildirimi kendi kapatırsa (yeni mesaj, timeout, vs.)
            // bizim listemizden de anında sil — kendi id'sini kapanmadan ÖNCE
            // yakalıyoruz (closure), çünkü kapandıktan sonra nesnenin id'si
            // güvenilir olmayabilir.
            notification.closed.connect(function() {
                root.notifications = root.notifications.filter(n => n !== notification)
                root.notificationRemoved(notifId)
            })

            const snapshot = {
                appName: notification.appName || "Bildirim",
                summary: notification.summary || "",
                body: notification.body || "",
                image: notification.image || "",
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
        // Listeden silme işlemi artık yukarıdaki "closed" sinyaliyle otomatik oluyor
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