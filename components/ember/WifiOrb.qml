import QtQuick
import "../../core"

// Wi-Fi orb: what we are connected to, signal, security and how many networks
// are around.
OrbView {
    id: orb

    readonly property var net: Connectivity.network
    readonly property var securityNames: ["Open", "WEP", "WPA-PSK", "WPA-EAP", "SAE"]

    title: "Wi‑Fi"
    on: Connectivity.wifiEnabled
    icon: !on ? "󰖪" : (net ? "󰤨" : "󰤟")
    name: !on ? "Wi‑Fi is off" : (net ? net.name : "Not connected")
    status: !on ? "" : (net ? "Connected" : "Choose a network")
    facts: [
        { label: "Signal", value: net ? Math.round(net.signalStrength * 100) + " %" : "–" },
        { label: "Security", value: net ? (securityNames[net.security] ?? "–") : "–" },
        { label: "Networks", value: String(Connectivity.networks.length) }
    ]
    moreLabel: "Other networks"
    moreCount: Connectivity.networks.length
    onSwitched: Connectivity.toggleWifi()
}
