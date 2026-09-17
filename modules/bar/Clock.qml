import QtQuick
import Quickshell.Io
import "root:/services"

Item {
    id: root
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    property string time: ""

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.time
        color: "#cdd6f4"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarState.toggle()
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