import QtQuick
import QtQuick.Layouts
import "../core"

// Welcome wizard step 1 — hero + "what you'll set up" preview.
// The preview list is deliberate: iNiR's own comment on it is that users see
// the VALUE before they see the Skip button. Four rows, matching the four
// steps that follow.
ColumnLayout {
    // ⚠ `Layout.fillWidth: true` DOES NOT WORK on a ColumnLayout nested inside
    // another ColumnLayout or a StackLayout — it is silently ignored and the
    // column collapses to its own implicit width (here the 480px preview card),
    // flush left, so every `Layout.alignment: AlignHCenter` below then centres
    // against 480px instead of against the card. Verified with an isolated
    // probe: in one parent ColumnLayout of width 560, a nested ColumnLayout
    // with fillWidth measured 60px wide (its widest child) while a sibling
    // RowLayout with the identical fillWidth measured the full 560 — the
    // property works for RowLayout and is ignored for ColumnLayout. Adding
    // Layout.minimumWidth does not help either. Binding preferredWidth to the
    // parent layout's width does, and so does wrapping in a plain Item and
    // anchoring inside it.
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 14

    Item { Layout.fillHeight: true }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 76; height: 76; radius: 26
        // Primary-tinted fill rather than a surface fill inside a 2px primary
        // ring — the accent reads as the badge itself instead of as an outline
        // drawn around a neutral box.
        color: Qt.alpha(Theme.primary, 0.16)

        Text {
            anchors.centerIn: parent
            text: "󱐋"
            font.family: Theme.fontIcon
            font.pixelSize: 38
            color: Theme.primary
        }

        // Slow breathing glow — the pill's own "alive" idiom, so the first
        // thing a new user sees already moves the way the shell does.
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: 1.06; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        font.family: Theme.fontFamily
        text: "Welcome to Wisp"
        font.pixelSize: 30
        font.bold: true
        color: Theme.text
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 480
        font.family: Theme.fontFamily
        text: "Let's set up your desktop. A minute now, or skip it — everything here lives in Settings too."
        font.pixelSize: 13
        color: Theme.subtext0
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    // No container card. This is a list of four rows, and wrapping it in a
    // bordered box inside the wizard's own card is card-in-card nesting for no
    // gain — the rows are already grouped by proximity. Whitespace is the first
    // rung of the separation ladder and it is sufficient here.
    // Item wrapper, not a bare ColumnLayout with Layout.alignment: a nested
    // ColumnLayout ignores layout sizing from its parent (the same trap
    // documented at the top of this file), so aligning it centre had no effect
    // and the list ran the full width of the card while the heading above it
    // stayed centred. Anchoring inside a sized Item is the verified fix.
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 14
        Layout.preferredWidth: 420
        Layout.preferredHeight: previewCol.implicitHeight

    ColumnLayout {
        id: previewCol
        anchors.fill: parent
        spacing: 12

        Repeater {
            model: [
                { icon: "󰸌", label: "Appearance", desc: "Colors from your wallpaper, dark or light" },
                { icon: "󰸉", label: "Wallpaper", desc: "Where your wallpapers live" },
                { icon: "󰍜", label: "Shell", desc: "Clock, workspaces, which monitor" },
                { icon: "󰄬", label: "Ready", desc: "A quick system check and you're done" }
            ]
            delegate: RowLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 14

                // Staggered fade-in, one beat per row
                opacity: 0
                SequentialAnimation on opacity {
                    running: true
                    PauseAnimation { duration: 120 + index * 70 }
                    NumberAnimation { to: 1; duration: 240 }
                }

                // Tinted glyph tile instead of a bare icon — gives the row a
                // left anchor now that there is no container box around the
                // list, without reintroducing an outline.
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 10
                    color: Qt.alpha(Theme.primary, 0.14)
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: Theme.fontIcon
                        font.pixelSize: 15
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        font.family: Theme.fontFamily
                        text: modelData.label
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        text: modelData.desc
                        font.pixelSize: 11
                        color: Theme.subtext0
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
    }

    Item { Layout.fillHeight: true }
}
