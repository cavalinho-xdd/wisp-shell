import QtQuick
import QtQuick.Layouts
import "../core"

// Informational callout box — the ii-dots NoticeBox equivalent.
Rectangle {
    id: root
    property string icon: "󰋽"
    property string text: ""

    Layout.fillWidth: true
    implicitHeight: noticeRow.implicitHeight + 24
    radius: 14
    // Tinted fill only. The border was the same hue as the fill it surrounded
    // — an outline that merely restates its own fill is decoration (DESIGN.md
    // §16). Fill lifted from 0.10 to 0.14 to hold the same presence without it.
    color: Qt.alpha(Theme.primary, 0.14)

    RowLayout {
        id: noticeRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
            text: root.icon
            font.family: Theme.fontIcon
            font.pixelSize: 15
            color: Theme.primary
            Layout.alignment: Qt.AlignTop
        }
        Text {
            font.family: Theme.fontFamily;
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: 12
            color: Theme.text
            wrapMode: Text.WordWrap
        }
    }
}
