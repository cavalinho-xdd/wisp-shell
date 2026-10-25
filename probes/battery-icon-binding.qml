import QtQuick
import Quickshell
import Quickshell.Services.UPower

ShellRoot {
    property var dev: UPower.displayDevice
    
    QtObject {
        id: batt
        readonly property bool available: !!dev && dev.ready && dev.isLaptopBattery
        readonly property real percentage: available ? dev.percentage : 0
        readonly property bool charging: available && dev.state === UPowerDeviceState.Charging
        function icon() {
            console.log("EVALUATING ICON! percentage=" + percentage + " charging=" + charging);
            return charging ? "CHARGING" : "DISCHARGING";
        }
    }
    
    Text {
        text: batt.icon() + " " + Math.round(batt.percentage * 100) + "%"
        onTextChanged: console.log("Text changed to: " + text)
    }
}
