// modules/bar/QuickToggles.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth
import "root:/config"
import "root:/services"

RowLayout {
    id: root
    spacing: Math.round(8 * SettingsState.scaleFactor)

    property real currentBrightness: 0.5

    function closeOtherPopovers(exceptName) {
        if (exceptName !== "network") NetworkState.visible = false
        if (exceptName !== "audio") AudioDeviceListState.visible = false
        if (exceptName !== "bluetooth") BluetoothListState.visible = false
        if (exceptName !== "sysmon") SystemInfo.panelVisible = false
        if (exceptName !== "weather") WeatherPanelState.visible = false
        if (exceptName !== "calendar") CalendarState.visible = false
    }

    // ---- WIFI ----
    Rectangle {
        id: wifiBtn
        Layout.alignment: Qt.AlignVCenter
        width: Math.round(26 * SettingsState.scaleFactor)
        height: width
        radius: Math.round(6 * SettingsState.scaleFactor)
        color: wifiHover.containsMouse || NetworkState.visible ? Colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: WifiStatus.connected ? "󰖩" : "󰖪"
            color: NetworkState.visible ? Colors.accent : Colors.foreground
            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: wifiHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    const pos = wifiBtn.mapToItem(null, wifiBtn.width / 2, wifiBtn.height)
                    NetworkState.anchorX = pos.x
                    root.closeOtherPopovers("network")
                    NetworkState.visible = !NetworkState.visible
                } else if (mouse.button === Qt.RightButton) {
                    wifiMenuProc.running = true
                }
            }
        }
    }

    Process {
        id: wifiMenuProc
        command: ["nm-connection-editor"]
    }

    // ---- BRIGHTNESS ----
    Item {
        id: brightnessContainer
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: brightnessIcon.width + Math.round(4 * SettingsState.scaleFactor) + brightnessLabel.width
        implicitHeight: Math.round(22 * SettingsState.scaleFactor)

        Text {
            id: brightnessIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃞"
            color: Colors.foreground
            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            id: brightnessLabel
            anchors.left: brightnessIcon.right
            anchors.leftMargin: Math.round(4 * SettingsState.scaleFactor)
            anchors.verticalCenter: brightnessIcon.verticalCenter
            text: Math.round(root.currentBrightness * 100) + "%"
            color: Colors.foreground
            font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onWheel: (wheel) => {
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                root.currentBrightness = Math.max(0, Math.min(1, root.currentBrightness + delta))
                OsdService.show("brightness", root.currentBrightness)
                brightnessDebounce.restart()
            }
        }
    }

    Timer {
        id: brightnessDebounce
        interval: 150
        onTriggered: {
            const pct = Math.round(root.currentBrightness * 100)
            brightnessSetProc.command = ["brightnessctl", "set", pct + "%"]
            brightnessSetProc.running = true
        }
    }

    Process {
        id: brightnessSetProc
        onExited: brightnessGetProc.running = true
    }

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "-m", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")
                if (parts.length > 3) {
                    const newBrightness = parseInt(parts[3]) / 100
                    if (Math.abs(newBrightness - root.currentBrightness) > 0.001) {
                        root.currentBrightness = newBrightness
                        OsdService.show("brightness", newBrightness)
                    }
                }
            }
        }
    }

    Timer {
        interval: Math.max(250, SettingsState.brightnessPollInterval)
        running: true
        repeat: true
        onTriggered: {
            if (!brightnessDebounce.running && !brightnessGetProc.running) {
                brightnessGetProc.running = true
            }
        }
    }

    // ---- VOLUME ----
    Rectangle {
        id: volumeContainer
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: volumeRow.implicitWidth + Math.round(10 * SettingsState.scaleFactor)
        implicitHeight: Math.round(26 * SettingsState.scaleFactor)
        radius: Math.round(6 * SettingsState.scaleFactor)
        color: volumeHover.containsMouse || AudioDeviceListState.visible ? Colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            id: volumeRow
            anchors.centerIn: parent
            spacing: Math.round(4 * SettingsState.scaleFactor)

            Text {
                text: AudioMixerState.masterMuted ? "󰝟" : "󰕾"
                color: AudioDeviceListState.visible ? Colors.accent : Colors.foreground
                font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                text: Math.round(AudioMixerState.masterVolume * 100) + "%"
                color: AudioDeviceListState.visible ? Colors.accent : Colors.foreground
                font.pixelSize: Math.round(11 * SettingsState.scaleFactor)
            }
        }

        MouseArea {
            id: volumeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    const pos = volumeContainer.mapToItem(null, volumeContainer.width / 2, volumeContainer.height)
                    AudioDeviceListState.anchorX = pos.x
                    root.closeOtherPopovers("audio")
                    AudioDeviceListState.visible = !AudioDeviceListState.visible
                } else if (mouse.button === Qt.MiddleButton) {
                    AudioMixerState.toggleMasterMute()
                }
            }
            onWheel: (wheel) => {
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                const target = Math.max(0, Math.min(1, AudioMixerState.masterVolume + delta))
                AudioMixerState.masterVolume = target
                OsdService.show("volume", target)
                volumeDebounce.restart()
            }
        }
    }

    Timer {
        id: volumeDebounce
        interval: 150
        onTriggered: {
            AudioMixerState.setMasterVolume(Math.round(AudioMixerState.masterVolume * 100))
        }
    }

    // ---- BLUETOOTH ----
    Rectangle {
        id: btBtn
        Layout.alignment: Qt.AlignVCenter
        width: Math.round(26 * SettingsState.scaleFactor)
        height: width
        radius: Math.round(6 * SettingsState.scaleFactor)
        color: btHover.containsMouse || BluetoothListState.visible ? Colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: {
                if (!BluetoothStatus.powered) return "󰂲"
                if (BluetoothStatus.connectedCount > 0) return "󰂱"
                return "󰂯"
            }
            color: BluetoothListState.visible ? Colors.accent : Colors.foreground
            font.pixelSize: Math.round(14 * SettingsState.scaleFactor)
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: btHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    const pos = btBtn.mapToItem(null, btBtn.width / 2, btBtn.height)
                    BluetoothListState.anchorX = pos.x
                    root.closeOtherPopovers("bluetooth")
                    BluetoothListState.visible = !BluetoothListState.visible
                } else if (mouse.button === Qt.RightButton) {
                    bluetoothMenuProc.running = true
                }
            }
        }
    }

    Process {
        id: bluetoothMenuProc
        command: ["blueman-manager"]
    }
}
