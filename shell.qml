// shell.qml
import Quickshell
import "root:/modules/bar"
import "root:/modules/notifications"

ShellRoot {
    Bar {}
    NotificationDaemon {}
}