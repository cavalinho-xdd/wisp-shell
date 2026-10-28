import QtQuick
import QtQuick.Effects

// One dot per user, like the workspace dots: the selected one is a lit ember
// pill, hover names the others. Hidden with a single user. Also the theme's
// reader of userModel: the current user's roles come out as properties.
Row {
    id: dots

    required property var tokens
    property var model
    property int currentIndex: 0
    signal picked(int index)

    readonly property var current: repeater.count > 0 ? repeater.itemAt(Math.max(0, Math.min(currentIndex, repeater.count - 1))) : null
    readonly property string userName: current ? current.userName : ""
    readonly property string displayName: current ? (current.realName || current.userName) : ""
    readonly property bool needsPassword: current ? current.needsPassword : true
    readonly property int count: repeater.count

    height: 10
    spacing: 8
    opacity: count > 1 ? 1 : 0
    enabled: count > 1

    Repeater {
        id: repeater
        model: dots.model

        delegate: Item {
            id: dot
            required property int index
            required property string name
            required property string realName
            required property bool needsPassword
            readonly property string userName: name
            readonly property bool active: index === dots.currentIndex

            width: active ? 24 : 6
            height: 10
            Behavior on width { SpringAnimation { spring: 4; damping: 0.32; epsilon: 0.25 } }

            Accessible.role: Accessible.Button
            Accessible.name: realName || name

            RectangularShadow {
                anchors.fill: pill
                radius: 3
                blur: dots.tokens.glow * 10
                color: dots.tokens.ember
                opacity: dot.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            Rectangle {
                id: pill
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: dot.active ? dots.tokens.ember : Qt.rgba(1, 1, 1, hit.containsMouse ? 0.55 : 0.28)
                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            // The name of a user you are about to pick.
            Rectangle {
                y: 18
                anchors.horizontalCenter: parent.horizontalCenter
                width: tip.implicitWidth + 18
                height: tip.implicitHeight + 8
                radius: 9
                color: dots.tokens.smoke
                opacity: hit.containsMouse && !dot.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: dots.tokens.motionFast } }
                Text {
                    id: tip
                    anchors.centerIn: parent
                    text: dot.realName || dot.name
                    font.family: dots.tokens.fontFamily
                    font.pixelSize: 12
                    color: dots.tokens.muted
                }
            }

            MouseArea {
                id: hit
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dots.picked(dot.index)
            }
        }
    }
}
