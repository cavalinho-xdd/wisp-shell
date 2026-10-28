pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../core"
import "ember"

// Welcome wizard step 1 — the ember, a greeting and what the next steps set
// up. The list is deliberate (iNiR's note on it): users see the value before
// they see the Skip button. Rows kindle in one after another.
//
// ⚠ `Layout.fillWidth: true` DOES NOT WORK on a ColumnLayout nested inside
// another ColumnLayout or a StackLayout — it is silently ignored and the
// column collapses to its own implicit width. Binding preferredWidth to the
// parent's width works, and so does anchoring inside a sized Item.
ColumnLayout {
    id: step
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: Theme.spaceMd

    property bool lit: false
    Component.onCompleted: lit = true

    readonly property var rows: [
        { label: "Colour", desc: "The ember, taken from your wallpaper" },
        { label: "Wallpaper", desc: "Where your wallpapers live" },
        { label: "Islands", desc: "Material, glow, layout and motion" },
        { label: "Tour", desc: "What each island does, and the shortcuts" },
        { label: "Login screen", desc: "An SDDM theme, if you want one" },
        { label: "Ready", desc: "A quick system check and you're done" }
    ]

    Item { Layout.fillHeight: true }

    EmberDot {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Theme.controlSize - Theme.spaceSm
        Layout.preferredHeight: Theme.controlSize - Theme.spaceSm
        Layout.bottomMargin: Theme.spaceSm
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Welcome to Wisp"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textHeading + Theme.spaceSm
        font.weight: Font.DemiBold
        color: Theme.islandText
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 460
        text: "Let's set up your desktop. A minute now, or skip it — everything here lives in Settings too."
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textBody
        color: Theme.islandMuted
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spaceSm
        Layout.preferredWidth: 440
        Layout.preferredHeight: list.implicitHeight

        Column {
            id: list
            width: parent.width
            spacing: Theme.spaceXs

            Repeater {
                model: step.rows
                // Kindle has an `index` of its own (its stagger slot), which
                // would shadow the Repeater's; the wrapper hands it over.
                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    width: list.width
                    height: row.implicitHeight

                Kindle {
                    id: row
                    width: slot.width
                    lit: step.lit
                    index: slot.index

                    RowLayout {
                        width: row.width
                        spacing: Theme.spaceMd

                        Text {
                            Layout.preferredWidth: Theme.spaceLg
                            text: (slot.index + 1).toString()
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textMonoSmall
                            color: Theme.ember
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.preferredWidth: 110
                            text: slot.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textBody
                            font.weight: Font.Medium
                            color: Theme.islandText
                        }
                        Text {
                            Layout.fillWidth: true
                            text: slot.modelData.desc
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                            color: Theme.islandMuted
                            elide: Text.ElideRight
                        }
                    }
                }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
