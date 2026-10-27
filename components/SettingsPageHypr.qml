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
        radius: Theme.radiusRow
        color: btnMa.containsMouse
            ? (btn.danger ? Qt.alpha(Theme.red, 0.15) : Theme.hover)
            : Theme.ashHi
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
                color: btn.danger ? Theme.red : Theme.islandText
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontFamily;
                text: btn.text
                font.pixelSize: 13; font.bold: true
                color: btn.danger ? Theme.red : Theme.islandText
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

    // State of the "Add rule" card until the rule is added.
    property bool newFloat: false
    property bool newCenter: false

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        CfgTile {
            icon: "󰂵"
            text: "Blur"
            checked: Settings.conf.hypr.blurEnabled
            onToggled: value => { Settings.conf.hypr.blurEnabled = value; page.queueApply() }
        }
        CfgTile {
            icon: "󰑮"
            text: "Window animations"
            checked: Settings.conf.hypr.animationsEnabled
            onToggled: value => { Settings.conf.hypr.animationsEnabled = value; page.queueApply() }
        }
    }

    CfgGrid {
        CfgSection {
            Layout.fillHeight: true
            title: "Gaps and borders"

            CfgSlider {
                labelWidth: 96
                text: "Inner gaps"
                value: Settings.conf.hypr.gapsIn
                maxValue: 30
                onEdited: v => { Settings.conf.hypr.gapsIn = v; page.queueApply() }
            }
            CfgSlider {
                labelWidth: 96
                text: "Outer gaps"
                value: Settings.conf.hypr.gapsOut
                maxValue: 60
                onEdited: v => { Settings.conf.hypr.gapsOut = v; page.queueApply() }
            }
            CfgSlider {
                labelWidth: 96
                text: "Border size"
                value: Settings.conf.hypr.borderSize
                maxValue: 8
                onEdited: v => { Settings.conf.hypr.borderSize = v; page.queueApply() }
            }
            CfgSlider {
                labelWidth: 96
                text: "Rounding"
                value: Settings.conf.hypr.rounding
                maxValue: 30
                onEdited: v => { Settings.conf.hypr.rounding = v; page.queueApply() }
            }
        }

        CfgSection {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            title: "Blur"

            CfgSpin {
                text: "Size"
                enabled: Settings.conf.hypr.blurEnabled
                value: Settings.conf.hypr.blurSize
                from: 1; to: 20
                onEdited: v => { Settings.conf.hypr.blurSize = v; page.queueApply() }
            }
            CfgSpin {
                text: "Passes"
                enabled: Settings.conf.hypr.blurEnabled
                value: Settings.conf.hypr.blurPasses
                from: 1; to: 4
                onEdited: v => { Settings.conf.hypr.blurPasses = v; page.queueApply() }
            }
            CfgNotice {
                Layout.topMargin: Theme.spaceXs
                visible: !Settings.conf.hypr.blurEnabled
                text: "Turn on Blur above to change these."
            }
        }

        CfgSection {
            Layout.columnSpan: 2
            title: "Window rules"

            CfgNotice {
                Layout.bottomMargin: Theme.spaceXs
                text: (Settings.conf.customWindowRules || []).length === 0
                    ? "No rules yet. A rule applies to windows whose class matches, e.g. kitty or firefox."
                    : "Applied to windows whose class matches."
            }

            Repeater {
                model: Settings.conf.customWindowRules || []
                delegate: RowLayout {
                    id: ruleRow
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.listRow
                    Layout.leftMargin: 12
                    Layout.rightMargin: Theme.spaceXs
                    spacing: Theme.spaceSm

                    Text {
                        text: ruleRow.modelData.match
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textCaption
                        color: Theme.islandText
                        Layout.preferredWidth: 140
                        elide: Text.ElideRight
                    }
                    Text {
                        text: {
                            let parts = [];
                            for (let k in ruleRow.modelData.rules)
                                parts.push(k + ": " + ruleRow.modelData.rules[k]);
                            return parts.join(", ");
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textMonoSmall
                        color: Theme.islandMuted
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.preferredWidth: Theme.controlSize - 6
                        Layout.preferredHeight: Theme.controlSize - 6
                        radius: height / 2
                        color: removeMa.containsMouse ? Qt.alpha(Theme.red, 0.15) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        scale: removeMa.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.textBody
                            color: removeMa.containsMouse ? Theme.red : Theme.islandMuted
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                        MouseArea {
                            id: removeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.removeCustomWindowRule(ruleRow.index)
                        }
                    }
                }
            }
        }

        CfgSection {
            Layout.columnSpan: 2
            title: "Add rule"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.listRow
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: Theme.spaceMd

                Text {
                    text: "Window class"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                    color: Theme.islandText
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.controlSize - 4
                    radius: Theme.radiusRow - 4
                    color: Theme.well
                    border.width: classInput.activeFocus ? 1 : 0
                    border.color: Qt.alpha(Theme.ember, 0.6)
                    TextInput {
                        id: classInput
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceSm
                        anchors.rightMargin: Theme.spaceSm
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textCaption
                        color: Theme.islandText
                        clip: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: classInput.text === ""
                            text: "kitty, firefox, ^steam_app_.*"
                            font: classInput.font
                            color: Theme.islandMuted
                        }
                    }
                }
            }
            CfgSwitch {
                text: "Float"
                checked: page.newFloat
                onToggled: value => page.newFloat = value
            }
            CfgSwitch {
                text: "Center"
                checked: page.newCenter
                onToggled: value => page.newCenter = value
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spaceXs
                Layout.rightMargin: Theme.spaceXs
                Layout.topMargin: Theme.spaceXs
                ActionButton {
                    text: "Add rule"
                    icon: "󰐕"
                    enabled: classInput.text.trim() !== "" && (page.newFloat || page.newCenter)
                    opacity: enabled ? 1 : 0.5
                    onClicked: {
                        let rules = {};
                        if (page.newFloat) rules["float"] = true;
                        if (page.newCenter) rules["center"] = true;
                        Settings.addCustomWindowRule({
                            match: classInput.text.trim(),
                            rules: rules
                        });
                        classInput.text = "";
                        page.newFloat = false;
                        page.newCenter = false;
                    }
                }
            }
        }
    }
}
