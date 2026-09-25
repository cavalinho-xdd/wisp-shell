import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../core"
import "../core/notif_rules.js" as Rules

// Notification centre: live notifications grouped by app (Android/caelestia/
// ii-dots style), swipe-to-dismiss, click to open, action pills, inline reply;
// below them a searchable "Earlier" history. All state lives in core/Notifs.qml
// — this card only renders records and calls back into it.
Rectangle {
    id: root
    radius: 20
    color: Theme.surface

    // { appName: true } for groups the user expanded
    property var expandedGroups: ({})
    property bool historyOpen: false
    property string historyQuery: ""

    function toggleGroup(appName) {
        let g = Object.assign({}, expandedGroups);
        g[appName] = !g[appName];
        expandedGroups = g;
    }

    function urgencyColor(rec) {
        if (!rec) return Theme.primary;
        if (rec.urgency === NotificationUrgency.Critical) return Theme.red;
        if (rec.urgency === NotificationUrgency.Low) return Theme.surface0;
        return Theme.primary;
    }

    readonly property var groups: Rules.groupByApp(Notifs.liveRecords)
    readonly property var history: Notifs.historyRecords.filter(r => Rules.matches(r, root.historyQuery))

    readonly property string dndLabel: ({
        manual: "Do not disturb",
        game: "Do not disturb · game",
        fullscreen: "Do not disturb · fullscreen",
        schedule: "Do not disturb · scheduled"
    })[Notifs.dndReason] || ""

    Flickable {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: notifBottomBar.top
        anchors.margins: 12; anchors.bottomMargin: 4
        contentWidth: width
        contentHeight: groupCol.implicitHeight
        clip: true
        interactive: contentHeight > height

        Column {
            id: groupCol
            width: parent.width
            spacing: 8

            Repeater {
                model: root.groups
                delegate: NotifGroupCard { required property var modelData; width: groupCol.width; group: modelData }
            }

            Text {
                font.family: Theme.fontFamily
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 24; bottomPadding: 24
                text: "No new notifications"
                font.pixelSize: 13; color: Theme.subtext0
                visible: Notifs.liveRecords.length === 0
            }

            // ── Earlier: closed/expired notifications, persisted across restarts ──
            Rectangle {
                visible: Notifs.historyRecords.length > 0
                width: parent.width
                radius: 16
                color: Theme.surface0
                implicitHeight: histInner.implicitHeight + 24

                ColumnLayout {
                    id: histInner
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            font.family: Theme.fontFamily; text: "Earlier"; font.pixelSize: 12; font.bold: true; color: Theme.subtext0; Layout.fillWidth: true }
                        Text {
                            text: "󰆴"; font.family: Theme.fontIcon; font.pixelSize: 14
                            visible: root.historyOpen
                            color: clearHistMa.containsMouse ? Theme.red : Theme.subtext0
                            MouseArea { id: clearHistMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearHistory() }
                        }
                        Rectangle {
                            width: histChev.implicitWidth + 16; height: 22; radius: 11
                            color: Theme.surface
                            RowLayout {
                                id: histChev
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    font.family: Theme.fontFamily; text: Notifs.historyRecords.length; font.pixelSize: 11; color: Theme.text }
                                Text {
                                    text: "󰅀"
                                    font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.text
                                    rotation: root.historyOpen ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: Theme.animFast } }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.historyOpen = !root.historyOpen }
                        }
                    }

                    // Search
                    Rectangle {
                        visible: root.historyOpen
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 10
                        color: Theme.surface
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.subtext0
                        }
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 32; anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.text
                            clip: true
                            onTextChanged: root.historyQuery = text
                            Keys.onEscapePressed: text = ""
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text === ""
                                text: "Search history"
                                font: searchInput.font; color: Theme.subtext0
                            }
                        }
                    }

                    Column {
                        visible: root.historyOpen
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: root.historyOpen ? root.history : []
                            delegate: NotifRow { required property var modelData; width: parent.width; rec: modelData; showAppIcon: true }
                        }
                        Text {
                            visible: root.history.length === 0
                            font.family: Theme.fontFamily; text: "Nothing matches"; font.pixelSize: 12; color: Theme.subtext0
                        }
                    }
                }
            }
        }
    }

    // Bottom Action Bar
    Item {
        id: notifBottomBar
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 48

        // DND Toggle — the manual switch; auto triggers (game, fullscreen,
        // schedule) show in the label but are configured in Settings > Notifications.
        MouseArea {
            id: dndMa
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 32; height: 32; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Notifs.setDnd(!Notifs.conf.dnd)
            Text {
                anchors.centerIn: parent
                text: Notifs.dnd ? "󰂛" : "󰂚"
                font.family: Theme.fontIcon
                color: Notifs.dnd ? Theme.red : (dndMa.containsMouse ? Theme.text : Theme.subtext0)
                font.pixelSize: 16
                scale: dndMa.pressed ? 0.85 : (dndMa.containsMouse ? 1.2 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        Text {
            font.family: Theme.fontFamily;
            anchors.centerIn: parent
            readonly property int count: Notifs.liveRecords.length
            text: root.dndLabel !== "" ? root.dndLabel : (count + (count === 1 ? " notification" : " notifications"))
            font.pixelSize: 13; color: root.dndLabel !== "" ? Theme.red : Theme.subtext0
        }

        // Clear All — closes every live notification; they drop into "Earlier".
        MouseArea {
            id: clearMa
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 32; height: 32; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                if (Notifs.liveRecords.length === 0) return;
                clearSweep.restart();
                clearAllAnim.restart();
            }
            SequentialAnimation {
                id: clearAllAnim
                ParallelAnimation {
                    NumberAnimation { target: groupCol; property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutQuad }
                    NumberAnimation { target: groupCol; property: "x"; to: 80; duration: 200; easing.type: Easing.InQuad }
                }
                ScriptAction {
                    script: {
                        root.expandedGroups = {};
                        Notifs.dismissAll();
                        groupCol.opacity = 1;
                        groupCol.x = 0;
                    }
                }
            }
            Text {
                id: clearIcon
                anchors.centerIn: parent
                text: "󰧧"
                font.family: Theme.fontIcon
                color: clearMa.containsMouse ? Theme.text : Theme.subtext0
                font.pixelSize: 16
                scale: clearMa.pressed ? 0.85 : (clearMa.containsMouse ? 1.2 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                // Broom sweep on click
                SequentialAnimation {
                    id: clearSweep
                    NumberAnimation { target: clearIcon; property: "rotation"; to: -25; duration: 90; easing.type: Easing.OutQuad }
                    NumberAnimation { target: clearIcon; property: "rotation"; to: 15; duration: 120 }
                    NumberAnimation { target: clearIcon; property: "rotation"; to: 0; duration: 150; easing.type: Easing.OutBack }
                }
            }
        }
    }

    // ── One app's notifications: single card when there's just one, a
    // collapsible stack (Android-style) when there's more. ──
    component NotifGroupCard: Rectangle {
        id: groupCard
        property var group // { appName, records }
        readonly property bool multi: group.records.length > 1
        readonly property bool expanded: root.expandedGroups[group.appName] === true

        radius: 16
        color: Theme.surface0
        clip: true
        implicitHeight: inner.implicitHeight + 24
        Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        ColumnLayout {
            id: inner
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            RowLayout {
                visible: groupCard.multi
                Layout.fillWidth: true
                spacing: 8
                Text {
                    font.family: Theme.fontFamily; text: groupCard.group.appName; font.pixelSize: 12; font.bold: true; color: Theme.subtext0; Layout.fillWidth: true; elide: Text.ElideRight }
                Text {
                    font.family: Theme.fontFamily; text: Notifs.relTime(groupCard.group.records[0].time); font.pixelSize: 11; color: Theme.subtext0 }
                Rectangle {
                    width: chevRow.implicitWidth + 16; height: 22; radius: 11
                    color: Theme.surface
                    RowLayout {
                        id: chevRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            font.family: Theme.fontFamily; text: groupCard.group.records.length; font.pixelSize: 11; color: Theme.text }
                        Text {
                            text: "󰅀"
                            font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.text
                            rotation: groupCard.expanded ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: Theme.animFast } }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleGroup(groupCard.group.appName) }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: groupCard.multi && !groupCard.expanded ? [groupCard.group.records[0]] : groupCard.group.records
                    delegate: NotifRow { required property var modelData; width: parent.width; rec: modelData; showAppIcon: !groupCard.multi }
                }
            }
        }
    }

    // ── A single swipeable notification row. Live rows get actions and an
    // inline reply box; history rows are plain text. ──
    component NotifRow: Item {
        id: notifRow
        property var rec
        property bool showAppIcon: true
        // The live Notification behind this record, or null once closed.
        readonly property var n: rec && rec.live ? Notifs.live(rec.key) : null
        implicitHeight: rowBg.implicitHeight

        function commitDismiss(sign) {
            dismissAnim.sign = sign;
            dismissAnim.start();
        }

        SequentialAnimation {
            id: dismissAnim
            property int sign: 1
            NumberAnimation { target: rowBg; property: "x"; to: notifRow.width * 1.2 * dismissAnim.sign; duration: 180; easing.type: Easing.InQuad }
            ScriptAction { script: if (notifRow.rec) Notifs.dismiss(notifRow.rec.key) }
        }

        Rectangle {
            id: rowBg
            width: parent.width
            radius: 12
            color: dragArea.containsMouse && !dragArea.drag.active ? Qt.lighter(Theme.surface, 1.15) : Theme.surface
            implicitHeight: content.implicitHeight + 16
            opacity: 1 - Math.min(Math.abs(x) / width, 1) * 0.7

            Behavior on x { enabled: !dragArea.drag.active && !dismissAnim.running; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Rectangle {
                width: 3; radius: 1.5
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 8
                color: root.urgencyColor(notifRow.rec)
            }

            // Swipe to dismiss; a click without a swipe opens the notification.
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                drag.target: rowBg
                drag.axis: Drag.XAxis
                drag.minimumX: -width
                drag.maximumX: width
                property bool swiped: false
                onPressed: swiped = false
                onPositionChanged: if (Math.abs(rowBg.x) > 6) swiped = true
                onReleased: {
                    if (Math.abs(rowBg.x) > 90) {
                        notifRow.commitDismiss(rowBg.x > 0 ? 1 : -1);
                    } else {
                        rowBg.x = 0;
                    }
                }
                onClicked: if (!swiped && notifRow.rec) Notifs.activate(notifRow.rec.key)
            }

            ColumnLayout {
                id: content
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 8; anchors.leftMargin: 15
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        visible: notifRow.showAppIcon
                        width: 32; height: 32; radius: 16; clip: true
                        color: root.urgencyColor(notifRow.rec)

                        readonly property string img: notifRow.rec ? (notifRow.rec.image || "") : ""
                        readonly property string icon: notifRow.rec ? (notifRow.rec.appIcon || "") : ""

                        Image {
                            anchors.fill: parent
                            visible: parent.img !== ""
                            source: parent.img
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; cache: false
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 18
                            visible: parent.img === "" && parent.icon !== ""
                            source: visible ? Quickshell.iconPath(parent.icon) : ""
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: parent.img === "" && parent.icon === ""
                            text: "󰂚"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.background
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            font.family: Theme.fontFamily; text: notifRow.rec ? (notifRow.rec.summary || notifRow.rec.appName) : ""; font.pixelSize: 13; font.bold: true; color: Theme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontFamily
                            text: !notifRow.rec ? "" : (notifRow.rec.redacted ? "Content not saved" : notifRow.rec.body)
                            font.pixelSize: 12; font.italic: !!notifRow.rec && notifRow.rec.redacted
                            color: Theme.subtext0; elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== "" }
                    }

                    Text {
                        font.family: Theme.fontFamily; text: notifRow.rec ? Notifs.relTime(notifRow.rec.time) : ""; font.pixelSize: 11; color: Theme.subtext0 }

                    Text {
                        text: "󰅗"; font.family: Theme.fontIcon; color: Theme.subtext0; font.pixelSize: 15
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: { if (notifRow.rec) notifRow.commitDismiss(1) } }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    readonly property var visibleActions: {
                        const out = [];
                        const acts = notifRow.n ? notifRow.n.actions : [];
                        // "default" is what a row click does — no separate pill for it.
                        for (let i = 0; i < acts.length; i++)
                            if (acts[i].identifier !== "default") out.push(acts[i]);
                        return out;
                    }
                    visible: visibleActions.length > 0

                    Repeater {
                        model: parent.visibleActions
                        delegate: Rectangle {
                            required property var modelData
                            radius: 10; height: 26
                            width: actLabel.implicitWidth + 20
                            color: Theme.surface0
                            Text {
                                font.family: Theme.fontFamily; id: actLabel; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 11; color: Theme.text }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                        }
                    }
                }

                // Inline reply (e.g. messengers that support it)
                Rectangle {
                    visible: !!notifRow.n && notifRow.n.hasInlineReply
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 10
                    color: Theme.surface0
                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 30
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.text
                        clip: true
                        function send() {
                            if (!notifRow.rec) return;
                            Notifs.reply(notifRow.rec.key, text);
                            text = "";
                        }
                        onAccepted: send()
                        Keys.onEscapePressed: text = ""
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: replyInput.text === ""
                            text: (notifRow.n && notifRow.n.inlineReplyPlaceholder) || "Reply…"
                            font: replyInput.font; color: Theme.subtext0
                        }
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        text: "󰒊"; font.family: Theme.fontIcon; font.pixelSize: 14
                        color: replyInput.text !== "" ? Theme.primary : Theme.subtext0
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: replyInput.send() }
                    }
                }
            }
        }
    }
}
