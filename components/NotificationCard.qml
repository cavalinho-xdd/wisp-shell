import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../core"

// Notification centre: groups by app (Android/caelestia/ii-dots style), swipe-to-dismiss,
// per-notification action pills, relative timestamps. Inspired by caelestia-dots'
// services/NotifData.qml + modules/sidebar/Notif*.qml and ii-dots' NotificationGroup.qml.
Rectangle {
    id: root
    radius: 20
    color: Theme.surface

    property bool dndEnabled: false
    // { appName: true } for groups the user expanded
    property var expandedGroups: ({})
    property int tick: 0

    function toggleGroup(appName) {
        let g = Object.assign({}, expandedGroups);
        g[appName] = !g[appName];
        expandedGroups = g;
    }

    function relTime(id) {
        root.tick; // dependency: forces re-eval every tick
        const t = Notifs.arrivalTimes[id];
        if (t === undefined) return "";
        const diffMin = Math.floor((Date.now() - t) / 60000);
        if (diffMin < 1) return "now";
        if (diffMin < 60) return diffMin + "m";
        const diffH = Math.floor(diffMin / 60);
        if (diffH < 24) return diffH + "h";
        return Math.floor(diffH / 24) + "d";
    }

    function urgencyColor(n) {
        if (!n) return Theme.primary;
        if (n.urgency === NotificationUrgency.Critical) return Theme.red;
        if (n.urgency === NotificationUrgency.Low) return Theme.surface0;
        return Theme.primary;
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.tick++ }

    // Server lives in the Notifs singleton — it must exist even while the
    // pill is collapsed (island flash), and this card only exists while
    // the dashboard is on the StackView.

    // Group tracked notifications by appName, most-recently-active app first.
    readonly property var groups: {
        const all = Notifs.server.trackedNotifications.values;
        const order = [];
        const byApp = {};
        for (const n of all) {
            const key = n.appName || "Notification";
            if (!byApp[key]) { byApp[key] = []; order.push(key); }
            byApp[key].push(n);
        }
        return order.slice().reverse().map(key => ({
            appName: key,
            notifs: byApp[key].slice().reverse()
        }));
    }

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
        }
    }

    Text {
        font.family: Theme.fontFamily;
        anchors.centerIn: parent
        text: "No notifications"
        font.pixelSize: 13; color: Theme.subtext0
        visible: Notifs.server.trackedNotifications.values.length === 0
    }

    // Bottom Action Bar
    Item {
        id: notifBottomBar
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 48

        // DND Toggle
        MouseArea {
            id: dndMa
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 32; height: 32; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                root.dndEnabled = !root.dndEnabled;
                Quickshell.execDetached(["bash", "-c", "echo '" + (root.dndEnabled ? "1" : "0") + "' > ~/.cache/dnd-state"]);
            }
            Text {
                anchors.centerIn: parent
                text: root.dndEnabled ? "󰂛" : "󰂚"
                font.family: Theme.fontIcon
                color: root.dndEnabled ? Theme.red : (dndMa.containsMouse ? Theme.text : Theme.subtext0)
                font.pixelSize: 16
                scale: dndMa.pressed ? 0.85 : (dndMa.containsMouse ? 1.2 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        Text {
            font.family: Theme.fontFamily;
            anchors.centerIn: parent
            readonly property int count: Notifs.server.trackedNotifications.values.length
            text: count + (count === 1 ? " notification" : " notifications")
            font.pixelSize: 13; color: Theme.subtext0
        }

        // Clear All
        MouseArea {
            id: clearMa
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 32; height: 32; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                clearSweep.restart();
                root.expandedGroups = {};
                let notifs = Notifs.server.trackedNotifications.values;
                for (let i = notifs.length - 1; i >= 0; i--) {
                    notifs[i].dismiss();
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
        property var group // { appName, notifs }
        readonly property bool multi: group.notifs.length > 1
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
                    font.family: Theme.fontFamily; text: root.relTime(groupCard.group.notifs[0].id); font.pixelSize: 11; color: Theme.subtext0 }
                Rectangle {
                    width: chevRow.implicitWidth + 16; height: 22; radius: 11
                    color: Theme.surface
                    RowLayout {
                        id: chevRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            font.family: Theme.fontFamily; text: groupCard.group.notifs.length; font.pixelSize: 11; color: Theme.text }
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
                    model: groupCard.multi && !groupCard.expanded ? [groupCard.group.notifs[0]] : groupCard.group.notifs
                    delegate: NotifRow { required property var modelData; width: parent.width; n: modelData; showAppIcon: !groupCard.multi }
                }
            }
        }
    }

    // ── A single swipeable notification row with actions. ──
    component NotifRow: Item {
        id: notifRow
        property var n
        property bool showAppIcon: true
        implicitHeight: rowBg.implicitHeight

        function commitDismiss(sign) {
            dismissAnim.sign = sign;
            dismissAnim.start();
        }

        SequentialAnimation {
            id: dismissAnim
            property int sign: 1
            NumberAnimation { target: rowBg; property: "x"; to: notifRow.width * 1.2 * dismissAnim.sign; duration: 180; easing.type: Easing.InQuad }
            ScriptAction { script: if (notifRow.n) notifRow.n.dismiss() }
        }

        Rectangle {
            id: rowBg
            width: parent.width
            radius: 12
            color: Theme.surface
            implicitHeight: content.implicitHeight + 16
            opacity: 1 - Math.min(Math.abs(x) / width, 1) * 0.7

            Behavior on x { enabled: !dragArea.drag.active && !dismissAnim.running; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

            Rectangle {
                width: 3; radius: 1.5
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 8
                color: root.urgencyColor(notifRow.n)
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: rowBg
                drag.axis: Drag.XAxis
                drag.minimumX: -width
                drag.maximumX: width
                onReleased: {
                    if (Math.abs(rowBg.x) > 90) {
                        notifRow.commitDismiss(rowBg.x > 0 ? 1 : -1);
                    } else {
                        rowBg.x = 0;
                    }
                }
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
                        color: root.urgencyColor(notifRow.n)

                        Image {
                            anchors.fill: parent
                            visible: notifRow.n && notifRow.n.image !== ""
                            source: notifRow.n ? notifRow.n.image : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; cache: false
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 18
                            visible: notifRow.n && notifRow.n.image === "" && notifRow.n.appIcon !== ""
                            source: (notifRow.n && notifRow.n.image === "" && notifRow.n.appIcon !== "") ? Quickshell.iconPath(notifRow.n.appIcon) : ""
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: notifRow.n && notifRow.n.image === "" && notifRow.n.appIcon === ""
                            text: "󰂚"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.background
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            font.family: Theme.fontFamily; text: notifRow.n ? (notifRow.n.summary || notifRow.n.appName) : ""; font.pixelSize: 13; font.bold: true; color: Theme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontFamily; text: notifRow.n ? notifRow.n.body : ""; font.pixelSize: 12; color: Theme.subtext0; elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== "" }
                    }

                    Text {
                        font.family: Theme.fontFamily; text: notifRow.n ? root.relTime(notifRow.n.id) : ""; font.pixelSize: 11; color: Theme.subtext0 }

                    Text {
                        text: "󰅗"; font.family: Theme.fontIcon; color: Theme.subtext0; font.pixelSize: 15
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: notifRow.n && notifRow.n.dismiss() }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: notifRow.n && notifRow.n.actions && notifRow.n.actions.length > 0

                    Repeater {
                        model: notifRow.n ? notifRow.n.actions : []
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
            }
        }
    }
}
