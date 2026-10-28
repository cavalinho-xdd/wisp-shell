import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../core"

// Welcome wizard: the islands themselves — material, glow, layout, motion,
// clock and which monitor. Same Settings.conf.shell fields as
// SettingsPageShell.qml; the preview on top follows every change live.
CfgPage {
    id: step

    property string wallpaper: ""
    property var monitors: []

    Process {
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { step.monitors = JSON.parse(this.text.trim()); } catch (e) {}
            }
        }
    }

    WelcomeIslandsPreview {
        Layout.fillWidth: true
        wallpaper: step.wallpaper
    }

    CfgSection {
        title: "Islands"

        CfgChoice {
            text: "Material"
            value: Settings.conf.shell.material
            options: [
                { value: "solid", label: "Solid" },
                { value: "tinted", label: "Tinted glass" },
                { value: "smoked", label: "Smoked glass" }
            ]
            onEdited: v => Settings.conf.shell.material = v
        }
        CfgChoice {
            text: "Glow"
            value: Settings.conf.shell.glow
            options: [
                { value: "soft", label: "Soft" },
                { value: "medium", label: "Medium" },
                { value: "strong", label: "Strong" }
            ]
            onEdited: v => Settings.conf.shell.glow = v
        }
        CfgChoice {
            text: "Layout"
            value: Settings.conf.shell.emberLayout
            options: [
                { value: "spread", label: "Spread" },
                { value: "cluster", label: "Cluster" },
                { value: "quarters", label: "Quarters" }
            ]
            onEdited: v => Settings.conf.shell.emberLayout = v
        }
        CfgChoice {
            // A multi-monitor machine shows islands on every screen by
            // default; this is the moment to say "just this one".
            visible: step.monitors.length > 1
            text: "Show on"
            value: Settings.conf.shell.pillMonitor
            options: [{ value: "", label: "All monitors" }].concat(
                step.monitors.map(m => ({ value: m.name, label: m.name })))
            onEdited: v => Settings.conf.shell.pillMonitor = v
        }
    }

    CfgSection {
        title: "Feel"

        CfgSwitch {
            text: "Reduce motion"
            hint: "Short fades instead of springs, no breathing ember"
            checked: Settings.conf.shell.reduceMotion
            onToggled: value => Settings.conf.shell.reduceMotion = value
        }
        CfgSwitch {
            text: "12-hour clock"
            checked: Settings.conf.shell.clock12h
            onToggled: value => Settings.conf.shell.clock12h = value
        }
    }
}
