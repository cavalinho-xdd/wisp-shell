import QtQuick
import QtQuick.Shapes
import "../../core"

// Detail view of a connection (Wi-Fi, Bluetooth): a quiet orb with what is
// connected, three facts and a button to the list. The ring breathes while it
// is on; switched off, the whole view goes grey.
Item {
    id: root

    property bool lit: false
    property string title: ""
    property bool on: false
    property string icon: ""
    property string name: ""
    property string status: ""
    // [{ label, value }] x 3
    property var facts: []
    property string moreLabel: ""
    property int moreCount: 0

    signal back()
    signal switched(bool on)
    signal more()

    implicitWidth: Theme.ccWidth
    implicitHeight: column.implicitHeight + Theme.spaceMd * 2

    Column {
        id: column
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        spacing: Theme.spaceSm

        Kindle {
            lit: root.lit
            index: 0
            width: column.width
            height: Theme.controlSize

            Item {
                width: column.width
                height: Theme.controlSize
                EmberButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "󰁍"
                    label: "Back"
                    onClicked: root.back()
                }
                Text {
                    anchors.centerIn: parent
                    text: root.title
                    color: Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textBody
                    font.weight: Font.DemiBold
                }
                EmberSwitch {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spaceXs
                    anchors.verticalCenter: parent.verticalCenter
                    label: root.title
                    checked: root.on
                    onToggled: v => root.switched(v)
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 1
            width: column.width
            height: Theme.orbSize + Theme.spaceSm

            Item {
                id: orb
                width: column.width
                height: Theme.orbSize + Theme.spaceSm

                Rectangle {
                    id: ring
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.spaceXs
                    width: Theme.orbSize
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.on ? Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, 0.16)) : Theme.ashHi
                    Behavior on border.color { ColorAnimation { duration: Theme.motionMorph } }

                    // Breathes with the ember: slow, small, only while on and open.
                    SequentialAnimation on opacity {
                        running: root.lit && root.on && !Theme.reduceMotion
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.55; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    id: disc
                    anchors.centerIn: ring
                    width: ring.width - Theme.spaceLg * 2.6
                    height: width
                    radius: width / 2
                    color: Theme.smoke

                    Shape {
                        anchors.fill: parent
                        opacity: root.on ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.motionMorph } }
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: disc.width / 2; centerY: disc.height * 0.38
                                focalX: centerX; focalY: centerY
                                centerRadius: disc.width * 0.62
                                GradientStop { position: 0; color: Qt.alpha(Theme.ember, 0.07 * Theme.glow) }
                                GradientStop { position: 1; color: "transparent" }
                            }
                            PathAngleArc {
                                centerX: disc.width / 2; centerY: disc.height / 2
                                radiusX: disc.width / 2; radiusY: disc.height / 2
                                startAngle: 0; sweepAngle: 360
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Theme.spaceMd * 2
                        spacing: Theme.spaceXs / 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.icon
                            color: root.on ? Qt.tint(Theme.islandText, Qt.alpha(Theme.ember, 0.7)) : Theme.islandMuted
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.textTitle * 2
                            Behavior on color { ColorAnimation { duration: Theme.motionMorph } }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.name
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: Theme.islandText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textBody
                            font.weight: Font.DemiBold
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.status
                            elide: Text.ElideRight
                            color: Theme.islandMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                        }
                    }
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 2
            width: column.width

            Row {
                id: factsRow
                spacing: Theme.spaceSm
                opacity: root.on ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: Theme.motionMorph } }

                Repeater {
                    model: root.facts.length
                    Rectangle {
                        id: fact
                        required property int index
                        width: (root.width - Theme.spaceMd * 2 - Theme.spaceSm * 2) / 3
                        height: Theme.controlSizeBig + Theme.spaceXs
                        radius: Theme.radiusRow
                        color: Theme.ash
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.spaceSm
                            width: parent.width - Theme.spaceSm * 2
                            Text {
                                width: parent.width
                                text: root.facts[fact.index].label
                                elide: Text.ElideRight
                                color: Theme.islandMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.textLabel
                                font.letterSpacing: Theme.textLabel * 0.08
                                font.capitalization: Font.AllUppercase
                            }
                            Text {
                                width: parent.width
                                text: root.facts[fact.index].value
                                elide: Text.ElideRight
                                color: Theme.islandText
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.textMono
                            }
                        }
                    }
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 3
            width: column.width
            height: Theme.controlSizeBig

            Rectangle {
                width: column.width
                height: Theme.controlSizeBig
                radius: Theme.radiusTile
                color: moreMouse.containsMouse ? Theme.ashHi : Theme.ash
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                activeFocusOnTab: true
                Keys.onReturnPressed: root.more()
                Accessible.role: Accessible.Button
                Accessible.name: root.moreLabel

                Text {
                    x: Theme.spaceMd
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.moreLabel
                    color: Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textBody
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: chevron.left
                    anchors.rightMargin: Theme.spaceXs
                    text: root.moreCount
                    color: Theme.islandMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textMonoSmall
                }
                Text {
                    id: chevron
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spaceSm
                    text: "󰅂"
                    color: Theme.islandMuted
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textBody
                }
                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.more()
                }
            }
        }
    }
}
