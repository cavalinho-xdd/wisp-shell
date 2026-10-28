import QtQuick

// Suspend, reboot, power off. No dialog: a click grows the island into a
// question with a confirm button, a second click commits, Esc or a pause of
// four seconds cancels. A button the system cannot do is not shown.
Island {
    id: power

    property bool canSuspend: sddm.canSuspend
    property bool canReboot: sddm.canReboot
    property bool canPowerOff: sddm.canPowerOff

    // "", "suspend", "reboot" or "powerOff"
    property string asking: ""

    readonly property var actions: [
        { key: "suspend", can: power.canSuspend, label: "Uspat", path: "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z" },
        { key: "reboot", can: power.canReboot, label: "Restartovat", path: "M20 12a8 8 0 1 1-2.3-5.6M20 4v5h-5" },
        { key: "powerOff", can: power.canPowerOff, label: "Vypnout", path: "M12 3v9M6.3 7.3a8 8 0 1 0 11.4 0" }
    ]
    readonly property var askingAction: actions.find(a => a.key === asking) || null

    function ask(key) {
        asking = key;
        cancelTimer.restart();
    }
    function cancel() {
        asking = "";
    }
    function commit() {
        const key = asking;
        asking = "";
        if (key === "suspend") sddm.suspend();
        else if (key === "reboot") sddm.reboot();
        else if (key === "powerOff") sddm.powerOff();
    }

    padding: 5
    spacing: 0
    visible: actions.some(a => a.can)

    Timer {
        id: cancelTimer
        interval: 4000
        onTriggered: power.cancel()
    }

    // The question, grown in front of the buttons.
    Item {
        id: confirm
        readonly property real full: question.implicitWidth + 8 + yes.width + 16
        width: power.asking !== "" ? full : 0
        height: 30
        clip: true
        opacity: power.asking !== "" ? 1 : 0
        Behavior on width { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Text {
            id: question
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: power.askingAction ? power.askingAction.label + "?" : ""
            font.family: power.tokens.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: power.tokens.text
        }
        Rectangle {
            id: yes
            x: question.x + question.implicitWidth + 8
            anchors.verticalCenter: parent.verticalCenter
            width: yesText.implicitWidth + 24
            height: 28
            radius: 14
            color: Qt.tint(power.tokens.ash, Qt.alpha(power.tokens.red, 0.22))
            Accessible.role: Accessible.Button
            Accessible.name: yesText.text
            Text {
                id: yesText
                anchors.centerIn: parent
                text: power.askingAction ? power.askingAction.label : ""
                font.family: power.tokens.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: "#ffd6df"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: power.commit()
            }
        }
    }

    Repeater {
        model: power.actions

        delegate: Item {
            id: button
            required property var modelData
            readonly property bool on: power.asking === modelData.key
            // Hidden while the system cannot do it; folded away while
            // another action is asking.
            visible: modelData.can
            width: power.asking === "" || on ? 30 : 0
            height: 30
            clip: true
            opacity: width > 0 ? 1 : 0
            Behavior on width { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Accessible.role: Accessible.Button
            Accessible.name: modelData.label

            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 15
                scale: hit.pressed ? 0.88 : 1
                Behavior on scale { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.005 } }
                color: button.on ? Qt.alpha(power.tokens.red, 0.12) : hit.containsMouse ? power.tokens.ashHi : "transparent"
                Behavior on color { ColorAnimation { duration: power.tokens.motionFast } }

                Icon {
                    anchors.centerIn: parent
                    path: button.modelData.path
                    color: button.on ? power.tokens.red : hit.containsMouse ? power.tokens.text : power.tokens.muted
                }
            }
            MouseArea {
                id: hit
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressedChanged: power.pressed = pressed
                onClicked: button.on ? power.commit() : power.ask(button.modelData.key)
            }
        }
    }
}
