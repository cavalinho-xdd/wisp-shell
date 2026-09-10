import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../core"

CfgPage {
    id: page

    component ActionButton: Rectangle {
        id: btn
        property string icon: ""
        property string text: ""
        property bool danger: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 14
        color: btnMa.containsMouse
            ? (btn.danger ? Qt.alpha(Theme.red, 0.15) : Theme.surface0)
            : Theme.surface
        border.color: Theme.red
        border.width: btn.danger ? 1 : 0
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        scale: btnMa.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: btn.icon
                font.family: Theme.fontIcon; font.pixelSize: 14
                color: btn.danger ? Theme.red : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontFamily;
                text: btn.text
                font.pixelSize: 13; font.bold: true
                color: btn.danger ? Theme.red : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    Timer {
        id: applyTimer
        interval: 150
        onTriggered: Settings.applyLook()
    }
    function queueApply() {
        applyTimer.restart();
    }

    property int currentTab: 0

    // Top Tabs
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        spacing: 12

        Repeater {
            model: ["Look & Feel", "Window Rules"]
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: page.currentTab === index ? Theme.primary : (tabMa.containsMouse ? Theme.surface0 : Theme.surface)
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: page.currentTab === index ? Theme.background : Theme.text
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                
                MouseArea {
                    id: tabMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: page.currentTab = index
                }
            }
        }
    }

    // ── Tab 0: Look & Feel ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 28
        visible: page.currentTab === 0

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

    // ── Tab 1: Window Rules ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 28
        visible: page.currentTab === 1

        CfgNotice {
            text: "Add custom window rules below. They apply to matching window classes (e.g. 'kitty', 'firefox')."
        }

        CfgSection {
            title: "Rules"
            icon: "󰖲"

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 12

                Repeater {
                    model: Settings.conf.customWindowRules || []
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 12
                        color: Theme.surface0
                        
                        required property var modelData
                        required property int index

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: modelData.match
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.text
                                font.bold: true
                                Layout.preferredWidth: 120
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    let parts = [];
                                    for (let k in modelData.rules) {
                                        parts.push(k + ": " + modelData.rules[k]);
                                    }
                                    return parts.join(", ");
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.subtext0
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            IconButton {
                                icon: "󰅖"
                                color: Theme.red
                                onClicked: Settings.removeCustomWindowRule(index)
                            }
                        }
                    }
                }
            }
        }

        CfgSection {
            title: "Add new rule"
            icon: "󰐕"

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Class match:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.text
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Theme.surface0
                        TextInput {
                            id: classInput
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.text
                            clip: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Float"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.text
                    }
                    ToggleSwitch {
                        id: floatInput
                    }
                    
                    Item { Layout.preferredWidth: 10 }

                    Text {
                        text: "Center"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.text
                    }
                    ToggleSwitch {
                        id: centerInput
                    }
                }

                ActionButton {
                    text: "Add Rule"
                    icon: "󰐕"
                    onClicked: {
                        if (classInput.text.trim() === "") return;
                        let rules = {};
                        if (floatInput.checked) rules["float"] = true;
                        if (centerInput.checked) rules["center"] = true;
                        if (Object.keys(rules).length === 0) return;

                        Settings.addCustomWindowRule({
                            match: classInput.text.trim(),
                            rules: rules
                        });

                        classInput.text = "";
                        floatInput.checked = false;
                        centerInput.checked = false;
                    }
                }
            }
        }
    }
}
