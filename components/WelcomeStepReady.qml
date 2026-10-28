import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Welcome wizard, last step — system check + where to go next.
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
            "first=1; for b in hyprctl matugen jq qalc wl-copy nvidia-smi bc awww swww hyprpaper kitty python3 node curl; do " +
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
        { ok: step.have("python3"), name: "python3", need: "required",
          desc: "Settings > Hyprland and Keybinds edit your real Hyprland config through this" },
        { ok: step.have("matugen") && step.have("jq"), name: "matugen + jq", need: "colors",
          desc: "The ember colour from your wallpaper" },
        { ok: step.have("awww") || step.have("swww") || step.have("hyprpaper"), name: "awww / swww / hyprpaper", need: "wallpaper",
          desc: "Setting the wallpaper from the picker" },
        { ok: step.have("nvidia-smi") && step.have("bc"), name: "nvidia-smi + bc", need: "optional",
          desc: "GPU reading in the system view (Nvidia only)" },
        { ok: step.have("qalc") && step.have("wl-copy"), name: "qalc + wl-copy", need: "optional",
          desc: "Launcher calculator and copy actions" },
        { ok: step.have("node"), name: "node", need: "optional",
          desc: "Live osu! activity (osu!lazer + tosu)" },
        { ok: step.have("curl"), name: "curl", need: "optional",
          desc: "Weather, Steam cover art and achievement popups" }
    ]

    CfgSection {
        id: checkCol
        title: "System check"

        Repeater {
            model: step.rows
            delegate: Rectangle {
                id: checkRow
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: "transparent"

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
                        Layout.preferredWidth: 170
                        font.family: Theme.fontFamily
                        text: checkRow.modelData.name
                        font.pixelSize: Theme.textCaption
                        font.weight: Font.Medium
                        color: Theme.islandText
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        text: checkRow.modelData.desc
                        font.pixelSize: Theme.textCaption
                        color: Theme.islandMuted
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        Text {
            Layout.fillWidth: true
            text: "Everything from this wizard, and more, is in Settings (Super + I)."
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
            color: Theme.islandMuted
            wrapMode: Text.WordWrap
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
