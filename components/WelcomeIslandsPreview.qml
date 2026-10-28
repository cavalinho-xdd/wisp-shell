import QtQuick
import QtQuick.Effects
import "../core"
import "ember"
import "ember/layout.js" as IslandLayout

// A miniature of the top bar over the wallpaper for the welcome wizard: the
// three islands in the chosen layout, material, glow and ember, so a step
// shows what its controls change. `highlight` lights one island (0 left,
// 1 centre, 2 right) and dims the others, as an open island does.
Item {
    id: root

    property string wallpaper: ""
    property int highlight: -1

    readonly property int islandH: 24
    readonly property int margin: Theme.spaceSm
    readonly property var widths: [64, 104, 88]
    readonly property var slots: IslandLayout.place(Settings.conf.shell.emberLayout, width, widths, -1, margin, Theme.spaceXs)

    implicitHeight: islandH + 2 * Theme.spaceLg + Theme.spaceSm

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: Theme.radiusTile
        color: Theme.ashHi
        layer.enabled: true
        visible: false
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusTile
        color: Theme.ash
    }
    Image {
        id: wp
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 960
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: wp.status === Image.Ready
        maskEnabled: true
        maskSource: shape
        brightness: -0.15
    }

    Repeater {
        model: 3
        delegate: Item {
            id: island
            required property int index
            readonly property bool lit: root.highlight === index
            readonly property bool dimmed: root.highlight >= 0 && !lit

            x: root.slots[index]
            y: Theme.spaceLg
            width: root.widths[index]
            height: root.islandH
            Behavior on x { SpringAnimation { spring: Theme.springMove; damping: Theme.dampingMove } }

            opacity: dimmed ? Theme.dimOpacity : 1
            scale: dimmed ? Theme.dimScale : (lit ? Theme.hoverScale : 1)
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
            Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

            RectangularShadow {
                anchors.fill: parent
                radius: height / 2
                blur: (island.lit ? Theme.glowBlurOpen : Theme.glowBlur) * 0.6 * Theme.glow
                color: Qt.alpha(Theme.ember, (island.lit ? Theme.glowAlphaOpen : Theme.glowAlpha) * Theme.glow)
            }
            EmberSurface {
                anchors.fill: parent
                radius: height / 2
                base: Theme.islandFill
                topLight: true
                edge: Theme.edgeLightIsland
                lit: island.lit
                lightX: width / 2
                lightY: 0
            }

            // Left: workspaces, the active one stretched.
            Row {
                visible: island.index === 0
                anchors.centerIn: parent
                spacing: Theme.spaceXs / 2
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: index === 0 ? Theme.workspaceActiveWidth * 0.6 : Theme.spaceXs
                        height: Theme.spaceXs
                        radius: height / 2
                        color: index === 0 ? Theme.ember : Theme.islandMuted
                    }
                }
            }
            // Centre: the ember and the clock.
            Row {
                visible: island.index === 1
                anchors.centerIn: parent
                spacing: Theme.spaceXs
                EmberDot {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceXs
                    height: Theme.spaceXs
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(new Date(), Settings.conf.shell.clock12h ? "h:mm" : "HH:mm")
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textLabel
                    color: Theme.islandText
                }
            }
            // Right: status glyphs.
            Text {
                visible: island.index === 2
                anchors.centerIn: parent
                text: "󰖩  󰂯  󰁹"
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textLabel
                color: Theme.islandText
            }
        }
    }
}
