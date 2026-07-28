import QtQuick

Rectangle {
    id: stateLayer
    anchors.fill: parent
    color: themePrimaryColor
    opacity: 0.0

    property color themePrimaryColor: "#cba6f7"
    property bool isPressed: false
    property bool isHovered: false

    states: [
        State {
            name: "pressed"; when: isPressed
            PropertyChanges { target: stateLayer; opacity: 0.25 }
        },
        State {
            name: "hovered"; when: isHovered && !isPressed
            PropertyChanges { target: stateLayer; opacity: 0.15 }
        }
    ]
    
    transitions: Transition {
        NumberAnimation { property: "opacity"; duration: 150 }
    }
}
