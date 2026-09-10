import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../core"

CfgPage {
    id: page

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
