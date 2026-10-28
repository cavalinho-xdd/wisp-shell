pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../core"

// Welcome wizard: what each island does and the shortcuts worth knowing.
// Hovering a card lights its island in the preview above. Gestures here must
// match components/ember/EmberIslands.qml and WorkspacesView.qml.
CfgPage {
    id: step

    property string wallpaper: ""
    property int hovered: -1

    readonly property var islands: [
        { title: "Workspaces", lines: ["Click a dot to switch", "Scroll to step through them"] },
        { title: "Activity", lines: ["Click for media, a call or system load", "Scroll for volume, middle click to pause", "Notifications flare here"] },
        { title: "Status", lines: ["Click for the control centre", "Wi-Fi, Bluetooth, sound, calendar, power"] }
    ]
    readonly property var keys: [
        { key: "Super + Space", desc: "Launcher" },
        { key: "Super + I", desc: "Settings" },
        { key: "Super + Shift + W", desc: "Wallpaper" },
        { key: "Super + Shift + S", desc: "Screenshot" }
    ]

    WelcomeIslandsPreview {
        Layout.fillWidth: true
        wallpaper: step.wallpaper
        highlight: step.hovered
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        Repeater {
            model: step.islands
            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: cardCol.implicitHeight + 2 * Theme.spaceMd
                radius: Theme.radiusCard
                color: hover.hovered ? Theme.ashHi : Theme.ash
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                HoverHandler {
                    id: hover
                    onHoveredChanged: step.hovered = hovered ? card.index : (step.hovered === card.index ? -1 : step.hovered)
                }

                Column {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMd
                    spacing: Theme.spaceXs

                    Text {
                        text: card.modelData.title
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textBody
                        font.weight: Font.DemiBold
                        color: hover.hovered ? Theme.ember : Theme.islandText
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    }
                    Repeater {
                        model: card.modelData.lines
                        delegate: Text {
                            required property string modelData
                            width: cardCol.width
                            text: modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                            color: Theme.islandMuted
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    CfgNotice {
        text: "Drag an island to move it; it snaps to the nearest layout. Esc or a click outside closes an open one."
    }

    CfgSection {
        title: "Shortcuts"

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spaceSm
            Layout.rightMargin: Theme.spaceSm
            Layout.bottomMargin: Theme.spaceXs
            columns: 2
            columnSpacing: Theme.spaceMd
            rowSpacing: Theme.spaceXs

            Repeater {
                model: step.keys
                delegate: RowLayout {
                    id: keyRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Theme.listRow - Theme.spaceSm
                    spacing: Theme.spaceSm
                    Text {
                        Layout.fillWidth: true
                        text: keyRow.modelData.desc
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textCaption
                        color: Theme.islandText
                    }
                    Rectangle {
                        Layout.preferredWidth: keyText.implicitWidth + 2 * Theme.spaceSm
                        Layout.preferredHeight: keyText.implicitHeight + Theme.spaceXs
                        radius: Theme.spaceXs
                        color: Theme.smoke
                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: keyRow.modelData.key
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textMonoSmall
                            color: Theme.ember
                        }
                    }
                }
            }
        }
    }
}
