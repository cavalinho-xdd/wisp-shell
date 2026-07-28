import QtQuick
import "../core"

Rectangle {
    id: btn
    property bool isChecked: false
    property string text: ""
    property int iconSize: 20
    signal clicked()
    
    width: 48; height: 48
    radius: isChecked ? 12 : 24  
    color: isChecked ? Theme.primary : Theme.surface
    
    Behavior on radius { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    
    scale: mouse.pressed ? 0.9 : (mouse.containsMouse ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
    
    StateLayer {
        themePrimaryColor: Theme.primary
        isHovered: mouse.containsMouse
        isPressed: mouse.pressed
        radius: parent.radius
    }
    
    Text {
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.fontIcon
        font.pixelSize: btn.iconSize
        color: isChecked ? Theme.background : Theme.text
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
    
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btn.clicked()
    }
}
