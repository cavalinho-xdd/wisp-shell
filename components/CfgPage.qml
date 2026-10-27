import QtQuick
import QtQuick.Layouts
import "../core"

// Scrollable settings page: a column of CfgSection cards under the header
// that settings.qml draws. Modeled on ii-dots ContentPage.
Flickable {
    id: root
    default property alias contentData: contentColumn.data

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + Theme.spaceSm + Theme.spaceLg
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: contentColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceXs
        spacing: Theme.spaceSm
    }
}
