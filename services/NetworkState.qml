pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
    property real anchorX: 60
    property var networks: []
    property bool scanning: false
}
