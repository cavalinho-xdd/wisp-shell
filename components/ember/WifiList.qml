import QtQuick
import "../../core"

// Visible Wi-Fi networks. Known and open ones connect with a click; new
// secured ones need a password, which is not supported yet.
ConnList {
    id: list

    readonly property var securityNames: ["Open", "WEP", "WPA-PSK", "WPA-EAP", "SAE"]

    title: "Wi‑Fi networks"
    emptyText: Connectivity.wifiEnabled ? "Searching…" : "Wi‑Fi is off"
    rows: Connectivity.networks.map(n => ({
        icon: n.signalStrength > 0.75 ? "󰤨" : (n.signalStrength > 0.5 ? "󰤥" : (n.signalStrength > 0.25 ? "󰤢" : "󰤟")),
        name: n.name,
        sub: n.connected ? "Connected" : (n.known ? "Saved" : (securityNames[n.security] ?? "")) + (!n.known && n.security !== 0 ? " · password needed" : ""),
        active: n.connected,
        enabled: n.connected || n.known || n.security === 0
    }))
    onPicked: index => {
        const n = Connectivity.networks[index];
        if (n.connected) n.disconnect();
        else n.connect();
    }

    // Scan while the list is on screen.
    Binding {
        target: Connectivity.wifiDevice
        property: "scannerEnabled"
        value: list.lit
        when: !!Connectivity.wifiDevice
    }
}
