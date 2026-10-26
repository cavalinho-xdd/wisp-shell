import QtQuick
import QtQuick.Layouts
import "../core"

CfgPage {
    CfgSection {
        title: "Collapsed Bar"
        icon: "󰍜"

        CfgSpin {
            icon: "󱂬"
            text: "Workspace dots"
            value: Settings.conf.shell.workspaceCount
            from: 1
            to: 10
            onEdited: v => Settings.conf.shell.workspaceCount = v
        }
        CfgSwitch {
            icon: "󰥔"
            text: "12-hour clock"
            hint: "Off = 24-hour format"
            checked: Settings.conf.shell.clock12h
            onToggled: value => Settings.conf.shell.clock12h = value
        }
        CfgSwitch {
            icon: "󰈸"
            text: "Ember islands (preview)"
            hint: "The new Wisp Ember islands instead of the pill. Unfinished"
            checked: Settings.conf.shell.ember
            onToggled: value => Settings.conf.shell.ember = value
        }
        CfgChoice {
            icon: "󰛨"
            text: "Ember glow"
            enabled: Settings.conf.shell.ember
            value: Settings.conf.shell.glow
            options: [
                { value: "soft", label: "Soft" },
                { value: "medium", label: "Medium" },
                { value: "strong", label: "Strong" }
            ]
            onEdited: v => Settings.conf.shell.glow = v
        }
        CfgChoice {
            icon: "󰂵"
            text: "Island material"
            enabled: Settings.conf.shell.ember
            value: Settings.conf.shell.material
            options: [
                { value: "solid", label: "Solid" },
                { value: "tinted", label: "Tinted glass" },
                { value: "smoked", label: "Smoked glass" }
            ]
            onEdited: v => Settings.conf.shell.material = v
        }
        CfgChoice {
            icon: "󰕮"
            text: "Island layout"
            enabled: Settings.conf.shell.ember
            value: Settings.conf.shell.emberLayout
            options: [
                { value: "spread", label: "Spread" },
                { value: "cluster", label: "Cluster" },
                { value: "quarters", label: "Quarters" }
            ]
            onEdited: v => Settings.conf.shell.emberLayout = v
        }
        CfgSwitch {
            icon: "󰜺"
            text: "Reduce motion"
            hint: "Islands fade instead of springing, no flare, breathing or blur"
            enabled: Settings.conf.shell.ember
            checked: Settings.conf.shell.reduceMotion
            onToggled: value => Settings.conf.shell.reduceMotion = value
        }
    }

    CfgSection {
        title: "Widgets"
        icon: "󰕮"

        CfgSwitch {
            icon: "󰖐"
            text: "Weather card"
            hint: "Fetches open-meteo via auto-detected location, cached 15 min"
            checked: Settings.conf.weather.enable
            onToggled: value => Settings.conf.weather.enable = value
        }
    }
}
