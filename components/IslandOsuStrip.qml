import QtQuick
import QtQuick.Effects
import "../core"

// Compact "dynamic island" osu!lazer presentation for the collapsed bar,
// fed by the Osu singleton (core/Osu.qml -> scripts/osu_connect.js -> tosu).
// Two faces, swapped on Osu.inGameplay: idle profile card (avatar, username,
// global rank, total PP) while just sitting in menus, live scoring HUD
// (PP, combo, accuracy, 300/100/50/miss) once a map is actually being
// played. Purely presentational — all state comes from Osu/Island.
Item {
    id: root

    readonly property bool active: Island.current === "osu"
    readonly property bool playing: Osu.inGameplay

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    scale: active ? 1.0 : 0.7
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }
    Behavior on implicitWidth { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

    Row {
        id: strip
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // ── Avatar (idle face only — live HUD needs the width for stats) ──
        Item {
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.playing

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: width / 2
                color: "transparent"
                border.color: Theme.primary
                border.width: 2
            }

            Image {
                id: avatar
                anchors.fill: parent
                source: Osu.avatarUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            MultiEffect {
                anchors.fill: avatar
                source: avatar
                maskEnabled: true
                visible: avatar.status === Image.Ready
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle { width: 30; height: 30; radius: 15 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: Theme.surface0
                visible: avatar.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "󰮯"
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                    color: Theme.text
                }
            }
        }

        // ── Idle face: username + global rank + total PP ──
        Column {
            visible: !root.playing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                font.family: Theme.fontFamily
                text: Osu.username
                color: Theme.text
                font.pixelSize: 12
                font.bold: true
            }
            Row {
                spacing: 6
                Text {
                    font.family: Theme.fontFamily
                    text: "#" + Osu.globalRank.toLocaleString()
                    color: Theme.subtext0
                    font.pixelSize: 10
                }
                Text {
                    font.family: Theme.fontFamily
                    text: Math.round(Osu.profilePp).toLocaleString() + "pp"
                    color: Theme.peach
                    font.pixelSize: 10
                }
            }
        }

        // ── Live face: pp / combo / accuracy / hit judgements ──
        Row {
            visible: root.playing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Column {
                spacing: 1
                Text {
                    font.family: Theme.fontFamily
                    text: Math.round(Osu.livePp) + "pp"
                    color: Theme.primary
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    font.family: Theme.fontFamily
                    text: "x" + Osu.combo
                    color: Theme.subtext0
                    font.pixelSize: 10
                }
            }

            Column {
                spacing: 1
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    font.family: Theme.fontFamily
                    text: Osu.accuracy.toFixed(2) + "%"
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    font.family: Theme.fontFamily
                    text: "acc"
                    color: Theme.subtext0
                    font.pixelSize: 9
                }
            }

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        { value: Osu.hits300, color: Theme.blue },
                        { value: Osu.hits100, color: Theme.green },
                        { value: Osu.hits50, color: Theme.yellow },
                        { value: Osu.hitsMiss, color: Theme.red }
                    ]
                    delegate: Text {
                        required property var modelData
                        font.family: Theme.fontFamily
                        text: modelData.value
                        color: modelData.color
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }
    }
}
