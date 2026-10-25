.pragma library

// Where the three islands (left, centre, right) sit on one screen, as left
// edges. A pure function of the layout, the screen width and the current
// island widths, so it can be checked outside Quickshell
// (probes/layout_check.mjs).
//
//   spread    left in the left corner, centre in the middle, right in the
//             right corner
//   cluster   all three side by side, the group centred
//   quarters  centre at 1/2 of the width, left at 1/4, right at 3/4
//
// `open` is the index of the open island (0 left, 1 centre, 2 right) or -1.
// The open island keeps its place and the others step aside, chain by chain
// (centre first, then the one behind it); with nothing open the centre holds.
// In `cluster` the whole group stays centred instead, so everything slides
// when one island grows.

var NAMES = ["spread", "cluster", "quarters"];

function place(layout, screenWidth, widths, open, margin, gap) {
    var w = widths;
    var x;

    if (layout === "cluster") {
        var total = w[0] + w[1] + w[2] + 2 * gap;
        x = [];
        var at = (screenWidth - total) / 2;
        for (var i = 0; i < 3; i++) {
            x.push(at);
            at += w[i] + gap;
        }
        return clampGroup(x, w, screenWidth, margin);
    }

    if (layout === "quarters") {
        x = [screenWidth / 4 - w[0] / 2, (screenWidth - w[1]) / 2, screenWidth * 3 / 4 - w[2] / 2];
    } else {
        x = [margin, (screenWidth - w[1]) / 2, screenWidth - margin - w[2]];
    }

    var pivot = open < 0 ? 1 : open;
    for (var r = pivot + 1; r < 3; r++)
        x[r] = Math.max(x[r], x[r - 1] + w[r - 1] + gap);
    for (var l = pivot - 1; l >= 0; l--)
        x[l] = Math.min(x[l], x[l + 1] - w[l] - gap);
    return clampGroup(x, w, screenWidth, margin);
}

// Keeps the islands on the screen: shifts everything back when the chain was
// pushed past an edge. Only when the three do not fit at all do they overlap.
function clampGroup(x, w, screenWidth, margin) {
    var out = x.slice();
    var over = out[0] - margin;
    if (over < 0) {
        for (var i = 0; i < 3; i++) out[i] -= over;
    }
    var right = screenWidth - margin - (out[2] + w[2]);
    if (right < 0) {
        // Do not push the left island back past its own margin.
        var shift = Math.min(-right, out[0] - margin);
        for (var j = 0; j < 3; j++) out[j] -= shift;
    }
    return out;
}
