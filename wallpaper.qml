//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import "core"

ShellRoot {
    PanelWindow {
        id: window
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        
        color: Qt.rgba(0, 0, 0, 0.7)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wallpaper_picker"
        
        property real skewFactor: -0.25
        property real itemWidth: 240
        property real itemHeight: 480
        // Was -40 with non-active cards at 0.5x width — that combo made the
        // inner image ~1.5x wider than its own clipped item (120/(120-40)),
        // so neighbors mostly overlapped into invisibility (one thin sliver
        // visible, everything else hidden). Widened non-active cards below
        // and eased off the overlap so each option actually reads.
        property real spacing: -25
        
        // Close on background click
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
        
        Text {
            font.family: Theme.fontFamily;
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Select Wallpaper"
            font.pixelSize: 32
            font.bold: true
            color: "white"
            style: Text.Outline
            styleColor: "black"
        }
        
        ListView {
            id: view
            anchors.centerIn: parent
            width: parent.width
            height: window.itemHeight + 100
            orientation: ListView.Horizontal
            spacing: window.spacing
            
            preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.6 + window.spacing) / 2)
            preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.6 + window.spacing) / 2)
            highlightRangeMode: ListView.StrictlyEnforceRange
            snapMode: ListView.SnapToItem
            highlightMoveDuration: 500
            
            model: FolderListModel {
                folder: "file://" + Settings.wallpaperFolder
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                showDirs: false
                sortField: FolderListModel.Name
            }
            
            delegate: Item {
                id: delegateRoot
                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property real targetWidth: isCurrent ? (window.itemWidth * 1.6) : (window.itemWidth * 0.85)
                readonly property real targetHeight: isCurrent ? (window.itemHeight + 60) : window.itemHeight
                
                width: targetWidth + window.spacing
                height: targetHeight
                anchors.verticalCenter: parent.verticalCenter
                z: isCurrent ? 10 : 1
                
                opacity: isCurrent ? 1.0 : 0.6
                
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                
                Item {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                    width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0
                    height: parent.height
                    
                    transform: Matrix4x4 {
                        property real s: window.skewFactor
                        matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (isCurrent) {
                                // Apply Wallpaper
                                let path = String(fileUrl).replace("file://", "");
                                let cmd = `if command -v awww &> /dev/null; then awww img "${path}"; elif command -v swww &> /dev/null; then swww img "${path}" --transition-type wipe --transition-fps 60; elif command -v hyprctl &> /dev/null; then hyprctl hyprpaper wallpaper ",${path}"; fi`;
                                Quickshell.execDetached(["bash", "-c", cmd]);
                                Settings.conf.colors.lastWallpaper = path;
                                Settings.flush();
                                if (Settings.conf.colors.dynamicEnabled) Settings.applyColors(path);
                                Qt.quit();
                            } else {
                                view.currentIndex = index
                            }
                        }
                    }
                    
                    Item {
                        anchors.fill: parent
                        anchors.margins: 2
                        clip: true
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.background
                            // Ring only on the focused card — semantic state.
                            // The idle outline every card wore framed the images
                            // it was meant to show off (DESIGN.md §16).
                            border.color: Theme.primary
                            border.width: isCurrent ? 3 : 0
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                        
                        Image {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -50
                            width: (window.itemWidth * 1.6) + ((window.itemHeight + 60) * Math.abs(window.skewFactor)) + 50
                            height: window.itemHeight + 60
                            fillMode: Image.PreserveAspectCrop
                            source: fileUrl
                            asynchronous: true
                            
                            transform: Matrix4x4 {
                                property real s: -window.skewFactor
                                matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        
                        // Dim unselected items
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: isCurrent ? 0.0 : 0.5
                            Behavior on opacity { NumberAnimation { duration: 500 } }
                        }
                    }
                }
            }
        }
    }
}
