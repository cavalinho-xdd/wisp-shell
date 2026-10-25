import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../core"

// Open centre island as launcher: a search field and the five best results.
// Up/Down move, Enter runs, Esc closes. Fixed height, so the island does not
// jump while the results change.
Item {
    id: root

    property bool lit: false
        property int current: 0
    // Centre of the search glyph (the ember here), for the island's inner light.
    readonly property point emberPoint: Qt.point(
        fieldBlock.x + glyph.x + glyph.width / 2, fieldBlock.y + fieldBlock.height / 2)

    signal dismiss()

    implicitWidth: Theme.launcherWidth
    implicitHeight: Theme.spaceMd * 2 + Theme.launcherField + Theme.spaceSm + finder.maxResults * Theme.launcherRow

    LauncherSearch {
        id: finder
        query: input.text
        onLaunched: root.dismiss()
    }

    onLitChanged: {
        if (lit) {
            input.text = "";
            input.forceActiveFocus();
        }
    }

    Kindle {
        id: fieldBlock
        lit: root.lit
        index: 0
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        height: Theme.launcherField

        Rectangle {
            width: fieldBlock.width
            height: fieldBlock.height
            radius: Theme.radiusRow
            color: Theme.ash

            Text {
                id: glyph
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.spaceMd
                text: "󰍉"
                color: Theme.ember
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textTitle
            }

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                x: glyph.x + glyph.width + Theme.spaceSm
                width: parent.width - x - Theme.spaceMd
                clip: true
                color: Theme.islandText
                selectionColor: Theme.ember
                selectedTextColor: Theme.smoke
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textTitle
                cursorDelegate: Rectangle {
                    width: 2
                    radius: 1
                    color: Theme.ember
                }

                onTextChanged: root.current = 0

                Keys.onEscapePressed: root.dismiss()
                Keys.onDownPressed: root.current = Math.min(root.current + 1, finder.results.length - 1)
                Keys.onUpPressed: root.current = Math.max(root.current - 1, 0)
                Keys.onReturnPressed: finder.launch(finder.results[root.current])
                Keys.onEnterPressed: finder.launch(finder.results[root.current])

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: "Search apps    = calc   ? web   $ shell"
                    elide: Text.ElideRight
                    width: parent.width
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }
            }
        }
    }

    Kindle {
        id: listBlock
        lit: root.lit
        index: 1
        x: Theme.spaceMd
        y: Theme.spaceMd + Theme.launcherField + Theme.spaceSm
        width: root.width - Theme.spaceMd * 2
        height: finder.maxResults * Theme.launcherRow

        Item {
            width: listBlock.width
            height: listBlock.height

            Rectangle {
                visible: finder.results.length > 0
                width: parent.width
                height: Theme.launcherRow
                radius: Theme.radiusRow
                color: Theme.ashHi
                y: root.current * Theme.launcherRow
                Behavior on y { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
            }

            Text {
                anchors.centerIn: parent
                visible: input.text.trim() !== "" && finder.results.length === 0
                text: "No results"
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textBody
            }

            // Index access, not modelData: inside the per-screen Variants
            // modelData would resolve to the screen.
            Repeater {
                model: finder.maxResults

                LauncherRow {
                    required property int index
                    y: index * Theme.launcherRow
                    width: listBlock.width
                    entry: finder.results[index] ?? null
                    selected: root.current === index
                    onHovered: root.current = index
                    onActivated: finder.launch(entry)
                }
            }
        }
    }
}
