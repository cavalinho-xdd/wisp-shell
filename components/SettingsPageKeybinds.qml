import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Lists the user's real Hyprland lua keybinds (parsed read-only from
// ~/.config/hypr/**/*.lua by scripts/keybinds_list.sh) and lets editable ones
// be rebound: scripts/apply_hypr_keybind.py rewrites the matching
// hl.bind("<key>", ...) line in place, in whichever real dotfile declares it,
// then Settings.qml reloads Hyprland. This is a direct, permanent edit to the
// user's own file — not a runtime-only override that a reload would undo.
// keybindOverrides in settings.json is kept only so this page can show which
// rows changed and offer a per-row reset (writes the original key back).
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

    // ── Add-keybind action catalog ──
    // A curated, foolproof subset of hl.dsp.* — the user picks what the bind
    // does from a list instead of writing Lua. Every shape here is copied
    // verbatim from a call already live in this machine's own keybinds.lua
    // (window.close/float/move, focus, layout) or /usr/share/hypr/stubs/
    // hl.meta.lua (window.fullscreen, exec_cmd) — nothing guessed.
    readonly property var actions: [
        { id: "exec", label: "Launch app / run command", icon: "󰆍", arg: "command" },
        { id: "close", label: "Close active window", icon: "󰅖", arg: "none" },
        { id: "float", label: "Toggle floating", icon: "󰹙", arg: "none" },
        { id: "fullscreen", label: "Toggle fullscreen", icon: "󰊓", arg: "none" },
        { id: "focusDir", label: "Move focus", icon: "󰁕", arg: "direction" },
        { id: "gotoWs", label: "Switch to workspace", icon: "󰎥", arg: "workspace" },
        { id: "moveWs", label: "Move window to workspace", icon: "󰌱", arg: "workspace" },
        { id: "togglesplit", label: "Toggle split", icon: "󰤱", arg: "none" }
    ]

    function actionById(id) { return page.actions.find(a => a.id === id) || page.actions[0]; }

    function buildLuaExpr(actionId, arg) {
        const esc = s => String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        switch (actionId) {
            case "exec": return 'hl.dsp.exec_cmd("' + esc(arg) + '")';
            case "close": return "hl.dsp.window.close()";
            case "float": return 'hl.dsp.window.float({ action = "toggle" })';
            case "fullscreen": return 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })';
            case "focusDir": return 'hl.dsp.focus({ direction = "' + arg + '" })';
            case "gotoWs": return "hl.dsp.focus({ workspace = " + arg + " })";
            case "moveWs": return "hl.dsp.window.move({ workspace = " + arg + " })";
            case "togglesplit": return 'hl.dsp.layout("togglesplit")';
        }
        return "";
    }

    function defaultDescription(actionId, arg) {
        switch (actionId) {
            case "exec": return arg ? ("Run: " + arg) : "Run command";
            case "close": return "Close active window";
            case "float": return "Toggle floating";
            case "fullscreen": return "Toggle fullscreen";
            case "focusDir": return arg ? ("Focus " + arg) : "Move focus";
            case "gotoWs": return arg ? ("Switch to workspace " + arg) : "Switch workspace";
            case "moveWs": return arg ? ("Move window to workspace " + arg) : "Move window to workspace";
            case "togglesplit": return "Toggle split";
        }
        return "";
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
        text: "Your real binds from ~/.config/hypr — rebinding here edits that file directly (then reloads Hyprland). Locked rows dispatch through a named lua function rather than a plain hl.dsp.* call, so they're left alone as a safety margin. Use Reset on a changed row to put the original key back."
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

    // ── Add keybind ──
    CfgSection {
        title: "Add keybind"
        icon: "󰐕"

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.preferredHeight: addForm.implicitHeight + 24
            radius: 14
            color: Theme.surface0
            Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }

            ColumnLayout {
                id: addForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // ── Key capture: press the real combo instead of typing it ──
                Rectangle {
                    id: captureBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 12
                    color: captureArea.activeFocus ? Qt.alpha(Theme.primary, 0.12) : Theme.background
                    border.color: captureArea.activeFocus ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    property var capturedMods: []
                    property string capturedKey: ""
                    function reset() { capturedMods = []; capturedKey = ""; }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Row {
                            spacing: 4
                            Repeater {
                                model: captureBox.capturedMods
                                delegate: Rectangle {
                                    width: modCapText.implicitWidth + 12; height: 22; radius: 6
                                    color: Theme.primary
                                    Text {
                                        id: modCapText
                                        font.family: Theme.fontFamily
                                        anchors.centerIn: parent; text: modelData
                                        font.pixelSize: 10; font.bold: true; color: Theme.background
                                    }
                                }
                            }
                            Rectangle {
                                visible: captureBox.capturedKey !== ""
                                width: keyCapText.implicitWidth + 12; height: 22; radius: 6
                                color: Theme.primary
                                Text {
                                    id: keyCapText
                                    font.family: Theme.fontFamily
                                    anchors.centerIn: parent; text: captureBox.capturedKey
                                    font.pixelSize: 10; font.bold: true; color: Theme.background
                                }
                            }
                        }
                        Text {
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: 11
                            color: Theme.subtext0
                            text: captureArea.activeFocus
                                ? "Press your key combo…"
                                : (captureBox.capturedKey === "" ? "Click, then press a key combo" : "Click to capture again")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: captureArea.forceActiveFocus()
                    }

                    // Only catches keys while the box itself is focused — never
                    // steals input from the rest of the settings app. Modifiers
                    // are read off event.modifiers (not raw keycodes), so Super/
                    // Ctrl/Alt/Shift all register the same way regardless of
                    // left/right variant.
                    Item {
                        id: captureArea
                        anchors.fill: parent
                        focus: false
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) { captureArea.focus = false; event.accepted = true; return; }
                            let mods = [];
                            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");
                            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                            captureBox.capturedMods = mods;
                            const isModOnly = [Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Control,
                                Qt.Key_Alt, Qt.Key_Shift, Qt.Key_Meta, Qt.Key_CapsLock].includes(event.key);
                            if (isModOnly) { event.accepted = true; return; }
                            let k = "";
                            if (event.key === Qt.Key_Space) k = "SPACE";
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) k = "RETURN";
                            else if (event.key === Qt.Key_Tab) k = "TAB";
                            else if (event.key === Qt.Key_Left) k = "left";
                            else if (event.key === Qt.Key_Right) k = "right";
                            else if (event.key === Qt.Key_Up) k = "up";
                            else if (event.key === Qt.Key_Down) k = "down";
                            else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) k = "F" + (event.key - Qt.Key_F1 + 1);
                            else if (event.text && event.text.trim().length > 0) k = event.text.toUpperCase();
                            else k = event.key.toString();
                            captureBox.capturedKey = k;
                            event.accepted = true;
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    font.family: Theme.fontFamily
                    text: "Combos already bound to something else won't reach this box — Hyprland handles those first."
                    font.pixelSize: 10
                    color: Qt.alpha(Theme.subtext0, 0.7)
                    wrapMode: Text.WordWrap
                }

                // ── What the keybind does ──
                Text { font.family: Theme.fontFamily; text: "Action"; font.pixelSize: 11; font.bold: true; color: Theme.subtext0 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: page.actions
                        delegate: Rectangle {
                            readonly property bool active: addForm.selectedAction === modelData.id
                            width: actRow.implicitWidth + 20
                            height: 30
                            radius: 10
                            color: active ? Qt.alpha(Theme.primary, 0.22) : Theme.background
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Row {
                                id: actRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 12; color: active ? Theme.primary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    font.family: Theme.fontFamily
                                    text: modelData.label
                                    font.pixelSize: 11
                                    color: active ? Theme.primary : Theme.text
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addForm.selectedAction = modelData.id
                            }
                        }
                    }
                }

                // ── Argument, shape depends on the chosen action ──
                property string selectedAction: "exec"
                property string argValue: ""

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    visible: page.actionById(addForm.selectedAction).arg === "command"
                    radius: 10
                    color: Theme.background
                    border.color: cmdInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                    TextInput {
                        id: cmdInput
                        font.family: Theme.fontFamily
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12
                        color: Theme.text
                        clip: true
                        selectByMouse: true
                        onTextChanged: addForm.argValue = text
                        Text {
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Command, e.g. kitty, firefox, flameshot gui…"
                            font.pixelSize: 12
                            color: Qt.alpha(Theme.subtext0, 0.6)
                            visible: cmdInput.text === "" && !cmdInput.activeFocus
                        }
                    }
                }

                Row {
                    visible: page.actionById(addForm.selectedAction).arg === "direction"
                    spacing: 6
                    Repeater {
                        model: [ { id: "l", label: "←" }, { id: "d", label: "↓" }, { id: "u", label: "↑" }, { id: "r", label: "→" } ]
                        delegate: Rectangle {
                            readonly property bool active: addForm.argValue === modelData.id
                            width: 34; height: 30; radius: 10
                            color: active ? Qt.alpha(Theme.primary, 0.22) : Theme.background
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 14
                                color: active ? Theme.primary : Theme.text
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: addForm.argValue = modelData.id }
                        }
                    }
                }

                CfgSpin {
                    visible: page.actionById(addForm.selectedAction).arg === "workspace"
                    Layout.leftMargin: 0
                    Layout.rightMargin: 0
                    icon: "󰎦"
                    text: "Workspace"
                    value: addForm.argValue === "" ? 1 : parseInt(addForm.argValue)
                    from: 1; to: 10
                    onEdited: v => addForm.argValue = String(v)
                }

                // ── Description (shown in the bind list; auto-filled if left blank) ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 10
                    color: Theme.background
                    border.color: descInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                    TextInput {
                        id: descInput
                        font.family: Theme.fontFamily
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12
                        color: Theme.text
                        clip: true
                        selectByMouse: true
                        Text {
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Description (optional)"
                            font.pixelSize: 12
                            color: Qt.alpha(Theme.subtext0, 0.6)
                            visible: descInput.text === "" && !descInput.activeFocus
                        }
                    }
                }

                // ── Validation + Add ──
                readonly property string keyStr: captureBox.capturedKey === "" ? "" :
                    (captureBox.capturedMods.length ? captureBox.capturedMods.join(" + ") + " + " : "") + captureBox.capturedKey
                readonly property string validationError: {
                    const act = page.actionById(addForm.selectedAction);
                    if (captureBox.capturedKey === "") return "Capture a key combo first.";
                    if (act.arg === "command" && addForm.argValue.trim() === "") return "Enter a command to run.";
                    if (act.arg === "direction" && addForm.argValue === "") return "Pick a direction.";
                    const normKey = addForm.keyStr.toLowerCase();
                    const dupExisting = page.binds.some(b => b.key.toLowerCase() === normKey);
                    const dupCustom = (Settings.conf.customKeybinds || []).some(b =>
                        ((b.mods && b.mods.length ? b.mods.join(" + ") + " + " : "") + b.key).toLowerCase() === normKey);
                    if (dupExisting || dupCustom) return "That combo is already bound to something.";
                    return "";
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        text: addForm.validationError
                        font.pixelSize: 11
                        color: Theme.red
                        wrapMode: Text.WordWrap
                        visible: addForm.validationError !== "" && captureBox.capturedKey !== ""
                    }
                    Rectangle {
                        readonly property bool valid: addForm.validationError === ""
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 32
                        radius: 12
                        opacity: valid ? 1.0 : 0.4
                        color: addMa.containsMouse && valid ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        Text {
                            font.family: Theme.fontFamily
                            anchors.centerIn: parent
                            text: "Add"
                            font.pixelSize: 12; font.bold: true
                            color: Theme.background
                        }
                        MouseArea {
                            id: addMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: parent.valid ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!parent.valid) return;
                                const act = page.actionById(addForm.selectedAction);
                                Settings.addCustomKeybind({
                                    mods: captureBox.capturedMods,
                                    key: captureBox.capturedKey,
                                    actionId: act.id,
                                    actionArg: addForm.argValue,
                                    luaExpr: page.buildLuaExpr(act.id, addForm.argValue),
                                    description: descInput.text.trim() !== "" ? descInput.text.trim() : page.defaultDescription(act.id, addForm.argValue)
                                });
                                captureBox.reset();
                                addForm.argValue = "";
                                cmdInput.text = "";
                                descInput.text = "";
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Custom keybinds you've added ──
    CfgSection {
        title: "Your custom keybinds"
        icon: "󰌌"
        visible: (Settings.conf.customKeybinds || []).length > 0

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: Settings.conf.customKeybinds || []
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 12
                    color: customRowMa.containsMouse ? Qt.alpha(Theme.surface0, 0.6) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        KeyCaps { combo: (modelData.mods && modelData.mods.length ? modelData.mods.join(" + ") + " + " : "") + modelData.key }

                        Text {
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                            text: modelData.description || modelData.luaExpr
                            font.pixelSize: 11
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰆴"
                            font.family: Theme.fontIcon; font.pixelSize: 13
                            color: delCustomMa.containsMouse ? Theme.red : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            MouseArea {
                                id: delCustomMa
                                anchors.fill: parent; anchors.margins: -6
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.removeCustomKeybind(index)
                            }
                        }
                    }

                    MouseArea { id: customRowMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
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
