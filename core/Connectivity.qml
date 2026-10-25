pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

// Wi-Fi and Bluetooth state for the shell: one place to read what is on and
// what is connected. The views that change things (switches, scanning) still
// talk to Networking / Bluetooth directly.
Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    // `type` is constant, so reading it adds no binding dependency.
    readonly property var wifiDevice: {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === DeviceType.Wifi) ?? null;
    }
    readonly property var network: {
        if (!wifiEnabled || !wifiDevice) return null;
        return wifiDevice.networks.values.find(n => n.connected) ?? null;
    }
    readonly property bool wifiConnected: !!network

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: !!btAdapter && btAdapter.enabled
    readonly property var btConnected: btEnabled ? btAdapter.devices.values.filter(d => d.connected) : []

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth(): void {
        if (btAdapter) btAdapter.enabled = !btAdapter.enabled;
    }
}
