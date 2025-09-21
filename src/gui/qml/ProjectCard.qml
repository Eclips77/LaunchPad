import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card
    property string key: ""
    property string iconGlyph: "🚀"
    property string projectName: ""
    property string lastProfile: ""
    property string status: ""
    property bool favorite: false
    property var tags: []
    property var theme
    signal quickLaunch()
    signal openDetails()
    signal favoriteToggled()

    radius: 12
    border.color: theme.border
    border.width: 1
    color: theme.elevated
    implicitWidth: 280
    implicitHeight: contentLayout.implicitHeight + 32

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: iconGlyph
                font.pixelSize: 32
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: projectName
                    font.pixelSize: 18
                    font.bold: true
                    wrapMode: Text.WordWrap
                    color: theme.textPrimary
                }

                Label {
                    text: "Profile · " + lastProfile
                    color: theme.textSecondary
                    font.pixelSize: 12
                }
            }

            ToolButton {
                text: favorite ? "⭐" : "☆"
                Accessible.name: favorite ? "Remove from favorites" : "Mark as favorite"
                onClicked: favoriteToggled()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.border
            opacity: 0.35
        }

        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: card.tags
                delegate: Rectangle {
                    radius: 6
                    color: theme.surfaceVariant
                    border.color: theme.border
                    border.width: 1
                    implicitHeight: 22
                    implicitWidth: tagLabel.implicitWidth + 12

                    Label {
                        id: tagLabel
                        text: modelData
                        anchors.centerIn: parent
                        font.pixelSize: 11
                        color: theme.textSecondary
                    }
                }
            }
            visible: card.tags.length > 0
        }

        Rectangle {
            radius: 8
            border.color: colorForStatus(status)
            color: Qt.rgba(colorForStatus(status).r, colorForStatus(status).g, colorForStatus(status).b, 0.12)
            Layout.fillWidth: true
            height: 36

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Label {
                    text: "Status"
                    color: theme.textSecondary
                    font.pixelSize: 12
                }

                Label {
                    text: status
                    color: colorForStatus(status)
                    font.bold: true
                }
            }
        }

        Button {
            text: "Quick Launch"
            Layout.fillWidth: true
            font.bold: true
            background: Rectangle {
                radius: 8
                color: theme.accent
            }
            contentItem: Label {
                text: parent.text
                color: "white"
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: quickLaunch()
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: card.openDetails()
    }

    function colorForStatus(value) {
        if (!value)
            return theme.muted
        var text = value.toLowerCase()
        if (text.indexOf("run") !== -1 || text.indexOf("ready") !== -1 || text.indexOf("healthy") !== -1)
            return theme.success
        if (text.indexOf("fail") !== -1 || text.indexOf("error") !== -1)
            return theme.danger
        if (text.indexOf("pause") !== -1 || text.indexOf("stop") !== -1)
            return theme.warning
        return theme.accent
    }
}
