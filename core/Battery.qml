pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// UPower facade. UPower.displayDevice is a synthetic aggregate device that
// always exists (verified in ~/coding/quickshell/src/services/upower/core.hpp)
// even on machines with no battery at all — gate on isLaptopBattery, not just
// isPresent/ready, so desktop hardware shows nothing instead of a fake 0%
// indicator (same principle plan.md's Scaling Notes already calls out for the
// GPU ring on non-Nvidia machines).
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!device && device.ready && device.isLaptopBattery
    readonly property real percentage: available ? device.percentage : 0
    readonly property int state: available ? device.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
        || state === UPowerDeviceState.PendingCharge
    readonly property bool fullyCharged: state === UPowerDeviceState.FullyCharged
    readonly property bool low: available && !charging && percentage <= 0.2
    readonly property bool critical: available && !charging && percentage <= 0.1
    // Seconds; 0 when not applicable (charging has no timeToEmpty, etc).
    readonly property real timeToEmpty: available ? device.timeToEmpty : 0
    readonly property real timeToFull: available ? device.timeToFull : 0

    function icon() {
        if (!available) return "";
        if (fullyCharged) return "󰁹";
        const p = percentage * 100;
        if (charging) {
            if (p >= 90) return "󰂅";
            if (p >= 80) return "󰂋";
            if (p >= 60) return "󰂉";
            if (p >= 40) return "󰢞";
            if (p >= 20) return "󰂆";
            return "󰢟";
        }
        if (p >= 95) return "󰁹";
        if (p >= 85) return "󰂂";
        if (p >= 75) return "󰂀";
        if (p >= 65) return "󰁿";
        if (p >= 55) return "󰁾";
        if (p >= 45) return "󰁽";
        if (p >= 35) return "󰁼";
        if (p >= 25) return "󰁻";
        if (p >= 15) return "󰁺";
        return "󰂎";
    }
}
