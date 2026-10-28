import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import "../core"

ColumnLayout {
    id: step
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 12

    CfgNotice {
        text: "Pick a theme for the login screen. Applying it asks for your password."
    }

    CfgSection {
        title: "SDDM theme"

        FolderListModel {
            id: sddmModel
            folder: "file:///usr/share/sddm/themes"
            showDirs: true
            showFiles: false
            showDotAndDotDot: false
        }

        GridView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            Layout.margins: 12
            model: sddmModel
            cellWidth: 200
            cellHeight: 50
            clip: true

            delegate: Rectangle {
                width: 180
                height: Theme.controlSize
                radius: height / 2
                color: thumbMa.containsMouse ? Theme.hover : Theme.ashHi
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                Text {
                    anchors.centerIn: parent
                    text: fileName
                    color: Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }

                MouseArea {
                    id: thumbMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/set_sddm.sh"), fileName])
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
