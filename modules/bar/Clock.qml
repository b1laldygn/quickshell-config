import QtQuick
import Quickshell.Io
import "root:/config"

Item {
    id: root
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    property string time: ""

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.time
        color: Colors.text
        font.pixelSize: 13
    }

    Process {
        id: dateProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.time = this.text.trim()
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}