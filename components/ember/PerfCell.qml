import QtQuick
import "../../core"

// One reading in PerformanceView: label, value, a thin bar that turns ember
// when it runs hot, and a line of detail. Kindles in like any open-island block.
Kindle {
    id: cell

    property string label: ""
    property string text: ""
    property string sub: ""
    // 0..1; an unknown reading shows a dash and an empty bar.
    property real value: 0
    property bool ready: false
    readonly property bool hot: value >= Theme.perfHot

    Column {
        width: cell.width
        spacing: Theme.spaceXs

        Text {
            text: cell.label
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textLabel
            font.weight: Font.Medium
            font.letterSpacing: Theme.textLabel * 0.08
            font.capitalization: Font.AllUppercase
            opacity: 0.7
        }
        Text {
            text: cell.ready ? cell.text : "–"
            color: Theme.islandText
            font.family: Theme.fontMono
            font.pixelSize: Theme.textTitle
            font.weight: Font.Medium
        }
        Item {
            width: cell.width
            height: Theme.progressHeight
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.ashHi
            }
            Rectangle {
                width: parent.width * Math.min(1, cell.ready ? cell.value : 0)
                height: parent.height
                radius: height / 2
                color: cell.hot ? Theme.ember : Theme.islandText
                Behavior on width { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            width: cell.width
            text: cell.ready ? cell.sub : ""
            elide: Text.ElideRight
            color: Theme.islandMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.textMonoSmall
        }
    }
}
