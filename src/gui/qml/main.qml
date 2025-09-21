import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "LaunchPad"

    // A simple text to show that the QML is loaded
    Text {
        text: "Hello, LaunchPad!"
        anchors.centerIn: parent
    }
}
