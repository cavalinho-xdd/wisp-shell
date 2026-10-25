import QtQuick
import "../../core"

// Bluetooth orb: the first connected device with its battery, and counts.
OrbView {
    id: orb

    readonly property var device: Connectivity.btConnected.length > 0 ? Connectivity.btConnected[0] : null
    readonly property bool audio: !!device && /head|audio/i.test(device.icon)

    title: "Bluetooth"
    on: Connectivity.btEnabled
    icon: !on ? "󰂲" : (device ? (audio ? "󰋋" : "󰂱") : "󰂯")
    name: !on ? "Bluetooth is off" : (device ? device.name : "Not connected")
    status: !on ? "" : (device ? "Connected" : "Choose a device")
    facts: [
        { label: "Battery", value: device && device.batteryAvailable ? Math.round(device.battery * 100) + " %" : "–" },
        { label: "Connected", value: String(Connectivity.btConnected.length) },
        { label: "Paired", value: String(Connectivity.btDevices.filter(d => d.paired).length) }
    ]
    moreLabel: "All devices"
    moreCount: Connectivity.btDevices.length
    onSwitched: Connectivity.toggleBluetooth()
}
