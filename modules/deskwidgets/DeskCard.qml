// modules/deskwidgets/DeskCard.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/config"
import "root:/services"

PanelWindow {
    id: win

    property string widgetId: ""
    property bool shown: true
    property string corner: "top-right"
    property int cardWidth: 260
    default property alias content: body.data

    visible: shown

    readonly property real stackOffset: DesktopLayout.offsetFor(widgetId)

    anchors {
        top: corner.includes("top")
        bottom: corner.includes("bottom")
        left: corner.includes("left")
        right: corner.includes("right")
    }
    margins {
        top: 60 + (corner.includes("top") ? stackOffset : 0)
        bottom: 40 + (corner.includes("bottom") ? stackOffset : 0)
        left: 30
        right: 30
    }

    implicitWidth: cardWidth
    implicitHeight: body.implicitHeight + 32
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function publish() {
        DesktopLayout.report(widgetId, shown ? implicitHeight : 0)
    }
    onImplicitHeightChanged: publish()
    onShownChanged: publish()
    Component.onCompleted: publish()

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, 0.82)
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 4
        }
    }
}