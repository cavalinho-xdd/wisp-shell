import QtQuick
import QtQuick.Effects

// The session list, grown out of the left island. Also the theme's reader of
// sessionModel: the current session's name comes out as `currentName`.
Item {
    id: menu

    required property var tokens
    property var model
    property int currentIndex: 0
    property bool open: false
    signal picked(int index)

    readonly property var current: repeater.count > 0 ? repeater.itemAt(Math.max(0, Math.min(currentIndex, repeater.count - 1))) : null
    readonly property string currentName: current ? current.sessionName : ""

    width: 248
    height: list.implicitHeight + 12
    transformOrigin: Item.TopLeft
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.94
    visible: opacity > 0
    enabled: open
    transform: Translate { y: menu.open ? 0 : -6; Behavior on y { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.1 } } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: menu.tokens.curveKindle } }
    Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.002 } }

    Accessible.role: Accessible.PopupMenu

    Surface {
        anchors.fill: parent
        tokens: menu.tokens
        radius: 22
        glowBlur: 30
        glowAlpha: 0.14
        ambientY: 24
        ambientBlur: 60
        ambientAlpha: 0.55
    }

    Column {
        id: list
        x: 6
        y: 6
        width: parent.width - 12

        Repeater {
            id: repeater
            model: menu.model

            delegate: Rectangle {
                id: entry
                required property int index
                required property string name
                required property string comment
                readonly property string sessionName: name
                readonly property bool active: index === menu.currentIndex

                width: list.width
                height: texts.implicitHeight + 20
                radius: 16
                color: hit.containsMouse ? menu.tokens.ash : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Accessible.role: Accessible.MenuItem
                Accessible.name: name

                RectangularShadow {
                    anchors.fill: dot
                    radius: 3
                    blur: 8
                    color: menu.tokens.ember
                    visible: entry.active
                }
                Rectangle {
                    id: dot
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: entry.active ? menu.tokens.ember : "transparent"
                }
                Column {
                    id: texts
                    x: 30
                    width: parent.width - x - 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        text: entry.name
                        elide: Text.ElideRight
                        font.family: menu.tokens.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: menu.tokens.text
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: entry.comment
                        elide: Text.ElideRight
                        font.family: menu.tokens.fontFamily
                        font.pixelSize: 12
                        color: menu.tokens.muted
                    }
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: menu.picked(entry.index)
                }
            }
        }
    }
}
