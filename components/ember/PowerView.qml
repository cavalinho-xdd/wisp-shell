import QtQuick
import Quickshell
import "../../core"

// Lock, log out, restart, shut down. Lock acts at once; the others ask
// for a second click on the same row (it times out), so a stray click
// can't end the session.
Item {
    id: root

    property bool lit: false
    // Set once the island has settled; switching views then skips the stagger.
    property bool quick: false
    // Index of the row waiting for its confirming click, -1 for none.
    property int armed: -1

    readonly property var actions: [
        { label: "Lock", icon: "󰌾", confirm: false, cmd: ["/usr/bin/qs", "-p", Settings.lockAppPath] },
        { label: "Log out", icon: "󰍃", confirm: true, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { label: "Restart", icon: "󰑐", confirm: true, cmd: ["bash", "-c", "systemctl reboot || loginctl reboot"] },
        { label: "Shut down", icon: "󰐥", confirm: true, cmd: ["bash", "-c", "systemctl poweroff || loginctl poweroff"] }
    ]

    signal back()
    signal done()

    function pick(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) {
            armed = i;
            disarm.restart();
            return;
        }
        armed = -1;
        Quickshell.execDetached(a.cmd);
        done();
    }

    onLitChanged: if (!lit) armed = -1

    implicitWidth: Theme.ccWidth
    implicitHeight: column.implicitHeight + Theme.spaceMd * 2

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = -1
    }

    Column {
        id: column
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        spacing: Theme.spaceXs

        Kindle {
            quick: root.quick
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
                    text: "Power"
                    color: Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textBody
                    font.weight: Font.DemiBold
                }
            }
        }

        Repeater {
            model: root.actions.length
            Kindle {
                quick: root.quick
                id: kin
                required property int modelData
                readonly property int slot: modelData
                lit: root.lit
                index: slot + 1
                width: column.width
                height: Theme.listRow
                Rectangle {
                    id: row
                    readonly property bool armed: root.armed === kin.slot
                    width: column.width
                    height: Theme.listRow
                    radius: Theme.radiusRow
                    color: armed ? Qt.tint(Theme.ash, Qt.alpha(Theme.ember, 0.18)) : (mouse.containsMouse ? Theme.hoverRow : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.pick(kin.slot)
                    Accessible.role: Accessible.Button
                    Accessible.name: root.actions[kin.slot].label

                    Text {
                        id: glyph
                        x: Theme.spaceSm
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.controlSize
                        horizontalAlignment: Text.AlignHCenter
                        text: root.actions[kin.slot].icon
                        color: row.armed ? Theme.ember : Theme.islandText
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.textTitle
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: glyph.x + glyph.width + Theme.spaceSm
                        text: row.armed ? root.actions[kin.slot].label + " — click again to confirm" : root.actions[kin.slot].label
                        color: Theme.islandText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textBody
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(kin.slot)
                    }
                }
            }
        }
    }
}
