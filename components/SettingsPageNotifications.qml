import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../core"

// Notification centre settings. Edits Settings.conf.notifications only; the
// shell's core/Notifs.qml picks changes up through settings.json. Deliberately
// never touches the Notifs singleton — loading it here would start a second
// notification server inside the settings process.
CfgPage {
    id: page

    readonly property var conf: Settings.conf.notifications

    function hourOf(hm) {
        const h = parseInt(String(hm || "").split(":")[0]);
        return isNaN(h) ? 0 : Math.max(0, Math.min(23, h));
    }
    function hm(h) {
        return (h < 10 ? "0" : "") + h + ":00";
    }

    function setRule(appName, flag, value) {
        const all = JSON.parse(JSON.stringify(page.conf.appRules || {}));
        const r = all[appName] || {};
        r[flag] = value;
        if (!r.noFlash && !r.noStore && !r.allowInDnd) delete all[appName];
        else all[appName] = r;
        Settings.conf.notifications.appRules = all;
    }

    // Apps to offer rules for: everything seen in saved history plus anything
    // that already has a rule, alphabetical.
    FileView {
        id: historyFile
        path: Paths.notificationsFile
        adapter: JsonAdapter {
            id: history
            property var records: []
        }
    }
    readonly property var apps: {
        const names = new Set(Object.keys(page.conf.appRules || {}));
        for (const r of (history.records || [])) if (r.appName) names.add(r.appName);
        return Array.from(names).sort((a, b) => a.localeCompare(b));
    }

    CfgSection {
        title: "Do Not Disturb"
        icon: "󰂛"

        CfgSwitch {
            icon: "󰂛"
            text: "Do not disturb"
            hint: "Notifications still land in the centre, the pill just stays quiet. Critical ones always show."
            checked: page.conf.dnd
            onToggled: value => Settings.conf.notifications.dnd = value
        }
        CfgSwitch {
            icon: "󰊴"
            text: "Automatically while gaming"
            hint: "Whenever a game session is detected (Steam, Heroic, gamemode)"
            checked: page.conf.dndDuringGames
            onToggled: value => Settings.conf.notifications.dndDuringGames = value
        }
        CfgSwitch {
            icon: "󰊓"
            text: "Automatically in fullscreen"
            hint: "When the focused monitor shows a fullscreen window"
            checked: page.conf.dndWhenFullscreen
            onToggled: value => Settings.conf.notifications.dndWhenFullscreen = value
        }
        CfgSwitch {
            icon: "󰔛"
            text: "On a schedule"
            checked: page.conf.dndScheduleEnabled
            onToggled: value => Settings.conf.notifications.dndScheduleEnabled = value
        }
        CfgSpin {
            visible: page.conf.dndScheduleEnabled
            icon: "󰖔"
            text: "From (hour)"
            from: 0; to: 23
            value: page.hourOf(page.conf.dndFrom)
            onEdited: v => Settings.conf.notifications.dndFrom = page.hm(v)
        }
        CfgSpin {
            visible: page.conf.dndScheduleEnabled
            icon: "󰖙"
            text: "Until (hour)"
            from: 0; to: 23
            value: page.hourOf(page.conf.dndTo)
            onEdited: v => Settings.conf.notifications.dndTo = page.hm(v)
        }
    }

    CfgSection {
        title: "Per-App Rules"
        icon: "󰀻"

        CfgNotice {
            visible: page.apps.length === 0
            text: "Apps show up here once they have sent a notification."
        }
        CfgNotice {
            visible: page.apps.length > 0
            text: "History keeps the last 7 days (up to 200 notifications) in ~/.local/state/wisp/notifications.json. \"Don't save content\" keeps only the app and title there."
        }

        Repeater {
            model: page.apps
            delegate: ColumnLayout {
                id: appBlock
                required property string modelData
                readonly property var rule: (page.conf.appRules || {})[modelData] || {}
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.leftMargin: 12; Layout.topMargin: 8
                    text: appBlock.modelData
                    font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true
                    color: Theme.text
                }
                CfgSwitch {
                    icon: "󰂜"
                    text: "Never flash in the pill"
                    checked: !!appBlock.rule.noFlash
                    onToggled: value => page.setRule(appBlock.modelData, "noFlash", value)
                }
                CfgSwitch {
                    icon: "󰈉"
                    text: "Don't save content in history"
                    checked: !!appBlock.rule.noStore
                    onToggled: value => page.setRule(appBlock.modelData, "noStore", value)
                }
                CfgSwitch {
                    icon: "󰂞"
                    text: "Allow during Do Not Disturb"
                    checked: !!appBlock.rule.allowInDnd
                    onToggled: value => page.setRule(appBlock.modelData, "allowInDnd", value)
                }
            }
        }
    }
}
