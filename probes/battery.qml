import QtQuick
import Quickshell
import Quickshell.Services.UPower

ShellRoot {
    property var dev: UPower.displayDevice
    
    Connections {
        target: dev
        function onReadyChanged() {
            console.log("ready: " + dev.ready);
            console.log("percentage: " + dev.percentage);
            console.log("type: " + dev.type);
            console.log("powerSupply: " + dev.powerSupply);
            console.log("isPresent: " + dev.isPresent);
            console.log("isLaptopBattery: " + dev.isLaptopBattery);
        }
    }
}
