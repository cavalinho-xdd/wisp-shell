import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Lists the user's real Hyprland lua keybinds (parsed read-only from
// ~/.config/hypr/**/*.lua by scripts/keybinds_list.sh) and lets editable ones
// be rebound at runtime: hl.unbind(old) + hl.bind(new, same dispatcher).
// Overrides persist in settings.json and re-inject on shell startup; any
// Hyprland reload restores the user's own binds untouched.
CfgPage {
    id: page

    property var binds: []
    property string filter: ""
    property int editingIndex: -1

    Process {
        id: listProc
        command: ["bash", String(Qt.resolvedUrl("../scripts/keybinds_list.sh")).replace("file://", "")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.binds = JSON.parse(this.text.trim()); } catch (e) {}
            }
        }
    }

    function overrideFor(bind) {
        return (Settings.conf.keybindOverrides || []).find(o => o.orig === bind.key && o.rest === bind.rest) || null;
    }

    component KeyCaps: Row {
        property string combo: ""
        spacing: 4
        Repeater {
            model: combo.split("+").map(s => s.trim()).filter(s => s !== "")
            delegate: Rectangle {
                width: capText.implicitWidth + 12
                height: 22
                radius: 6
                color: Theme.surface0
                Text {
                    font.family: Theme.fontFamily;
                    id: capText
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.text
                }
            }
        }
    }

    CfgNotice {
        text: "Your real binds from ~/.config/hypr — rebinding is runtime-only, files stay untouched. Locked rows use lua variables and can't be re-evaluated. Overrides re-apply on shell startup; a Hyprland reload restores your own binds."
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // Filter box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 12
            color: Theme.surface0
            border.color: filterInput.activeFocus ? Theme.primary : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                Text { text: "󰍉"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.subtext0 }
                TextInput {
                    font.family: Theme.fontFamily;
                    id: filterInput
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    color: Theme.text
                    clip: true
                    selectByMouse: true
                    onTextChanged: page.filter = text.toLowerCase()
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Filter keybinds…"
                        font.pixelSize: 12
                        color: Qt.alpha(Theme.subtext0, 0.6)
                        visible: filterInput.text === "" && !filterInput.activeFocus
                    }
                }
            }
        }

        // Clear all overrides
        Rectangle {
            visible: (Settings.conf.keybindOverrides || []).length > 0
            Layout.preferredHeight: 34
            Layout.preferredWidth: clearRow.implicitWidth + 24
            radius: 12
            color: clearAllMa.containsMouse ? Qt.alpha(Theme.red, 0.15) : "transparent"
            border.color: Theme.red
            border.width: 1
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Row {
                id: clearRow
                anchors.centerIn: parent
                spacing: 6
                Text { text: "󰦛"; font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.red; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    font.family: Theme.fontFamily;
                    text: "Reset all (" + (Settings.conf.keybindOverrides || []).length + ")"
                    font.pixelSize: 11; font.bold: true; color: Theme.red
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: clearAllMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Settings.clearKeybindOverrides()
            }
        }
    }

    // ── Bind list ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: page.binds
            delegate: Rectangle {
                id: bindRow

                readonly property var ov: (Settings.conf.keybindOverrides, page.overrideFor(modelData))
                readonly property string shownKey: ov ? ov.key : modelData.key
                readonly property bool editing: page.editingIndex === index
                readonly property bool matchesFilter: page.filter === ""
                    || modelData.key.toLowerCase().includes(page.filter)
                    || modelData.desc.toLowerCase().includes(page.filter)
                    || modelData.rest.toLowerCase().includes(page.filter)

                visible: matchesFilter
                Layout.fillWidth: true
                implicitHeight: matchesFilter ? (editing ? 76 : 44) : 0
                radius: 12
                color: editing ? Theme.surface0 : (rowMa.containsMouse ? Qt.alpha(Theme.surface0, 0.6) : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }
                clip: true

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 7
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        KeyCaps { combo: bindRow.shownKey }

                        // Modified marker
                        Rectangle {
                            visible: bindRow.ov !== null
                            width: 6; height: 6; radius: 3
                            color: Theme.primary
                        }

                        Text {
                            font.family: Theme.fontFamily;
                            Layout.fillWidth: true
                            text: modelData.desc !== "" ? modelData.desc : modelData.rest
                            font.pixelSize: 11
                            color: modelData.desc !== "" ? Theme.text : Theme.subtext0
                            elide: Text.ElideRight
                        }

                        // Reset (only when overridden)
                        Text {
                            visible: bindRow.ov !== null
                            text: "󰦛"
                            font.family: Theme.fontIcon; font.pixelSize: 13
                            color: resetMa.containsMouse ? Theme.red : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            MouseArea {
                                id: resetMa
                                anchors.fill: parent; anchors.margins: -6
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.resetKeybind(modelData.key, modelData.rest)
                            }
                        }

                        // Edit / lock
                        Text {
                            text: modelData.editable ? (bindRow.editing ? "󰅖" : "󰏫") : "󰌾"
                            font.family: Theme.fontIcon; font.pixelSize: 13
                            color: modelData.editable
                                ? (editMa.containsMouse ? Theme.primary : Theme.subtext0)
                                : Qt.alpha(Theme.subtext0, 0.4)
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            MouseArea {
                                id: editMa
                                anchors.fill: parent; anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: modelData.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (!modelData.editable) return;
                                    if (bindRow.editing) {
                                        page.editingIndex = -1;
                                    } else {
                                        page.editingIndex = index;
                                        keyInput.text = bindRow.shownKey;
                                        keyInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    // Edit row
                    RowLayout {
                        visible: bindRow.editing
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 10
                            color: Theme.background
                            border.color: Theme.primary
                            border.width: 1
                            TextInput {
                                font.family: Theme.fontFamily;
                                id: keyInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 12
                                color: Theme.text
                                clip: true
                                selectByMouse: true
                                onAccepted: {
                                    if (text.trim() === "") return;
                                    Settings.overrideKeybind(modelData.key, text.trim(), modelData.rest);
                                    page.editingIndex = -1;
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 28
                            radius: 10
                            color: applyMa.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Text {
                                font.family: Theme.fontFamily;
                                anchors.centerIn: parent
                                text: "Bind"
                                font.pixelSize: 11; font.bold: true
                                color: Theme.background
                            }
                            MouseArea {
                                id: applyMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (keyInput.text.trim() === "") return;
                                    Settings.overrideKeybind(modelData.key, keyInput.text.trim(), modelData.rest);
                                    page.editingIndex = -1;
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}
