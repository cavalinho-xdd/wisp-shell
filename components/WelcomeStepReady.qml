import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Welcome wizard step 5 — system check + what to press next.
//
// The check is the concrete answer to plan.md's Scaling Notes "No first-run
// experience" bullet ("detect GPU vendor, confirm the Nerd Font resolved").
// Every row is a thing wisp actually shells out to somewhere in the codebase,
// and each says what stops working without it — so a fresh install learns
// about a missing dependency here, at setup, instead of via a feature that
// silently does nothing weeks later (the exact failure mode the Fonts and
// hyprctl-keyword entries in CLAUDE.md exist because of).
ColumnLayout {
    id: step
    // Sized against the StackLayout explicitly — see WelcomeStepIntro for why
    // Layout.fillWidth cannot be used here.
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 12

    signal openSettings()

    // Font resolution needs no subprocess — Theme already resolves it against
    // Qt.fontFamilies() at startup and falls back to a literal "monospace" /
    // "sans-serif" when nothing in its candidate list is installed.
    readonly property bool iconFontOk: Theme.fontIcon !== "monospace"
    readonly property bool textFontOk: Theme.fontFamily !== "sans-serif"

    property var found: ({})
    property bool checked: false

    // One process, one line of JSON — same shape as Settings.syncFromSystem().
    Process {
        id: depProc
        command: ["bash", "-c",
            "printf '{'; " +
            "first=1; for b in hyprctl matugen jq qalc wl-copy nvidia-smi bc swww hyprpaper kitty; do " +
            "  if [ $first -eq 0 ]; then printf ','; fi; first=0; " +
            "  if command -v \"$b\" >/dev/null 2>&1; then printf '\"%s\":true' \"$b\"; " +
            "  else printf '\"%s\":false' \"$b\"; fi; " +
            "done; printf '}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    step.found = JSON.parse(this.text.trim());
                    step.checked = true;
                } catch (e) {}
            }
        }
    }

    // `have` is only meaningful once the probe has actually answered — before
    // that every lookup is undefined, which must not render as "missing".
    function have(bin) { return step.checked && step.found[bin] === true; }

    readonly property var rows: [
        { ok: step.have("hyprctl"), name: "Hyprland", need: "required",
          desc: "Everything — settings, keybinds, window rules" },
        { ok: step.iconFontOk && step.textFontOk, name: "Fonts", need: "required",
          desc: step.iconFontOk ? "Text and Nerd Font icons resolved" : "No Nerd Font found — icons will render as boxes" },
        { ok: step.have("matugen") && step.have("jq"), name: "matugen + jq", need: "colors",
          desc: "Wallpaper-derived Material You palette" },
        { ok: step.have("swww") || step.have("hyprpaper"), name: "swww / hyprpaper", need: "wallpaper",
          desc: "Setting the wallpaper from the picker" },
        { ok: step.have("nvidia-smi") && step.have("bc"), name: "nvidia-smi + bc", need: "optional",
          desc: "GPU ring on the Performance tab (Nvidia only)" },
        { ok: step.have("qalc") && step.have("wl-copy"), name: "qalc + wl-copy", need: "optional",
          desc: "Launcher calculator and copy actions" }
    ]

    Text {
        Layout.leftMargin: 4
        font.family: Theme.fontFamily
        text: "System check"
        font.pixelSize: 15
        font.bold: true
        color: Theme.text
    }

    // No container box — see WelcomeStepIntro. These are six rows under a
    // heading; proximity already groups them. Each row instead carries its own
    // tonal fill, which is what actually needs separating (one row from the
    // next), rather than an outline around the whole set.
    ColumnLayout {
        id: checkCol
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: step.rows
            delegate: Rectangle {
                id: checkRow
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                // The row itself is the surface. Separation from the card comes
                // from the +9.4 L* tonal step, and from row to row from the 4px
                // gap — no outline needed at either level.
                color: Theme.surface

                // Amber rather than red for anything non-required: a missing
                // optional dependency is information, not an error, and
                // colouring it like a failure would be a lie.
                readonly property color tint: modelData.ok ? Theme.green
                    : (modelData.need === "required" ? Theme.red : Theme.peach)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 18
                        text: checkRow.modelData.ok ? "󰄬" : (checkRow.modelData.need === "required" ? "󰅖" : "󰀪")
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        color: checkRow.tint
                    }
                    Text {
                        Layout.preferredWidth: 132
                        font.family: Theme.fontFamily
                        text: checkRow.modelData.name
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        text: checkRow.modelData.desc
                        font.pixelSize: 11
                        color: Theme.subtext0
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // ── Keybind tips ──
    Text {
        Layout.leftMargin: 4
        Layout.topMargin: 2
        font.family: Theme.fontFamily
        text: "Good to know"
        font.pixelSize: 15
        font.bold: true
        color: Theme.text
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: [
                { key: "Super + Space", desc: "App launcher" },
                { key: "Click the pill", desc: "Open the dashboard" }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 14
                color: Theme.surface

                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.fontMono
                        text: parent.parent.modelData.key
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.primary
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.fontFamily
                        text: parent.parent.modelData.desc
                        font.pixelSize: 11
                        color: Theme.subtext0
                    }
                }
            }
        }

        ActionButton {
            icon: "󰒓"
            text: "Open Settings"
            onClicked: {
                Quickshell.execDetached(["/usr/bin/qs", "-p", Settings.settingsAppPath]);
                step.openSettings();
            }
        }
    }

    Item { Layout.fillHeight: true }
}
