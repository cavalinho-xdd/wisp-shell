import QtQuick

// Test harness, never installed: loads the theme's Main.qml and puts it in
// the state named by `preview=` in the scratch copy's theme.conf, so
// check-greeter.sh can screenshot states that need typing or clicks.
Item {
    id: preview
    width: 1920
    height: 1080

    Loader {
        id: main
        anchors.fill: parent
        source: "Main.qml"
    }

    Timer {
        interval: 1500
        running: main.status === Loader.Ready
        onTriggered: {
            const m = main.item;
            // Test mode has no daemon: it can do nothing and has no layouts.
            if (String(config.previewCan) === "true") {
                m.powerIsland.canSuspend = m.powerIsland.canReboot = m.powerIsland.canPowerOff = true;
                m.layoutText = "cs";
            }
            switch (String(config.preview)) {
            case "typing": m.password = "wisp-ember"; break;
            case "caps": m.password = "wisp"; m.capsLock = true; break;
            // Test mode never answers a login, so play the daemon's reply.
            case "failed": m.password = "wrong"; m.login(); m.loginFailed(); break;
            case "nopass":
                m.login();
                console.log("PREVIEW empty login, password needed: busy=" + m.busy);
                m.needsPassword = false;
                m.login();
                console.log("PREVIEW empty login, no password: busy=" + m.busy);
                break;
            case "leaving": m.password = "wisp"; m.login(); m.loginSucceeded(); break;
            case "menu": m.sessionMenuOpen = true; break;
            case "ask": m.powerAsk("powerOff"); break;
            case "info": console.log("PREVIEW can", sddm.canSuspend, sddm.canReboot, sddm.canPowerOff, "layouts", keyboard ? keyboard.layouts.length : "none", "layout", m.layoutText); break;
            }
        }
    }
}
