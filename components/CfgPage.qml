import QtQuick
import QtQuick.Layouts
import "../core"

// Scrollable settings page: centered column of CfgSections.
// Modeled on ii-dots ContentPage.
Flickable {
    id: root
    default property alias contentData: contentColumn.data

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 48
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: contentColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 16
        spacing: 28
    }
}
