import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core"

CfgPage {
    id: page

    readonly property bool live: Settings.conf.hypr.overridesEnabled

    Timer {
        id: applyTimer
        interval: 150
        onTriggered: Settings.applyLook()
    }
    function queueApply() {
        if (page.live) applyTimer.restart();
    }

    CfgNotice {
        text: "Runtime only — your dotfiles are never touched. Toggling off (or any Hyprland reload) restores your own config exactly."
    }

    CfgSection {
        title: "Overrides"
        icon: ""

        CfgSwitch {
            icon: "󰒓"
            text: "Enable Hyprland overrides"
            checked: Settings.conf.hypr.overridesEnabled
            onToggled: value => {
                Settings.conf.hypr.overridesEnabled = value;
                if (value) Settings.applyLook();
                else Settings.restoreUserConfig();
            }
        }
    }

    CfgSection {
        title: "Look & Feel"
        icon: "󰉼"
        enabled: page.live
        opacity: page.live ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

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
