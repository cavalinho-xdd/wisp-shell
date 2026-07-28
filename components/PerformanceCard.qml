import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

Rectangle {
    id: root
    radius: 20
    color: Theme.surface
    clip: true

    property bool active: true
    // The zeroed sysData below is a placeholder shape for bindings to read
    // before the first real snapshot lands — it must never actually be
    // drawn (reads as "0.0 GB / 0% / 0%", indistinguishable from real idle
    // values). Rings + process list stay hidden behind a loading state
    // until hasData flips, then crossfade in.
    property bool hasData: false

    property var sysData: ({
        ram: { used: "0.0 GB", free: "0.0 GB", total: "0.0 GB" },
        gpu: { load: "0%" },
        cpu: { load: "0%" }
    })

    Process {
        id: sysmonProc
        command: ["bash", String(Qt.resolvedUrl("../scripts/sysmon_snapshot.sh")).replace("file://", "")]
        running: root.active
        stdout: SplitParser {
            onRead: message => {
                try {
                    if (message.trim() !== "") {
                        root.sysData = JSON.parse(message);
                        root.hasData = true;
                    }
                } catch(e) {}
            }
        }
    }

    // Loading state — shown until the first real snapshot arrives, then
    // crossfades out. Pulsing dots instead of misleadingly-real-looking
    // zero values.
    Row {
        anchors.centerIn: parent
        spacing: 8
        opacity: root.hasData ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 250 } }

        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                width: 8; height: 8; radius: 4
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    running: !root.hasData
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 150 }
                    NumberAnimation { to: 0.25; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        opacity: root.hasData ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        contentWidth: width
        contentHeight: contentCol.implicitHeight + 48
        clip: true
        interactive: contentHeight > height

        ColumnLayout {
            id: contentCol
            width: parent.width - 48
            x: 24; y: 24
            spacing: 24

            // Rings Row
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                spacing: 24

                CircularProgress {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: root.sysData.ram ? parseFloat(root.sysData.ram.value) : 0.0
                    title: root.sysData.ram ? root.sysData.ram.used : "0.0 GB"
                    subtitle: "RAM"
                    icon: "󰘚"
                    color: Theme.blue
                }

                CircularProgress {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: root.sysData.gpu ? parseFloat(root.sysData.gpu.value) : 0.0
                    title: root.sysData.gpu ? root.sysData.gpu.load : "0%"
                    subtitle: "GPU"
                    icon: "󰢮"
                    color: Theme.green
                }

                CircularProgress {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: root.sysData.cpu ? parseFloat(root.sysData.cpu.value) : 0.0
                    title: root.sysData.cpu ? root.sysData.cpu.load : "0%"
                    subtitle: "CPU"
                    icon: "󰻠"
                    color: Theme.peach
                }
            }

            // Top Processes
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: topProcsCol.implicitHeight + 32
                color: Theme.surface0
                radius: 16
                
                ColumnLayout {
                    id: topProcsCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            font.family: Theme.fontFamily; text: "Top Processes"; font.bold: true; color: Theme.text; font.pixelSize: 14; Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontFamily; text: "CPU"; font.bold: true; color: Theme.subtext0; font.pixelSize: 12; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight }
                        Text {
                            font.family: Theme.fontFamily; text: "MEM"; font.bold: true; color: Theme.subtext0; font.pixelSize: 12; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight }
                    }
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }
                    
                    Column {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: root.sysData.top || []
                            delegate: Item {
                                width: parent.width
                                height: 24

                                // Faint bar behind the row — width tracks CPU load
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height
                                    width: parent.width * Math.min(parseFloat(modelData.cpu) / 100, 1)
                                    radius: 6
                                    color: Theme.primary
                                    opacity: 0.08
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text {
                                        font.family: Theme.fontFamily;
                                        text: modelData.name
                                        color: Theme.text
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        font.family: Theme.fontFamily;
                                        text: modelData.cpu
                                        color: Theme.primary
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Text {
                                        font.family: Theme.fontFamily;
                                        text: modelData.mem
                                        color: Theme.subtext0
                                        font.pixelSize: 13
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
