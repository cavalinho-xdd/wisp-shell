import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import "../../core"

// One workspace in the left island: a dot, or for the active one a longer
// ember pill with a glow. The delegate gets its HyprlandWorkspace as modelData
// from WorkspacesView; clicking it switches to that workspace.
Item {
    id: dot

    required property var modelData
    readonly property bool isActive: modelData.active

    implicitWidth: pill.width
    implicitHeight: Theme.islandHeight

    Accessible.role: Accessible.Button
    Accessible.name: "Workspace " + modelData.name
    Accessible.onPressAction: dot.activate()

    function activate(): void {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })");
    }

    RectangularShadow {
        anchors.fill: pill
        radius: pill.radius
        color: Theme.ember
        blur: Theme.glowBlur * 0.5 * Theme.glow
        opacity: dot.isActive ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        width: dot.isActive ? Theme.workspaceActiveWidth : Theme.workspaceDot
        height: Theme.workspaceDot
        radius: height / 2
        color: dot.isActive ? Theme.ember : (mouse.containsMouse ? Theme.islandText : Theme.islandMuted)
        Behavior on width { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    // The dot is 8 px; the hit area is the whole island height and half the
    // gap on each side.
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.leftMargin: -Theme.workspaceGap / 2
        anchors.rightMargin: -Theme.workspaceGap / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: dot.activate()
    }
}
