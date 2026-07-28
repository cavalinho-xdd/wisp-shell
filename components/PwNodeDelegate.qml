import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.Pipewire
import "../core"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 80
    radius: 16
    color: Theme.surface
    
    required property var modelData
    property bool isSink: true
    property bool isApp: false
    
    // Determine if this is the active default hardware device
    property bool isActiveDefault: !isApp && ((isSink && Audio.sink && Audio.sink.id === modelData.id) || (!isSink && Audio.source && Audio.source.id === modelData.id))
    
    border.color: isActiveDefault ? Theme.primary
        : (rowHover.hovered ? Theme.outline : Theme.surface0)
    border.width: isActiveDefault ? 2 : 1

    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    // Whole-row hover invite — every other interactive surface in the shell
    // reacts to the pointer (CLAUDE.md UI rule); these mixer rows were the
    // one place that sat completely inert.
    HoverHandler { id: rowHover }
    scale: rowHover.hovered ? 1.012 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring; easing.overshoot: 1.4 } }

    // Two independent opacity influences, kept as separate factors rather than
    // two `opacity:` assignments (a second assignment would silently replace
    // the first binding, so the muted dim would be lost the moment the intro
    // animation touched opacity):
    //   introOpacity — one-shot entry fade
    //   muted dim    — live, must keep tracking nodeMuted forever after
    property real introOpacity: 0
    opacity: introOpacity * (nodeMuted ? 0.55 : 1.0)
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    // Entry rise, matching the collapsed bar's dots and the power-menu cascade.
    Component.onCompleted: entry.start()
    ParallelAnimation {
        id: entry
        NumberAnimation { target: root; property: "introOpacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: entryShift; property: "y"; from: 12; to: 0; duration: 380; easing.type: Easing.OutQuint }
    }
    transform: Translate { id: entryShift }

    // Auto-updating local properties from the Pipewire node
    property real nodeVolume: (modelData && modelData.audio) ? modelData.audio.volume : 0.0
    property bool nodeMuted: (modelData && modelData.audio) ? !!modelData.audio.muted : false

    PwObjectTracker {
        objects: modelData ? [modelData] : []
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Icon / Select button
        Rectangle {
            id: iconChip
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: 24
            // Hardware rows are click-to-make-default, so the chip previews
            // that action on hover; app rows aren't selectable, so they stay put.
            readonly property bool selectable: !root.isApp && !!root.modelData
            color: root.isActiveDefault ? Theme.primary
                : (selectable && chipMa.containsMouse ? Theme.surface0 : Theme.background)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            scale: selectable ? (chipMa.pressed ? 0.9 : (chipMa.containsMouse ? 1.08 : 1.0)) : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Theme.easeSpring; easing.overshoot: 1.8 } }

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontIcon
                font.pixelSize: 22
                color: root.isActiveDefault ? Theme.background : Theme.text
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                text: {
                    if (root.isApp) return root.isSink ? "󰎆" : "󰍬"
                    return root.isSink ? "󰋋" : "󰍬"
                }
            }

            MouseArea {
                id: chipMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: iconChip.selectable
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isSink) Audio.setDefaultSink(root.modelData)
                    else Audio.setDefaultSource(root.modelData)
                }
            }
        }
        
        // Middle Column (Name & Slider)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Text {
                font.family: Theme.fontFamily;
                Layout.fillWidth: true
                text: modelData ? ((modelData.properties && modelData.properties["application.name"]) || modelData.description || modelData.name || "Unknown") : ""
                font.pixelSize: 14
                font.bold: true
                color: Theme.text
                elide: Text.ElideRight
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    value: root.nodeVolume
                    onMoved: function(v) {
                        if (modelData && modelData.audio) {
                            modelData.audio.volume = v
                            if (modelData.audio.muted && v > 0) modelData.audio.muted = false
                        }
                    }
                }
                
                Text {
                    font.family: Theme.fontFamily;
                    // Counts rather than jumps, so a volume change reads as a
                    // continuous movement matching the slider fill's own
                    // animation instead of a discrete number swap.
                    property real shownVolume: root.nodeVolume
                    Behavior on shownVolume { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    text: Math.round(shownVolume * 100) + "%"
                    font.pixelSize: 12
                    color: root.nodeMuted ? Theme.red : Theme.subtext0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Layout.minimumWidth: 35
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
        
        // Mute Button
        IconButton {
            text: root.nodeMuted ? "󰖁" : "󰕾"
            width: 40; height: 40
            isChecked: root.nodeMuted
            onClicked: {
                if (modelData && modelData.audio) {
                    modelData.audio.muted = !modelData.audio.muted
                }
            }
        }
    }
}
