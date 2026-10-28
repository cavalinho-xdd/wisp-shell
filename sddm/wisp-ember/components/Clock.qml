import QtQuick

// The clock: light mono digits with the colon drawn as two dim dots that
// tick, and the date under it with the weekday carried by weight.
Column {
    id: clock

    required property var tokens
    property date now: new Date()
    readonly property var cs: Qt.locale("cs_CZ")

    spacing: 3 // the digits' line box already leaves air below

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter

        component Digits: Text {
            font.family: clock.tokens.fontMono
            font.pixelSize: 132
            font.weight: 250
            font.letterSpacing: -0.055 * 132
            color: clock.tokens.text
            // tight line box, like line-height .92
            lineHeightMode: Text.FixedHeight
            lineHeight: 121
        }

        Digits { text: clock.now.toLocaleTimeString(clock.cs, "HH") }

        Item {
            width: 9 + 28
            height: 121
            Column {
                id: colon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -6
                spacing: 22
                opacity: 1
                Repeater {
                    model: 2
                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5
                        color: clock.tokens.text
                        opacity: 0.42
                    }
                }
                // The colon ticks: dim for one second in two.
                SequentialAnimation on opacity {
                    running: !clock.tokens.reduceMotion
                    loops: Animation.Infinite
                    PropertyAction { value: 1 }
                    PauseAnimation { duration: 1000 }
                    PropertyAction { value: 0.48 }
                    PauseAnimation { duration: 1000 }
                }
            }
        }

        Digits { text: clock.now.toLocaleTimeString(clock.cs, "mm") }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        Text {
            text: {
                const d = clock.now.toLocaleDateString(clock.cs, "dddd");
                return d.charAt(0).toUpperCase() + d.slice(1);
            }
            font.family: clock.tokens.fontFamily
            font.pixelSize: 17
            font.weight: Font.Medium
            color: clock.tokens.text
        }
        Text {
            text: clock.now.toLocaleDateString(clock.cs, "d. MMMM")
            font.family: clock.tokens.fontFamily
            font.pixelSize: 17
            font.weight: 450
            color: clock.tokens.muted
        }
    }
}
