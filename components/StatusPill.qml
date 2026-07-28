import QtQuick
import "../core"

Rectangle {
    id: root
    
    property bool isActive: false
    property string icon: ""
    property string text: ""
    
    signal clicked()
    
    height: 48
    implicitWidth: row.implicitWidth + 32
    implicitHeight: 48
    radius: 16
    
    // Base color
    color: Theme.surface
    
    // Active Gradient Background
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        opacity: root.isActive ? 1.0 : 0.0
        
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Qt.lighter(Theme.primary, 1.3) }
        }
    }
    
    // State layer for hover/press
    StateLayer {
        id: stateLayer
        radius: parent.radius
        isHovered: mouseArea.containsMouse
        isPressed: mouseArea.pressed
        themePrimaryColor: root.isActive ? Theme.background : Theme.primary
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: Theme.fontIcon // Assuming standard nerd font
            font.pixelSize: 18
            color: root.isActive ? Theme.background : Theme.text
            
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        
        Text {
            font.family: Theme.fontFamily;
            id: labelText
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: 14
            font.bold: true
            color: root.isActive ? Theme.background : Theme.text
            visible: text !== ""
            
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }
    
    // Animations for scaling on hover
    scale: mouseArea.containsMouse && !mouseArea.pressed ? 1.05 : (mouseArea.pressed ? 0.95 : 1.0)
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
    
    Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
