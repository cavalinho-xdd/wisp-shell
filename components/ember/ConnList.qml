import QtQuick
import "../../core"

// List view for connections (networks, devices): back button, title and rows.
// `rows` is [{ icon, name, sub, active, enabled }]; a click on a row emits
// picked(index).
Item {
    id: root

    property bool lit: false
    // Set once the island has settled; switching views then skips the stagger.
    property bool quick: false
    property string title: ""
    property string emptyText: ""
    property var rows: []

    signal back()
    signal picked(int index)

    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.spaceMd * 2 + Theme.controlSize + Theme.spaceSm + Theme.listRow * Theme.listRows

    Kindle {
        quick: root.quick
        id: head
        lit: root.lit
        index: 0
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        height: Theme.controlSize

        Item {
            width: head.width
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
        }
    }

    Kindle {
        quick: root.quick
        id: body
        lit: root.lit
        index: 1
        x: Theme.spaceMd
        y: head.y + head.height + Theme.spaceSm
        width: head.width
        height: Theme.listRow * Theme.listRows

        Item {
            width: body.width
            height: Theme.listRow * Theme.listRows

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: root.rows
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property var modelData
                    width: list.width
                    height: Theme.listRow
                    radius: Theme.radiusRow
                    opacity: row.modelData.enabled ? 1 : 0.5
                    color: rowMouse.containsMouse && row.modelData.enabled ? Theme.ash : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        id: glyph
                        x: Theme.spaceSm
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.controlSize
                        horizontalAlignment: Text.AlignHCenter
                        text: row.modelData.icon
                        color: row.modelData.active ? Theme.ember : Theme.islandMuted
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.textTitle
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: glyph.x + glyph.width + Theme.spaceSm
                        width: parent.width - x - Theme.spaceSm
                        Text {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: Theme.islandText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textBody
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.sub
                            elide: Text.ElideRight
                            color: Theme.islandMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                        }
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: row.modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picked(row.index)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.rows.length === 0
                text: root.emptyText
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textBody
            }
        }
    }
}
