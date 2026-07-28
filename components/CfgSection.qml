import QtQuick
import QtQuick.Layouts
import "../core"

// Settings section: nerd-font icon + title header, children below.
// Modeled on ii-dots ContentSection.
ColumnLayout {
    id: root
    property string title: ""
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        spacing: 10
        Text {
            text: root.icon
            font.family: Theme.fontIcon
            font.pixelSize: 18
            color: Theme.primary
            visible: root.icon !== ""
        }
        Text {
            font.family: Theme.fontFamily;
            text: root.title
            font.pixelSize: 16
            font.bold: true
            color: Theme.text
        }
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 4
    }
}
