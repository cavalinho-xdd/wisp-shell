import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"

Item {
    id: root
    anchors.fill: parent
    
    signal dismiss()
    
    // Core search properties (ported from launcher.qml)
    readonly property var allApps: [...DesktopEntries.applications.values]
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    property string query: ""

    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        const wordHit = name.split(/[\s-]+/).some(w => w.startsWith(q));
        if (wordHit) return 80;
        const idx = name.indexOf(q);
        if (idx >= 0) return 60 - Math.min(idx, 20);
        if (app.keywords.some(k => k.toLowerCase().startsWith(q))) return 40;
        if ((app.genericName || "").toLowerCase().includes(q)) return 30;
        if ((app.comment || "").toLowerCase().includes(q)) return 20;
        return -1;
    }

    property string mathResult: ""
    readonly property bool mathMode: query.startsWith("=")
    onQueryChanged: if (mathMode && query.length > 1) mathDebounce.restart()
    Timer {
        id: mathDebounce
        interval: 120
        onTriggered: {
            mathProc.running = false;
            mathProc.command = ["qalc", "-t", root.query.slice(1).trim()];
            mathProc.running = true;
        }
    }
    Process {
        id: mathProc
        stdout: StdioCollector {
            onStreamFinished: root.mathResult = text.trim()
        }
    }

    readonly property var results: {
        const raw = query.trim();
        const q = raw.toLowerCase();

        if (mathMode) {
            const expr = raw.slice(1).trim();
            if (!expr) return [];
            return [{ kind: "math", expr: expr, result: mathResult }];
        }
        if (raw.startsWith("?")) {
            const term = raw.slice(1).trim();
            if (!term) return [];
            return [{ kind: "web", term: term }];
        }
        if (raw.startsWith("$")) {
            const cmd = raw.slice(1).trim();
            if (!cmd) return [];
            return [{ kind: "shell", cmd: cmd }];
        }

        if (!q) {
            // Empty query: show top 8 frecency apps
            return [...allApps]
                .sort((a, b) => AppUsage.frecencyBoost(b.id) - AppUsage.frecencyBoost(a.id))
                .slice(0, 8)
                .map(a => ({ kind: "app", app: a }));
        }
        return allApps
            .map(a => ({ app: a, s: score(a, q) + AppUsage.frecencyBoost(a.id) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s)
            .slice(0, 50)
            .map(r => ({ kind: "app", app: r.app }));
    }

    function launch(item) {
        if (!item) return;

        if (item.kind === "math") {
            if (root.mathResult)
                Quickshell.execDetached(["wl-copy", root.mathResult]);
        } else if (item.kind === "web") {
            Quickshell.execDetached(["xdg-open",
                "https://www.google.com/search?q=" + encodeURIComponent(item.term)]);
        } else if (item.kind === "shell") {
            Quickshell.execDetached(["bash", "-c", item.cmd]);
        } else {
            AppUsage.recordLaunch(item.app.id);
            if (item.app.runInTerminal)
                Quickshell.execDetached(["kitty", "-e", ...item.app.command]);
            else
                item.app.execute();
        }
        root.dismiss();
    }

    // Auto-focus logic when the launcher state activates
    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // ── Search row ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: Theme.surface
            radius: 16
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16
                
                Text {
                    text: "󰍉"
                    font.family: Theme.fontIcon
                    font.pixelSize: 28
                    color: Theme.primary
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.family: Theme.fontFamily;
                    color: Theme.text
                    font.pixelSize: 20
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onTextChanged: { root.query = text; resultList.currentIndex = 0; }
                    
                    Keys.onEscapePressed: root.dismiss()
                    Keys.onDownPressed: resultList.currentIndex = Math.min(resultList.currentIndex + 1, resultList.count - 1)
                    Keys.onUpPressed: resultList.currentIndex = Math.max(resultList.currentIndex - 1, 0)
                    Keys.onReturnPressed: root.launch(root.results[resultList.currentIndex])
                    Keys.onEnterPressed: root.launch(root.results[resultList.currentIndex])

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text.length === 0
                        text: "Search apps...   (= calc, ? web, $ shell)"
                        color: Theme.subtext0
                        font.pixelSize: 18
                        font.family: Theme.fontFamily;
                    }
                }
            }
        }

        // ── Content Area ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Frecency Grid (Empty Query)
            Item {
                anchors.fill: parent
                visible: root.query.length === 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                Text {
                    id: suggestedLabel
                    text: "Suggested"
                    font.family: Theme.fontFamily;
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.subtext0
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                }

                Grid {
                    anchors.top: suggestedLabel.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    columns: 4
                    spacing: 16

                    Repeater {
                        model: root.results.length > 0 && root.query.length === 0 ? root.results : []
                        delegate: Rectangle {
                            required property var modelData
                            width: (parent.width - 3 * 16) / 4
                            height: 120
                            radius: 16
                            HoverHandler { id: hoverHandler }
                            color: hoverHandler.hovered ? Theme.surface0 : Theme.surface
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            

                            Column {
                                anchors.centerIn: parent
                                spacing: 12
                                IconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    implicitSize: 48
                                    source: Quickshell.iconPath(modelData.app.icon, "application-x-executable")
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.app.name
                                    font.family: Theme.fontFamily;
                                    font.pixelSize: 14
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    width: parent.parent.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            
                            MouseArea {
                                id: gridMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(modelData)
                            }
                        }
                    }
                }
            }

            // Two-Pane Search Results (Query Active)
            RowLayout {
                anchors.fill: parent
                visible: root.query.length > 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                spacing: 24

                // Left: Result List
                ListView {
                    id: resultList
                    Layout.fillHeight: true
                    Layout.preferredWidth: 350
                    clip: true
                    model: root.results
                    currentIndex: 0
                    keyNavigationWraps: false
                    
                    highlightMoveDuration: 250
                    highlightMoveVelocity: -1
                    
                    highlight: Rectangle {
                        radius: 14
                        color: Theme.surface0
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isApp: modelData.kind === "app"
                        width: resultList.width
                        height: 64

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 36
                                visible: row.isApp
                                source: row.isApp
                                    ? Quickshell.iconPath(row.modelData.app.icon, "application-x-executable")
                                    : ""
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36; height: 36; radius: 12
                                visible: !row.isApp
                                color: Theme.surface
                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.kind === "math" ? "󰃬"
                                        : row.modelData.kind === "web" ? "󰖟" : ""
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 20
                                    color: Theme.primary
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    font.family: Theme.fontFamily;
                                    text: row.isApp ? row.modelData.app.name
                                        : row.modelData.kind === "math" ? (row.modelData.result || "...")
                                        : row.modelData.kind === "web" ? "Search the web"
                                        : "Run command"
                                    color: Theme.text
                                    font.pixelSize: 16
                                    font.bold: resultList.currentIndex === index
                                }
                                Text {
                                    font.family: Theme.fontFamily;
                                    text: row.isApp ? (row.modelData.app.genericName || "")
                                        : row.modelData.kind === "math" ? root.query.slice(1).trim()
                                        : row.modelData.kind === "web" ? "“" + row.modelData.term + "”"
                                        : row.modelData.cmd
                                    color: Theme.subtext0
                                    font.pixelSize: 12
                                    visible: text.length > 0
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: resultList.currentIndex = index
                            onClicked: root.launch(modelData)
                        }
                    }
                }

                // Right: Preview Pane
                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius: 20
                    color: Theme.surface

                    property var activeItem: resultList.count > 0 ? root.results[resultList.currentIndex] : null
                    
                    // App Preview
                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        visible: parent.activeItem && parent.activeItem.kind === "app"
                        
                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: 128
                            source: parent.parent.activeItem && parent.parent.activeItem.kind === "app" 
                                ? Quickshell.iconPath(parent.parent.activeItem.app.icon, "application-x-executable") 
                                : ""
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.activeItem && parent.parent.activeItem.kind === "app" ? parent.parent.activeItem.app.name : ""
                            font.family: Theme.fontFamily;
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.text
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.activeItem && parent.parent.activeItem.kind === "app" ? (parent.parent.activeItem.app.comment || "") : ""
                            font.family: Theme.fontFamily;
                            font.pixelSize: 14
                            color: Theme.subtext0
                            width: 250
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Rectangle {
                                width: 28; height: 28; radius: 8; color: Theme.surface0
                                Text { anchors.centerIn: parent; text: "↵"; font.pixelSize: 16; color: Theme.primary; font.family: Theme.fontFamily; }
                            }
                            Text {
                                text: "to Launch"
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.subtext0
                                font.pixelSize: 14
                                font.family: Theme.fontFamily;
                            }
                        }
                    }

                    // Math Preview
                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        visible: parent.activeItem && parent.activeItem.kind === "math"
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰃬"
                            font.family: Theme.fontIcon
                            font.pixelSize: 64
                            color: Theme.primary
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.activeItem && parent.parent.activeItem.kind === "math" ? (parent.parent.activeItem.result || "...") : ""
                            font.family: Theme.fontFamily;
                            font.pixelSize: 32
                            font.bold: true
                            color: Theme.text
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Rectangle {
                                width: 28; height: 28; radius: 8; color: Theme.surface0
                                Text { anchors.centerIn: parent; text: "↵"; font.pixelSize: 16; color: Theme.primary; font.family: Theme.fontFamily; }
                            }
                            Text {
                                text: "to Copy"
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.subtext0
                                font.pixelSize: 14
                                font.family: Theme.fontFamily;
                            }
                        }
                    }
                }
            }
        }
    }
}
