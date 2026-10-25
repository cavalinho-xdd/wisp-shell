pragma Singleton
import QtQuick

QtObject {
    property bool launcherActive: false
    // Output that was focused when the launcher was toggled on: the Ember
    // islands open it there and nowhere else.
    property string launcherScreen: ""
    property bool settingsActive: false
}
