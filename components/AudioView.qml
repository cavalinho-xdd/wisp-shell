import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../core"

Item {
    id: root
    property var stack: null
    
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 24
            
            IconButton {
                text: "󰄽" // Back icon
                width: 40; height: 40
                onClicked: if (root.stack) root.stack.pop()
            }
            
            Text {
                font.family: Theme.fontFamily;
                Layout.fillWidth: true
                text: "Audio & Mixer"
                font.pixelSize: 22
                font.bold: true
                color: Theme.text
                horizontalAlignment: Text.AlignHCenter
            }
            
            Item { width: 40 } // Spacer for centering
        }
    }
    
    ScrollView {
        id: scrollView
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 0
        clip: true
        
        RowLayout {
            width: scrollView.availableWidth
            spacing: 24
            
            // ── Left Column: Outputs ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 24
                
                // Hardware Outputs
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        font.family: Theme.fontFamily;
                        text: "Output Devices"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                    }
                    
                    Repeater {
                        model: Audio.outputDevices
                        delegate: PwNodeDelegate {
                            isSink: true
                            isApp: false
                        }
                    }
                }
                
                // App Mixers (Outputs)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: Audio.outputAppNodes.length > 0
                    
                    Text {
                        font.family: Theme.fontFamily;
                        text: "Applications"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                    }
                    
                    Repeater {
                        model: Audio.outputAppNodes
                        delegate: PwNodeDelegate {
                            isSink: true
                            isApp: true
                        }
                    }
                }
            }
            
            // ── Right Column: Inputs ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 24
                
                // Hardware Inputs
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        font.family: Theme.fontFamily;
                        text: "Input Devices"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                    }
                    
                    Repeater {
                        model: Audio.inputDevices
                        delegate: PwNodeDelegate {
                            isSink: false
                            isApp: false
                        }
                    }
                }
                
                // App Mixers (Inputs)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: Audio.inputAppNodes.length > 0
                    
                    Text {
                        font.family: Theme.fontFamily;
                        text: "Recording Applications"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                    }
                    
                    Repeater {
                        model: Audio.inputAppNodes
                        delegate: PwNodeDelegate {
                            isSink: false
                            isApp: true
                        }
                    }
                }
            }
        }
    }
}
