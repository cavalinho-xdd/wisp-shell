import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../core"

// One launcher result: app icon (or a glyph for calc / web / shell), name and
// a muted second line of context. `entry` is a LauncherSearch result.
Item {
    id: row

    property var entry: null
    property bool selected: false

    readonly property bool isApp: !!entry && entry.kind === "app"

    signal hovered()
    signal activated()

    height: Theme.launcherRow
    visible: !!entry

    IconImage {
        id: appIcon
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.spaceSm
        implicitSize: Theme.launcherIcon
        visible: row.isApp
        source: row.isApp ? Quickshell.iconPath(row.entry.app.icon, "application-x-executable") : ""
        asynchronous: true
    }
    Text {
        anchors.centerIn: appIcon
        visible: !!row.entry && !row.isApp
        text: !row.entry ? "" : row.entry.kind === "math" ? "󰃬" : row.entry.kind === "web" ? "󰖟" : ""
        color: Theme.ember
        font.family: Theme.fontIcon
        font.pixelSize: Theme.textTitle
    }

    Text {
        id: name
        anchors.verticalCenter: parent.verticalCenter
        x: appIcon.x + Theme.launcherIcon + Theme.spaceSm
        width: Math.min(implicitWidth, parent.width - x - Theme.spaceMd)
        text: !row.entry ? ""
            : row.entry.kind === "app" ? row.entry.app.name
            : row.entry.kind === "math" ? (row.entry.result || "…")
            : row.entry.kind === "web" ? "Search the web"
            : "Run command"
        elide: Text.ElideRight
        textFormat: Text.PlainText
        color: Theme.islandText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textBody
        font.weight: row.selected ? Font.DemiBold : Font.Normal
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        x: name.x + name.width + Theme.spaceSm
        width: Math.max(0, parent.width - x - Theme.spaceMd)
        text: !row.entry ? ""
            : row.entry.kind === "app" ? (row.entry.app.genericName || "")
            : row.entry.kind === "math" ? row.entry.expr
            : row.entry.kind === "web" ? row.entry.term
            : row.entry.cmd
        elide: Text.ElideRight
        textFormat: Text.PlainText
        color: Theme.islandMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textCaption
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.hovered()
        onClicked: row.activated()
    }
}
