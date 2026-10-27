pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../core"

// Settings card: a small uppercase title over its rows, with a hairline
// between rows. `icon` is kept for the pages that still pass one, but not
// drawn — an accent glyph on every heading competed with the rows.
Rectangle {
    id: root
    property string title: ""
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    implicitHeight: sectionContent.implicitHeight + Theme.spaceSm + Theme.spaceXs
    radius: Theme.radiusCard
    color: Theme.ash

    // Title and rows share one column: the title is its first child, the
    // rows are appended after it through the default property.
    ColumnLayout {
        id: sectionContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.spaceSm
        anchors.leftMargin: Theme.spaceXs
        anchors.rightMargin: Theme.spaceXs
        spacing: 0

        Text {
            Layout.leftMargin: Theme.spaceSm + 2
            Layout.bottomMargin: 2
            visible: root.title !== ""
            text: root.title.toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textLabel
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            color: Theme.islandMuted
        }
    }

    // Hairlines above every visible row except the first. Drawn over the
    // column rather than by the rows, so any row type (and the pages' own
    // RowLayouts) gets one. Zero-height children are Repeaters.
    Repeater {
        model: sectionContent.children.length
        delegate: Rectangle {
            required property int index
            readonly property Item row: sectionContent.children[index]
            readonly property bool shown: {
                if (index < 1 || !row.visible || row.height <= 0)
                    return false;
                for (let i = 1; i < index; i++) {
                    const prev = sectionContent.children[i];
                    if (prev.visible && prev.height > 0)
                        return true;
                }
                return false;
            }
            visible: shown
            x: sectionContent.x + Theme.spaceSm + 2
            y: sectionContent.y + row.y
            width: sectionContent.width - 2 * (Theme.spaceSm + 2)
            height: 1
            color: Theme.edgeLight
        }
    }
}
