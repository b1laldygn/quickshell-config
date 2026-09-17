// services/Battery.qml
pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property bool available: UPower.displayDevice?.isLaptopBattery ?? false
    readonly property real percentage: UPower.displayDevice?.percentage ?? 0
    readonly property bool charging: UPower.displayDevice?.state === UPowerDeviceState.Charging
    readonly property bool fullyCharged: UPower.displayDevice?.state === UPowerDeviceState.FullyCharged
}