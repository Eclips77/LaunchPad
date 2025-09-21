import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card
    width: 220
    height: 150
    color: "#4A4A4A"
    radius: 10

    // Define properties that the delegate can set from the model
    property string projectName: "Project Name"
    property string projectIcon: "" // URL or path to icon
    property string projectProfile: "dev"

    // Use a MouseArea to make the whole card clickable for navigation
    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: card.border.color = "#777777"
        onExited: card.border.color = "transparent"

        onClicked: {
            // This will eventually navigate to the project's detail screen.
            console.log("Navigating to project: " + projectName)
        }
    }

    // Add a border for the hover effect
    border.color: "transparent"
    border.width: 2

    // Main layout for the card's content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Icon Placeholder
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 48
            height: 48
            color: "#666" // Placeholder color
            radius: 8

            // In the future, this will be an Image component
            // Image { source: projectIcon }
        }

        // Project Name Label
        Label {
            Layout.fillWidth: true
            text: projectName
            color: "white"
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        // Quick Launch Button
        Button {
            id: launchButton
            Layout.fillWidth: true
            text: "Quick Launch"

            onClicked: (mouse) => {
                // We handle the click here and accept the event so it doesn't
                // propagate to the card's main MouseArea.
                mouse.accepted = true
                console.log("Quick Launch clicked for project: " + projectName)
            }
        }
    }
}
