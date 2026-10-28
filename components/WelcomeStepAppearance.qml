pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../core"

// Welcome wizard: the ember's colour from the wallpaper. Same
// Settings.conf.colors fields and Settings.applyColors() call as
// SettingsPageColors.qml; the preview shows the ember as it changes.
CfgPage {
    id: step

    property string wallpaper: ""
    readonly property bool live: Settings.conf.colors.dynamicEnabled

    // matugen takes ~150 ms per run; debounce chip mashing exactly as the
    // settings page does.
    Timer { id: regenTimer; interval: 250; onTriggered: Settings.applyColors("") }
    function queueRegen() { if (step.live) regenTimer.restart(); }

    WelcomeIslandsPreview {
        Layout.fillWidth: true
        wallpaper: step.wallpaper
        highlight: 1
    }

    CfgSection {
        title: "Ember"

        CfgSwitch {
            text: "Take the ember from your wallpaper"
            hint: "The one colour in Wisp. Off keeps the default blue."
            checked: Settings.conf.colors.dynamicEnabled
            onToggled: value => {
                Settings.conf.colors.dynamicEnabled = value;
                if (value) Settings.applyColors("");
            }
        }
        CfgChoice {
            enabled: step.live
            text: "Mode"
            value: Settings.conf.colors.mode
            options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]
            onEdited: v => { Settings.conf.colors.mode = v; step.queueRegen(); }
        }
    }

    CfgSection {
        title: "Palette style"
        enabled: step.live
        opacity: enabled ? 1 : 0.5

        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spaceSm
            Layout.rightMargin: Theme.spaceSm
            Layout.topMargin: Theme.spaceXs
            Layout.bottomMargin: Theme.spaceSm
            spacing: Theme.spaceXs

            Repeater {
                model: [
                    { id: "tonal-spot", name: "Tonal Spot" },
                    { id: "vibrant", name: "Vibrant" },
                    { id: "expressive", name: "Expressive" },
                    { id: "fruit-salad", name: "Fruit Salad" },
                    { id: "rainbow", name: "Rainbow" },
                    { id: "content", name: "Content" },
                    { id: "fidelity", name: "Fidelity" },
                    { id: "neutral", name: "Neutral" },
                    { id: "monochrome", name: "Monochrome" }
                ]
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool active: Settings.conf.colors.scheme === modelData.id
                    width: chipText.implicitWidth + 2 * Theme.spaceMd
                    height: Theme.controlSize - Theme.spaceXs
                    radius: height / 2
                    color: active ? Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, 0.22))
                         : chipMa.containsMouse ? Theme.hover : Theme.ashHi
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.name
                    Accessible.checked: active

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.name
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textCaption
                        font.weight: chip.active ? Font.DemiBold : Font.Normal
                        color: chip.active ? Theme.ember : Theme.islandText
                    }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Settings.conf.colors.scheme = chip.modelData.id; step.queueRegen(); }
                    }
                }
            }
        }
    }
}
