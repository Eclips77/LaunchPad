import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: background
    color: "#2E2E2E" // A dark background color

    // Main layout for the home screen
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header / Toolbar placeholder
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#3C3C3C"

            Label {
                text: "LaunchPad"
                color: "white"
                anchors.centerIn: parent
                font.pixelSize: 20
            }
        }

        // Scrollable area for the project grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridView {
                id: projectGridView
                anchors.fill: parent
                cellWidth: 240
                cellHeight: 170 // Increased height slightly for better spacing

                // Use padding for spacing around the grid
                anchors.margins: 10

                // Use the real project model exposed from Python
                model: projectModel

                // Use the ProjectCard component as the delegate for each item in the model
                delegate: ProjectCard {
                    // Bind the card's properties to the model's roles.
                    // These role names (e.g., "name") are defined in ProjectListModel.roleNames()
                    projectName: name
                    projectIcon: icon
                    projectProfile: profile
                }
            }
        }
    }
}
