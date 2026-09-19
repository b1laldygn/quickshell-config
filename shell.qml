//@ pragma UseQApplication
import Quickshell
import QtQuick
import "root:/modules/bar"
import "root:/modules/notifications"
import "root:/modules/wallpaper"
import "root:/modules/osd"
import "root:/modules/overview"
import "root:/modules/clipboard"
import "root:/services"
import "root:/modules/launcher"
import "root:/modules/powermenu"
import "root:/modules/network"
import "root:/modules/bluetooth"
import "root:/modules/audio"
import "root:/modules/sysmon"
import "root:/modules/calendar"
import "root:/modules/keybinds"
import "root:/modules/mixer"
import "root:/modules/alttab"


ShellRoot {
    Bar {}
    NotificationDaemon {}
    NotificationCenter {}
    WallpaperPicker {}
    WallpaperIpc {}
    Osd {}
    Overview {}
    OverviewIpc {}
    ClipboardPicker {}
    ClipboardIpc {}
    Launcher {}
    LauncherIpc {}
    PowerMenu {}
    PowerMenuIpc {}
    NetworkList {}
    NetworkIpc {}
    BluetoothList {}
    BluetoothIpc {}
    AudioDeviceList {}
    AudioDeviceIpc {}
    SystemMonitorPanel {}
    Calendar {}
    KeybindsOverlay {}
    KeybindsIpc {}
    AudioMixer {}
    MixerIpc {}
    AltTabOverlay {}
    AltTabIpc {}

    Timer {
        interval: 1500
        running: true
        repeat: false
        onTriggered: WallpaperService.restoreLastWallpaper()
    }
}