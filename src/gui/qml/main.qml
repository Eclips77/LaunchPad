import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "LaunchPad"

    // Set a minimum size for the window for better layout management
    minimumWidth: 800
    minimumHeight: 600

    // Instantiate the HomeScreen which now contains our main UI
    HomeScreen {
        anchors.fill: parent
    }
}
