import QtQuick
import "../core"

Item {
    id: root
    width: 200
    height: 12 // Thinner overall height to match the screenshot

    property real value: 0.5
    property real minimumValue: 0.0
    property real maximumValue: 1.0

    signal moved(real value)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: dragArea.containsMouse || dragArea.pressed ? 12 : 6 // Grow thick on hover
        radius: height / 2
        color: Theme.surface0
        
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        Rectangle {
            id: fill
            
            // If we are dragging, show the immediate mouse position, otherwise show the bound value
            property real visualValue: dragArea.pressed ? dragArea.tempValue : root.value
            
            width: Math.max(height, track.width * ((visualValue - root.minimumValue) / (root.maximumValue - root.minimumValue)))
            height: parent.height
            radius: height / 2
            color: Theme.primary
            
            Behavior on width { 
                NumberAnimation { 
                    duration: dragArea.pressed ? 0 : Theme.animFast
                    easing.type: Easing.OutCubic 
                } 
            }
            
            // The Knob (circle on the active end)
            Rectangle {
                property bool active: dragArea.containsMouse || dragArea.pressed
                width: active ? 16 : 12
                height: active ? 16 : 12
                radius: width / 2
                color: active ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                anchors.right: parent.right
                anchors.rightMargin: active ? -6 : -4 // Pop out slightly more when active
                anchors.verticalCenter: parent.verticalCenter
                
                Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on anchors.rightMargin { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -10
        hoverEnabled: true
        
        property real tempValue: root.value
        
        function updateValue(mouse) {
            let localX = mouse.x - 10
            let pct = Math.max(0, Math.min(1, localX / root.width))
            tempValue = root.minimumValue + pct * (root.maximumValue - root.minimumValue)
            root.moved(tempValue)
        }
        
        onPressed: (mouse) => updateValue(mouse)
        onPositionChanged: (mouse) => { if (pressed) updateValue(mouse) }
        
        onWheel: (wheel) => {
            let step = 0.05
            let newValue = root.value
            if (wheel.angleDelta.y > 0) {
                newValue += step
            } else if (wheel.angleDelta.y < 0) {
                newValue -= step
            }
            newValue = Math.max(root.minimumValue, Math.min(root.maximumValue, newValue))
            root.moved(newValue)
        }
    }
}
