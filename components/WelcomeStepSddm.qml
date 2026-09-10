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

    CfgSection {
        title: "SDDM Theme"
        icon: "󰍜"

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
                height: 40
                radius: 8
                color: thumbMa.containsMouse ? Qt.lighter(Theme.surface0, 1.2) : Theme.surface0
                border.width: 1
                border.color: Theme.surface1

                Text {
                    anchors.centerIn: parent
                    text: fileName
                    color: Theme.text
                    font.family: Theme.fontFamily
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
