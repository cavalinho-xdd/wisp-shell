import QtQuick
import QtQuick.Layouts
import "../core"

// Two columns of CfgSection cards. A card that holds a list spans both
// (`Layout.columnSpan: 2`); give the cards of one row `Layout.fillHeight`
// so their bottoms line up.
GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Theme.spaceSm
    rowSpacing: Theme.spaceSm
}
