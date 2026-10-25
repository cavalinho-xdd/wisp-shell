import QtQuick
import "../../core"

// Bluetooth devices: connected and paired first. A click connects or
// disconnects; unpaired devices are listed but not paired from here yet.
ConnList {
    id: list

    title: "Bluetooth devices"
    emptyText: Connectivity.btEnabled ? "Searching…" : "Bluetooth is off"
    rows: Connectivity.btDevices.map(d => ({
        icon: /head|audio/i.test(d.icon) ? "󰋋" : (d.connected ? "󰂱" : "󰂯"),
        name: d.name,
        sub: d.connected ? "Connected" + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + " %" : "") : (d.paired ? "Paired" : "Not paired"),
        active: d.connected,
        enabled: d.paired
    }))
    onPicked: index => {
        const d = Connectivity.btDevices[index];
        if (d.connected) d.disconnect();
        else d.connect();
    }

    Binding {
        target: Connectivity.btAdapter
        property: "discovering"
        value: list.lit
        when: !!Connectivity.btAdapter && Connectivity.btEnabled
    }
}
