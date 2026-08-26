pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var notifications: []

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
        }
    }

    // Artık obje referansı yerine id ile siliyoruz — daha güvenilir
    function dismiss(notificationId) {
        console.log("dismiss çağrıldı, id:", notificationId)
        const target = root.notifications.find(n => n.id === notificationId)
        root.notifications = root.notifications.filter(n => n.id !== notificationId)
        if (target) target.dismiss()
        root.notificationRemoved(notificationId)
    }
}