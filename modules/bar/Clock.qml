// modules/bar/Clock.qml
import QtQuick
import "root:/services"

Item {
    id: root

    property date now: new Date()
    property real maxW: 0

    implicitWidth: Math.max(maxW, clockText.implicitWidth)
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        anchors.centerIn: parent
        text: TimeFormat.full(root.now, SettingsState.barClockSeconds)
        color: "#cdd6f4"
        font.pixelSize: 13
        onImplicitWidthChanged: if (implicitWidth > root.maxW) root.maxW = implicitWidth
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarState.toggle()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}