import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core"

// Wallpaper & Colors — Material You palette from the current wallpaper via
// matugen (scripts/apply_colors.sh writes colors.json, Theme.qml watches it).
// Runtime + project-local only: the user's matugen config is never executed.
CfgPage {
    id: page

    readonly property bool live: Settings.conf.colors.dynamicEnabled

    readonly property var schemes: [
        { id: "tonal-spot", name: "Tonal Spot" },
        { id: "vibrant", name: "Vibrant" },
        { id: "expressive", name: "Expressive" },
        { id: "fruit-salad", name: "Fruit Salad" },
        { id: "rainbow", name: "Rainbow" },
        { id: "content", name: "Content" },
        { id: "fidelity", name: "Fidelity" },
        { id: "neutral", name: "Neutral" },
        { id: "monochrome", name: "Monochrome" }
    ]

    // matugen run takes ~150 ms; debounce chip mashing
    Timer {
        id: regenTimer
        interval: 250
        onTriggered: Settings.applyColors("")
    }
    function queueRegen() {
        if (page.live) regenTimer.restart();
    }

    CfgNotice {
        text: "Colors are generated from your wallpaper with matugen into a local colors.json — your own matugen config and dotfiles are never touched. Turning this off returns to the built-in Catppuccin palette."
    }

    CfgSection {
        title: "Dynamic colors"
        icon: "󰸌"

        CfgSwitch {
            icon: "󰏘"
            text: "Color the shell from the wallpaper"
            checked: Settings.conf.colors.dynamicEnabled
            onToggled: value => {
                Settings.conf.colors.dynamicEnabled = value;
                if (value) Settings.applyColors("");
            }
        }

        CfgSwitch {
            icon: ""
            text: "Recolor terminal too (kitty)"
            enabled: Settings.conf.colors.dynamicEnabled
            checked: Settings.conf.colors.applyTerminal
            onToggled: value => {
                Settings.conf.colors.applyTerminal = value;
                if (value) Settings.applyColors("");
            }
        }

        CfgSwitch {
            icon: "󰆍"
            text: "Recolor terminal (any terminal, via OSC)"
            enabled: Settings.conf.colors.dynamicEnabled
            checked: Settings.conf.colors.applyTerminalOSC
            onToggled: value => {
                Settings.conf.colors.applyTerminalOSC = value;
                if (value) Settings.applyColors("");
            }
        }
    }

    CfgNotice {
        visible: Settings.conf.colors.applyTerminalOSC
        icon: "󰈙"
        text: "This works in any terminal (not just kitty) by sending OSC color escapes, but it can't inject itself into your shell's startup — add one line to fish's config.fish (or .bashrc/.zshrc) yourself:\nsource " + Settings.terminalOscPath
    }
    RowLayout {
        visible: Settings.conf.colors.applyTerminalOSC
        Layout.fillWidth: true
        spacing: 12
        Item { Layout.fillWidth: true }
        ActionButton {
            id: oscCopyBtn
            property bool justCopied: false
            icon: justCopied ? "󰄬" : "󰆏"
            text: justCopied ? "Copied!" : "Copy source line"
            onClicked: {
                Quickshell.execDetached(["bash", "-c",
                    "printf %s 'source " + Settings.terminalOscPath + "' | wl-copy"]);
                justCopied = true;
                oscCopyRevert.restart();
            }
            Timer { id: oscCopyRevert; interval: 1500; onTriggered: oscCopyBtn.justCopied = false }
        }
    }

    CfgSection {
        title: "Panel"
        icon: "󰽙"

        CfgSlider {
            icon: "󰗇"
            text: "Transparency"
            value: Math.round(Settings.conf.colors.panelAlpha * 100)
            maxValue: 100
            onEdited: v => Settings.conf.colors.panelAlpha = v / 100
        }
    }

    // ── Wallpaper folder ──
    // Was hardcoded to one Czech-localized path (~/Obrázky/Wallpapers) — the
    // fullscreen picker (wallpaper.qml) now reads Settings.wallpaperFolder,
    // which defaults to `xdg-user-dir PICTURES` and can be overridden here.
    CfgSection {
        title: "Wallpaper folder"
        icon: "󰸉"

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                // Tonal step alone reads as an inset field (DESIGN.md §16)
                color: Theme.surface0
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.subtext0
                    text: Settings.wallpaperFolder
                }
            }

            ActionButton {
                icon: "󰉖"
                text: "Choose folder"
                onClicked: folderPicker.open(Settings.wallpaperFolder)
            }

            ActionButton {
                visible: Settings.conf.colors.wallpaperFolder !== ""
                icon: "󰑙"
                text: "Reset"
                onClicked: Settings.conf.colors.wallpaperFolder = ""
            }
        }
    }

    // Inline, inside the settings surface — a QtQuick.Dialogs FolderDialog here
    // hung the whole session. See FolderPicker.qml.
    FolderPicker {
        id: folderPicker
        Layout.fillWidth: true
        onAccepted: path => Settings.conf.colors.wallpaperFolder = path
    }

    // ── Live palette preview ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        // Wallpaper thumb (only when a generated palette exists)
        Rectangle {
            visible: Theme.dynWallpaper !== ""
            Layout.preferredWidth: 96
            Layout.preferredHeight: 60
            radius: 12
            color: Theme.surface0
            clip: true
            Image {
                anchors.fill: parent
                source: Theme.dynWallpaper !== "" ? "file://" + Theme.dynWallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // Swatches bound straight to Theme — they animate on palette change
        Row {
            spacing: 8
            Repeater {
                model: [
                    { c: Theme.background, n: "bg" },
                    { c: Theme.surface, n: "surface" },
                    { c: Theme.surface0, n: "surface0" },
                    { c: Theme.primary, n: "primary" },
                    { c: Theme.red, n: "error" },
                    { c: Theme.text, n: "text" }
                ]
                delegate: Column {
                    spacing: 4
                    // One of only two Theme.outline borders left in the shell,
                    // kept for the same reason as the wizard's: these are colour
                    // swatches and `background` is a near-black that would be
                    // invisible without an edge. Functional, not decorative.
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: modelData.c
                        border.color: Theme.outline
                        border.width: 1
                    }
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.n
                        font.pixelSize: 9
                        color: Theme.subtext0
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
    }

    // ── Mode ──
    CfgSection {
        title: "Mode"
        icon: "󰖨"
        enabled: page.live
        opacity: page.live ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            spacing: 8
            Repeater {
                model: [ { id: "dark", name: "Dark", icon: "󰖔" }, { id: "light", name: "Light", icon: "󰖨" } ]
                delegate: Rectangle {
                    readonly property bool active: Settings.conf.colors.mode === modelData.id
                    Layout.preferredWidth: modeRow.implicitWidth + 28
                    Layout.preferredHeight: 34
                    radius: 12
                    color: active ? Theme.primary : Theme.surface0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: modeMa.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text { text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 13; color: active ? Theme.colorOnPrimary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            font.family: Theme.fontFamily; text: modelData.name; font.pixelSize: 12; font.bold: active; color: active ? Theme.colorOnPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: modeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { Settings.conf.colors.mode = modelData.id; page.queueRegen() }
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    // ── Scheme ──
    CfgSection {
        title: "Scheme"
        icon: "󰢵"
        enabled: page.live
        opacity: page.live ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: page.schemes
                delegate: Rectangle {
                    readonly property bool active: Settings.conf.colors.scheme === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 12
                    color: active ? Theme.surface0 : (schemeMa.containsMouse ? Qt.alpha(Theme.surface0, 0.5) : Qt.alpha(Theme.surface0, 0.25))
                    border.color: active ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: schemeMa.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.centerIn: parent
                        text: modelData.name
                        font.pixelSize: 12
                        font.bold: active
                        color: active ? Theme.primary : Theme.text
                    }
                    MouseArea {
                        id: schemeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { Settings.conf.colors.scheme = modelData.id; page.queueRegen() }
                    }
                }
            }
        }
    }

    // ── Regenerate ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 16
        enabled: page.live
        opacity: page.live ? 1.0 : 0.45
        color: regenMa.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
        scale: regenMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "󰑐"; font.family: Theme.fontIcon; font.pixelSize: 15; color: Theme.colorOnPrimary; anchors.verticalCenter: parent.verticalCenter }
            Text {
                font.family: Theme.fontFamily; text: "Regenerate from current wallpaper"; font.pixelSize: 14; font.bold: true; color: Theme.colorOnPrimary; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
            id: regenMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Settings.applyColors("")
        }
    }
}
