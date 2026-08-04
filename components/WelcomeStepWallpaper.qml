import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import "../core"

// Welcome wizard step 3 — where wallpapers live, plus a live thumbnail strip
// of what's actually in that folder. The strip is the point: it turns "is this
// path right?" from a question into something you can see the answer to, on a
// machine where the default (xdg-user-dir PICTURES + /Wallpapers) may well be
// empty or nonexistent.
ColumnLayout {
    id: step
    // Sized against the StackLayout explicitly — see WelcomeStepIntro for why
    // Layout.fillWidth cannot be used here.
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 12

    CfgSection {
        title: "Wallpaper folder"
        icon: "󰉖"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                // Tonal step alone reads as an inset field; the outline it used
                // to carry was doing nothing the fill wasn't already doing.
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
                    text: Settings.wallpaperFolder
                }
            }

            ActionButton {
                icon: "󰉖"
                text: "Choose"
                onClicked: folderPicker.open(Settings.wallpaperFolder)
            }
        }
    }

    // Inline, inside the wizard's own surface. A QtQuick.Dialogs FolderDialog
    // here used to hang the entire session — see FolderPicker.qml for why, and
    // note the thumbnail delegate below already avoids the same trap
    // deliberately.
    FolderPicker {
        id: folderPicker
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        onAccepted: path => Settings.conf.colors.wallpaperFolder = path
    }

    // ── What's in there ──
    FolderListModel {
        id: wallModel
        folder: "file://" + Settings.wallpaperFolder
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    // The browser and the "what's in there" readout swap rather than stack:
    // this step is sized to the wizard card (Layout.preferredHeight above), so
    // showing both at once would overflow it.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: !folderPicker.visible
        Text {
            Layout.fillWidth: true
            font.family: Theme.fontFamily
            text: wallModel.count > 0
                ? wallModel.count + (wallModel.count === 1 ? " wallpaper found" : " wallpapers found")
                : "No images here yet"
            font.pixelSize: 12
            font.bold: true
            color: wallModel.count > 0 ? Theme.text : Theme.peach
        }
    }

    // Thumbnail strip, first 8. Clicking one applies it immediately (and
    // regenerates the palette if dynamic colors are on) — same call pair the
    // full picker uses, so "set a wallpaper" is reachable without leaving the
    // wizard.
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 108
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        visible: wallModel.count > 0 && !folderPicker.visible
        model: wallModel

        delegate: Rectangle {
            id: thumb
            required property url fileUrl
            required property int index
            readonly property string plainPath: String(fileUrl).replace("file://", "")
            readonly property bool selected: Settings.conf.colors.lastWallpaper === plainPath

            width: 160
            height: 100
            radius: 14
            color: Theme.surface0
            clip: true
            // A ring ONLY when selected. The separation ladder allows an
            // outline for genuine semantic state, and "which wallpaper is
            // applied" is exactly that — but the idle grey border every
            // thumbnail used to wear was decoration, and it fought the images
            // it was framing. Unselected thumbs separate by their own image
            // content and the 10px gutter.
            border.color: Theme.primary
            border.width: selected ? 2 : 0
            Behavior on border.width { NumberAnimation { duration: Theme.animFast } }
            scale: thumbMa.pressed ? 0.95 : (thumbMa.containsMouse ? 1.04 : 1.0)
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

            Image {
                anchors.fill: parent
                source: thumb.fileUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            // Selected badge
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: 22; height: 22; radius: 11
                color: Theme.primary
                opacity: thumb.selected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                Text {
                    anchors.centerIn: parent
                    text: "󰄬"
                    font.family: Theme.fontIcon; font.pixelSize: 12
                    color: Theme.colorOnPrimary
                }
            }

            MouseArea {
                id: thumbMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // awww/swww/hyprpaper one-liner — the single remaining copy
                    // of it lives in wallpaper.qml; kept identical here rather
                    // than launching the picker, so picking never interrupts
                    // the wizard's own exclusive-focus surface.
                    const p = thumb.plainPath;
                    Quickshell.execDetached(["bash", "-c",
                        `if command -v awww &> /dev/null; then awww img "${p}"; elif command -v swww &> /dev/null; then swww img "${p}" --transition-type wipe --transition-fps 60; elif command -v hyprctl &> /dev/null; then hyprctl hyprpaper wallpaper ",${p}"; fi`]);
                    Settings.conf.colors.lastWallpaper = p;
                    if (Settings.conf.colors.dynamicEnabled) Settings.applyColors(p);
                }
            }
        }
    }

    CfgNotice {
        visible: wallModel.count === 0 && !folderPicker.visible
        icon: "󰋽"
        text: "Point this at a folder with images, or drop some into the path above. You can always browse the full picker later from the dashboard's wallpaper button."
    }

    Item { Layout.fillHeight: true }
}
