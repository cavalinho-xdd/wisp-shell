import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import "../core"

// Inline folder browser — the replacement for QtQuick.Dialogs' FolderDialog.
//
// Why this exists at all: FolderDialog opens a real toplevel window, and every
// surface in this shell is a layer-shell surface with exclusive keyboard focus
// (welcome.qml, settings.qml). A dialog spawned from one of those has no
// xdg_toplevel to parent itself to, so it hangs — and because the parent still
// holds the keyboard grab, the hang takes the whole session's input with it.
// No keybinds, and not even Ctrl+Alt+Fn, since VT switching under Wayland goes
// through the compositor. Only a hard reset gets out of it.
//
// WelcomeStepWallpaper's thumbnail strip already worked around the same
// problem by applying wallpapers in place "so picking never interrupts the
// wizard's own exclusive-focus surface" — this component finishes that job for
// the folder-selection half.
//
// Everything here renders inside the caller's own surface, so there is no
// second window and no grab to lose. Usage:
//
//     FolderPicker {
//         id: folderPicker
//         Layout.fillWidth: true
//         onAccepted: path => Settings.conf.colors.wallpaperFolder = path
//     }
//     ActionButton { text: "Choose"; onClicked: folderPicker.open(Settings.wallpaperFolder) }
ColumnLayout {
    id: picker

    // Plain filesystem path (no file:// scheme) currently being browsed.
    property string path: ""

    signal accepted(string path)
    signal cancelled()

    visible: false
    spacing: 8

    function open(startPath) {
        picker.path = startPath;
        picker.visible = true;
    }

    function close() {
        picker.visible = false;
    }

    // String surgery rather than url manipulation: FolderListModel hands back
    // parentFolder as a url, and round-tripping through it re-encodes paths
    // with spaces. The path never leaves this component as anything but a
    // plain string, so keep it one.
    function goUp() {
        const p = picker.path.replace(/\/+$/, "");
        const i = p.lastIndexOf("/");
        picker.path = i > 0 ? p.substring(0, i) : "/";
    }

    FolderListModel {
        id: dirModel
        folder: "file://" + picker.path
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    // ── Current location + up ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ActionButton {
            icon: "󰁝"
            text: "Up"
            onClicked: picker.goUp()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 12
            color: Theme.surface0
            Text {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: Theme.subtext0
                text: picker.path
            }
        }
    }

    // ── Subdirectories ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 168
        radius: 14
        color: Theme.surface0

        ListView {
            id: dirList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: dirModel
            spacing: 2

            delegate: Rectangle {
                id: row
                required property string fileName
                required property string filePath

                width: dirList.width
                height: 32
                radius: 10
                color: rowMa.containsMouse ? Qt.lighter(Theme.surface, 1.35) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰉋"
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: row.fileName
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.text
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.path = row.filePath
                }
            }
        }

        // Distinct from "this folder has no images" — this is about having
        // nowhere further to descend, which is normal and not a warning.
        Text {
            anchors.centerIn: parent
            visible: dirModel.count === 0
            text: "No subfolders here"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.subtext0
        }
    }

    // ── Confirm ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Item { Layout.fillWidth: true }

        ActionButton {
            icon: "󰅖"
            text: "Cancel"
            onClicked: {
                picker.close();
                picker.cancelled();
            }
        }

        ActionButton {
            icon: "󰄬"
            text: "Use this folder"
            onClicked: {
                picker.close();
                picker.accepted(picker.path);
            }
        }
    }
}
