pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification state singleton. The DBus server must live here, not in
// NotificationCard: the card only exists while the dashboard is on the
// StackView, so a server inside it would deregister every time the pill
// collapses — exactly when the island flash needs notifications most.
//
// NB: while ii runs it owns org.freedesktop.Notifications, so this server
// fails to register (tracked in plan.md Big Future Task #1).
Singleton {
    id: root

    readonly property alias server: server

    // Notification has no timestamp property — track arrival locally.
    // Plain object, bumped via reassignment so bindings fire.
    property var arrivalTimes: ({})

    signal incoming(var notification)

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyImagesSupported: true
        onNotification: notification => {
            notification.tracked = true;
            const t = root.arrivalTimes;
            t[notification.id] = Date.now();
            root.arrivalTimes = t;
            root.incoming(notification);
        }
    }
}
