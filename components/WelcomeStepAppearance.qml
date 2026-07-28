import QtQuick
import QtQuick.Layouts
import "../core"

// Welcome wizard step 2 — the matugen palette settings, mirroring
// SettingsPageColors.qml's own controls (same Settings.conf.colors fields,
// same Settings.applyColors() call), just laid out for a one-screen pass
// instead of a scrolling settings page.
ColumnLayout {
    id: step
    // Sized against the StackLayout explicitly — see WelcomeStepIntro for why
    // Layout.fillWidth cannot be used here.
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 12

    readonly property bool live: Settings.conf.colors.dynamicEnabled

    // matugen takes ~150 ms per run; debounce chip mashing exactly as the
    // settings page does.
    Timer { id: regenTimer; interval: 250; onTriggered: Settings.applyColors("") }
    function queueRegen() { if (step.live) regenTimer.restart(); }

    CfgSwitch {
        icon: "󰏘"
        text: "Color the shell from your wallpaper"
        hint: "Generates a Material You palette with matugen. Off = built-in Catppuccin."
        checked: Settings.conf.colors.dynamicEnabled
        onToggled: value => {
            Settings.conf.colors.dynamicEnabled = value;
            if (value) Settings.applyColors("");
        }
    }

    // ── Mode ──
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        spacing: 8
        enabled: step.live
        opacity: step.live ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        Repeater {
            model: [ { id: "dark", name: "Dark", icon: "󰖔" }, { id: "light", name: "Light", icon: "󰖨" } ]
            delegate: Rectangle {
                id: modeChip
                required property var modelData
                readonly property bool active: Settings.conf.colors.mode === modelData.id
                Layout.preferredWidth: 120
                Layout.preferredHeight: 62
                radius: 16
                // Fill alone carries selection — an outline that only ever
                // matches the fill it surrounds is decoration.
                color: active ? Theme.primary : Theme.surface
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                scale: modeMa.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modeChip.modelData.icon
                        font.family: Theme.fontIcon; font.pixelSize: 20
                        color: modeChip.active ? Theme.colorOnPrimary : Theme.subtext0
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.fontFamily
                        text: modeChip.modelData.name
                        font.pixelSize: 12; font.bold: modeChip.active
                        color: modeChip.active ? Theme.colorOnPrimary : Theme.text
                    }
                }
                MouseArea {
                    id: modeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Settings.conf.colors.mode = modeChip.modelData.id; step.queueRegen() }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Live palette preview — bound straight to Theme, so it animates
        // through the 600 ms ColorAnimations when a regen lands.
        Row {
            spacing: 6
            Repeater {
                model: [ Theme.background, Theme.surface, Theme.primary, Theme.red, Theme.text ]
                // The one hairline kept in this file, deliberately: these are
                // colour swatches, and `background` is a near-black that would
                // be invisible against the card without an edge. That is a
                // functional outline on a swatch, not decoration around a card.
                delegate: Rectangle {
                    required property var modelData
                    width: 26; height: 26; radius: 13
                    color: modelData
                    border.color: Theme.outline
                    border.width: 1
                }
            }
        }
    }

    // ── Scheme ──
    Text {
        Layout.leftMargin: 12
        Layout.topMargin: 4
        font.family: Theme.fontFamily
        text: "Palette style"
        font.pixelSize: 12
        font.bold: true
        color: Theme.subtext0
        opacity: step.live ? 1.0 : 0.45
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        columns: 3
        rowSpacing: 8
        columnSpacing: 8
        enabled: step.live
        opacity: step.live ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        Repeater {
            model: [
                { id: "tonal-spot", name: "Tonal Spot" },
                { id: "vibrant", name: "Vibrant" },
                { id: "expressive", name: "Expressive" },
                { id: "fruit-salad", name: "Fruit Salad" },
                { id: "content", name: "Content" },
                { id: "monochrome", name: "Monochrome" }
            ]
            delegate: Rectangle {
                id: schemeChip
                required property var modelData
                readonly property bool active: Settings.conf.colors.scheme === modelData.id
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 12
                // Selection is a primary-tinted fill, not a ring around a
                // neutral one — the chip becomes the accent instead of wearing it.
                color: active ? Qt.alpha(Theme.primary, 0.22)
                    : (schemeMa.containsMouse ? Theme.surface0 : Theme.surface)
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                scale: schemeMa.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    text: schemeChip.modelData.name
                    font.pixelSize: 12
                    font.bold: schemeChip.active
                    color: schemeChip.active ? Theme.primary : Theme.text
                }
                MouseArea {
                    id: schemeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Settings.conf.colors.scheme = schemeChip.modelData.id; step.queueRegen() }
                }
            }
        }
    }

    CfgSlider {
        icon: "󰗇"
        text: "Transparency"
        value: Math.round(Settings.conf.colors.panelAlpha * 100)
        maxValue: 100
        onEdited: v => Settings.conf.colors.panelAlpha = v / 100
    }

    Item { Layout.fillHeight: true }
}
