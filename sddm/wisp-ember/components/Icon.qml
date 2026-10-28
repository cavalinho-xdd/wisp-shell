import QtQuick
import QtQuick.Shapes

// A stroked line icon drawn from an SVG path in a 24×24 box (the mock's
// icons), so the theme needs no icon font.
Item {
    id: icon

    property string path
    property real size: 15
    property color color: "white"
    property real strokeWidth: 1.7

    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.color
            strokeWidth: icon.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.path }
        }
    }
}
