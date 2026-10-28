import QtQuick
import QtQuick.Layouts
import "../core"

// Explanatory note under a page or section title. A plain secondary-text
// sentence: the tinted callout box it used to be made every note look like
// a warning, and stacked several accent slabs on one page. `icon` is kept
// for callers that still pass one.
Text {
    id: root
    property string icon: ""

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    font.family: Theme.fontFamily
    font.pixelSize: 12
    lineHeight: 1.25
    color: Theme.islandMuted
    wrapMode: Text.WordWrap
}
