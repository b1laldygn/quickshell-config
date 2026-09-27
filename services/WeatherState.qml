// services/WeatherState.qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool loaded: false
    property real tempC: 0
    property real feelsLikeC: 0
    property string condition: ""
    property string icon: "󰖐"
    property int humidity: 0
    property real windKmh: 0
    property string cityName: ""

    function mapIcon(code) {
        const c = parseInt(code)
        if (c === 113) return "󰖙"           // Açık
        if (c === 116) return "󰖕"           // Parçalı bulutlu
        if ([119, 122].includes(c)) return "󰖐"   // Bulutlu/kapalı
        if ([143, 248, 260].includes(c)) return "󰖑"   // Sisli
        if ([176, 263, 266, 293, 296, 353].includes(c)) return "󰖗"   // Hafif yağmur
        if ([299, 302, 305, 308, 356, 359, 314, 311, 317, 320].includes(c)) return "󰖖"   // Yağmur
        if ([200, 386, 389, 392, 395].includes(c)) return "󰖓"   // Fırtına
        if ([323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(c)) return "󰖘"   // Kar
        return "󰖐"
    }

    property Process fetchProc: Process {
        command: ["curl", "-s", "-m", "10", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)
                    const current = data.current_condition[0]
                    root.tempC = parseFloat(current.temp_C)
                    root.feelsLikeC = parseFloat(current.FeelsLikeC)
                    root.condition = current.weatherDesc[0].value
                    root.humidity = parseInt(current.humidity)
                    root.windKmh = parseFloat(current.windspeedKmph)
                    root.icon = root.mapIcon(current.weatherCode)
                    root.cityName = data.nearest_area?.[0]?.areaName?.[0]?.value || ""
                    root.loaded = true
                } catch (e) {
                    // Ağ hatası ya da parse sorunu — sessizce eski veriyi koru
                }
            }
        }
    }

    function refresh() {
        fetchProc.running = true
    }

    property Timer refreshTimer: Timer {
        interval: 1800000   // 30 dakika
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}