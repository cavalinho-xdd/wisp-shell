import QtQuick
import "../core"

// Edge fades for a scrollable list: content dissolves into the panel at
// whichever edge has more content beyond it.
//
// This is a discoverability fix, not decoration. A `clip: true` list cuts its
// content off with a hard edge that looks identical whether the list ends
// there or continues — so "there is more below" is invisible until the user
// happens to scroll. A fade at an edge only when that edge actually overflows
// makes "there's more" readable at a glance, and its disappearance tells you
// you've reached the end.
//
// Usage: place as a sibling *after* the list, anchored over it:
//     ScrollFade { anchors.fill: list; target: list }
// Must not intercept input — it sits on top of the list it describes.
Item {
    id: root

    // Any Flickable (ListView/GridView/Flickable/ScrollView's contentItem).
    required property var target
    property color tint: Theme.panelBackground
    property real size: 24

    // Purely a visual overlay: never steal clicks/wheel from the list beneath.
    enabled: false

    readonly property bool canScrollUp: !!target && target.contentY > target.originY + 1
    readonly property bool canScrollDown: !!target
        && (target.contentY + target.height) < (target.originY + target.contentHeight - 1)

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root.size
        opacity: root.canScrollUp ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.tint }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: root.size
        opacity: root.canScrollDown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: root.tint }
        }
    }
}
