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
