import QtQuick
import Quickshell.Services.Pipewire
import "../../core"

// Sound detail: where it plays and records (the default device is the
// ember one), and a volume slider for each app that makes sound.
Item {
    id: root

    property bool lit: false

    readonly property int maxDevices: 3
    readonly property int maxApps: 4
    readonly property var outputs: Audio.outputDevices
    readonly property var inputs: Audio.inputDevices
    readonly property var apps: Audio.outputAppNodes

    signal back()

    function appName(node) {
        const p = node.properties;
        return p["application.name"] || node.description || node.name;
    }
    function deviceName(node) {
        return node.nickname || node.description || node.name;
    }

    implicitWidth: Theme.ccWidth
    implicitHeight: column.implicitHeight + Theme.spaceMd * 2

    // Device and stream nodes only expose their volume once tracked.
    PwObjectTracker { objects: root.lit ? root.apps.concat(root.outputs, root.inputs) : [] }

    component Heading: Text {
        color: Theme.islandMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textLabel
        font.letterSpacing: Theme.textLabel * 0.08
        font.capitalization: Font.AllUppercase
        topPadding: Theme.spaceXs
    }

    Column {
        id: column
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        spacing: Theme.spaceXs

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
                    text: "Sound"
                    color: Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textBody
                    font.weight: Font.DemiBold
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 1
            width: column.width
            Column {
                width: column.width
                Heading { text: "Output" }
                Repeater {
                    model: Math.min(root.outputs.length, root.maxDevices)
                    SoundDevice {
                        id: outRow
                        required property int index
                        width: column.width
                        icon: /head/i.test(root.outputs[index].name) ? "󰋋" : "󰓃"
                        name: root.deviceName(root.outputs[index])
                        active: root.outputs[index] === Audio.sink
                        onClicked: Audio.setDefaultSink(root.outputs[index])
                    }
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 2
            width: column.width
            Column {
                width: column.width
                Heading { text: "Input" }
                Repeater {
                    model: Math.min(root.inputs.length, root.maxDevices)
                    SoundDevice {
                        id: inRow
                        required property int index
                        width: column.width
                        icon: "󰍬"
                        name: root.deviceName(root.inputs[index])
                        active: root.inputs[index] === Audio.source
                        onClicked: Audio.setDefaultSource(root.inputs[index])
                    }
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 3
            width: column.width
            Column {
                width: column.width
                Heading { text: "Apps" }
                Text {
                    visible: root.apps.length === 0
                    x: Theme.spaceXs
                    text: "Nothing is playing"
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textBody
                    height: Theme.listRow
                    verticalAlignment: Text.AlignVCenter
                }
                Repeater {
                    model: Math.min(root.apps.length, root.maxApps)
                    SoundApp {
                        id: appRow
                        required property int index
                        width: column.width
                        name: root.appName(root.apps[index])
                        value: root.apps[index].audio.volume
                        muted: root.apps[index].audio.muted
                        onMoved: v => root.apps[index].audio.volume = v
                        onMuteClicked: root.apps[index].audio.muted = !root.apps[index].audio.muted
                    }
                }
            }
        }
    }
}
