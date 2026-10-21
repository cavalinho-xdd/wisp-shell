import QtQuick
import QtQuick.Layouts
import "../core"

// Settings section: a plain title over its rows. `icon` is kept for the
// pages that still pass one, but no longer drawn — an accent glyph on every
// heading competed with the rows it introduced.
ColumnLayout {
    id: root
    property string title: ""
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    Text {
        Layout.leftMargin: 12
        font.family: Theme.fontFamily
        text: root.title
        font.pixelSize: 14
        font.bold: true
        color: Theme.text
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 0
    }
}
