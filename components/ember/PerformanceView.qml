import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

// Open centre island while nothing plays: CPU, RAM, GPU and disk as four
// readings with a thin bar, and the network speed. The numbers come from
// scripts/sysmon_snapshot.sh, which only runs while this view is lit.
Item {
    id: root

    property bool lit: false

    property bool hasData: false
    property var snap: ({})

    readonly property real cellWidth: (width - Theme.spaceLg * 2 - Theme.spaceMd * 3) / 4

    implicitWidth: Theme.mediaWidth
    implicitHeight: Theme.spaceLg * 2 + header.implicitHeight + Theme.spaceMd + row.implicitHeight

    Process {
        command: ["bash", Quickshell.shellPath("scripts/sysmon_snapshot.sh")]
        running: root.lit
        stdout: SplitParser {
            onRead: message => {
                try {
                    if (message.trim() !== "") {
                        root.snap = JSON.parse(message);
                        root.hasData = true;
                    }
                } catch (e) {}
            }
        }
    }

    Kindle {
        id: headerBlock
        lit: root.lit
        index: 0
        x: Theme.spaceLg
        y: Theme.spaceLg
        width: root.width - Theme.spaceLg * 2

        Item {
            id: header
            width: headerBlock.width
            implicitHeight: label.implicitHeight

            Text {
                id: label
                text: "System"
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textLabel
                font.weight: Font.Medium
                font.letterSpacing: Theme.textLabel * 0.08
                font.capitalization: Font.AllUppercase
                opacity: 0.7
            }
            Text {
                anchors.right: parent.right
                visible: root.hasData && !!root.snap.net
                text: root.snap.net ? "↓ " + root.snap.net.rx + "   ↑ " + root.snap.net.tx : ""
                color: Theme.islandMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.textMonoSmall
            }
        }
    }

    Row {
        id: row
        x: Theme.spaceLg
        y: Theme.spaceLg + header.implicitHeight + Theme.spaceMd
        spacing: Theme.spaceMd

        PerfCell {
            lit: root.lit
            index: 1
            width: root.cellWidth
            ready: root.hasData
            label: "CPU"
            value: root.snap.cpu ? root.snap.cpu.value : 0
            text: root.snap.cpu ? root.snap.cpu.load : ""
        }
        PerfCell {
            lit: root.lit
            index: 2
            width: root.cellWidth
            ready: root.hasData
            label: "RAM"
            value: root.snap.ram ? root.snap.ram.value : 0
            text: root.snap.ram ? Math.round(root.snap.ram.value * 100) + "%" : ""
            sub: root.snap.ram ? root.snap.ram.used.replace(" GB", "") + " / " + root.snap.ram.total : ""
        }
        PerfCell {
            lit: root.lit
            index: 3
            width: root.cellWidth
            ready: root.hasData
            label: "GPU"
            value: root.snap.gpu ? root.snap.gpu.value : 0
            text: root.snap.gpu ? root.snap.gpu.load : ""
        }
        PerfCell {
            lit: root.lit
            index: 4
            width: root.cellWidth
            ready: root.hasData
            label: "Disk"
            value: root.snap.disk ? root.snap.disk.value : 0
            text: root.snap.disk ? Math.round(root.snap.disk.value * 100) + "%" : ""
            sub: root.snap.disk ? root.snap.disk.used + " / " + root.snap.disk.total : ""
        }
    }
}
