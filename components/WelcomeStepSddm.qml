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

    // Installed themes, Wisp's own first.
    readonly property var themes: {
        sddmModel.count; // re-evaluate when the folder is read
        let names = [];
        for (let i = 0; i < sddmModel.count; i++) names.push(sddmModel.get(i, "fileName"));
        return names.sort((a, b) => (b === "wisp-ember") - (a === "wisp-ember"));
    }
    readonly property bool hasWisp: themes.indexOf("wisp-ember") !== -1

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
            Layout.preferredHeight: 220
            Layout.margins: 12
            model: step.themes
            cellWidth: 200
            cellHeight: 50
            clip: true

            delegate: Rectangle {
                id: chip
                required property string modelData
                readonly property bool wisp: modelData === "wisp-ember"
                width: 180
                height: Theme.controlSize
                radius: height / 2
                color: wisp ? Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, thumbMa.containsMouse ? 0.3 : 0.22))
                     : thumbMa.containsMouse ? Theme.hover : Theme.ashHi
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                Accessible.role: Accessible.Button
                Accessible.name: label.text

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: chip.wisp ? "Wisp Ember" : chip.modelData
                    color: chip.wisp ? Theme.ember : Theme.islandText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }

                MouseArea {
                    id: thumbMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/set_sddm.sh"), chip.modelData])
                    }
                }
            }
        }
    }

    // Wisp's theme cannot read your files: it gets its own copy on request.
    RowLayout {
        visible: step.hasWisp
        spacing: Theme.spaceMd
        ActionButton {
            icon: "󰍂"
            text: "Použít pro přihlášení"
            onClicked: Settings.applyLoginScreen(Theme.dynWallpaper, Theme.ember, Theme.glow)
        }
        Text {
            Layout.fillWidth: true
            text: "Copies your wallpaper and ember into Wisp Ember."
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
            color: Theme.islandMuted
            wrapMode: Text.WordWrap
        }
    }

    Item { Layout.fillHeight: true }
}
