import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core"

CfgPage {
    id: page

    Timer {
        id: applyTimer
        interval: 150
        onTriggered: Settings.applyLook()
    }
    function queueApply() {
        applyTimer.restart();
    }

    CfgNotice {
        text: "Writes straight to your Hyprland config (general.lua / animations.lua) and reloads it — this is your real config now, not a preview layer."
    }

    CfgSection {
        title: "Look & Feel"
        icon: "󰉼"

        CfgSlider {
            icon: "󰁌"
            text: "Inner gaps"
            value: Settings.conf.hypr.gapsIn
            maxValue: 30
            onEdited: v => { Settings.conf.hypr.gapsIn = v; page.queueApply() }
        }
        CfgSlider {
            icon: "󰁌"
            text: "Outer gaps"
            value: Settings.conf.hypr.gapsOut
            maxValue: 60
            onEdited: v => { Settings.conf.hypr.gapsOut = v; page.queueApply() }
        }
        CfgSlider {
            icon: "󰺿"
            text: "Border size"
            value: Settings.conf.hypr.borderSize
            maxValue: 8
            onEdited: v => { Settings.conf.hypr.borderSize = v; page.queueApply() }
        }
        CfgSlider {
            icon: "󱓻"
            text: "Rounding"
            value: Settings.conf.hypr.rounding
            maxValue: 30
            onEdited: v => { Settings.conf.hypr.rounding = v; page.queueApply() }
        }
        CfgSwitch {
            icon: "󰂵"
            text: "Blur"
            checked: Settings.conf.hypr.blurEnabled
            onToggled: value => { Settings.conf.hypr.blurEnabled = value; page.queueApply() }
        }
        CfgSpin {
            icon: "󰘦"
            text: "Blur size"
            enabled: Settings.conf.hypr.blurEnabled
            value: Settings.conf.hypr.blurSize
            from: 1; to: 20
            onEdited: v => { Settings.conf.hypr.blurSize = v; page.queueApply() }
        }
        CfgSpin {
            icon: "󰑖"
            text: "Blur passes"
            enabled: Settings.conf.hypr.blurEnabled
            value: Settings.conf.hypr.blurPasses
            from: 1; to: 4
            onEdited: v => { Settings.conf.hypr.blurPasses = v; page.queueApply() }
        }
        CfgSwitch {
            icon: "󰤺"
            text: "Animations"
            checked: Settings.conf.hypr.animationsEnabled
            onToggled: value => { Settings.conf.hypr.animationsEnabled = value; page.queueApply() }
        }
    }
}
