
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var theme
    property var projectsModel
    property var projectDetails
    signal backRequested()
    signal openProject(string projectKey)

    property int totalProjects: 0
    property int activeProjects: 0
    property real usageHours: 0
    property var statusBreakdown: []

    function statusColor(value) {
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

    function refreshMetrics() {
        if (!projectsModel)
            return
        totalProjects = projectsModel.count
        var active = 0
        var usage = 0
        var stats = {}
        for (var i = 0; i < projectsModel.count; ++i) {
            var proj = projectsModel.get(i)
            if (proj.active)
                active += 1
            usage += proj.usageHours
            var status = proj.status || "Unknown"
            if (!stats[status])
                stats[status] = 0
            stats[status] += 1
        }
        activeProjects = active
        usageHours = usage
        var entries = []
        for (var key in stats)
            entries.push({ status: key, count: stats[key] })
        statusBreakdown = entries
    }

    function toggleProject(index) {
        if (!projectsModel)
            return
        var proj = projectsModel.get(index)
        projectsModel.setProperty(index, "active", !proj.active)
        refreshMetrics()
    }

    onProjectsModelChanged: refreshMetrics()
    Component.onCompleted: refreshMetrics()

    Connections {
        target: projectsModel
        function onDataChanged() { refreshMetrics() }
        function onRowsInserted() { refreshMetrics() }
        function onRowsRemoved() { refreshMetrics() }
        function onModelReset() { refreshMetrics() }
        function onCountChanged() { refreshMetrics() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ToolBar {
            Layout.fillWidth: true
            padding: 12
            background: Rectangle { color: Qt.rgba(0, 0, 0, 0) }

            RowLayout {
                anchors.fill: parent
                spacing: 12

                ToolButton {
                    text: "← Back"
                    onClicked: backRequested()
                }

                Label {
                    text: "Global dashboard"
                    font.pixelSize: 24
                    font.bold: true
                    color: theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "Active " + activeProjects + " / " + totalProjects
                    color: theme.textSecondary
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 20
                padding: 24

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.33 * parent.width
                        radius: 12
                        border.color: theme.border
                        color: theme.elevated
                        implicitHeight: 110

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Label { text: "Projects"; color: theme.textSecondary }
                            Label {
                                text: totalProjects
                                font.pixelSize: 32
                                font.bold: true
                                color: theme.textPrimary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.33 * parent.width
                        radius: 12
                        border.color: theme.border
                        color: theme.elevated
                        implicitHeight: 110

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Label { text: "Active"; color: theme.textSecondary }
                            Label {
                                text: activeProjects
                                font.pixelSize: 32
                                font.bold: true
                                color: theme.success
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.33 * parent.width
                        radius: 12
                        border.color: theme.border
                        color: theme.elevated
                        implicitHeight: 110

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Label { text: "Usage hours"; color: theme.textSecondary }
                            Label {
                                text: usageHours.toFixed(1) + " h"
                                font.pixelSize: 32
                                font.bold: true
                                color: theme.textPrimary
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Status overview"
                    Layout.fillWidth: true

                    Flow {
                        width: parent.width
                        spacing: 12
                        Repeater {
                            model: statusBreakdown
                            delegate: Rectangle {
                                radius: 8
                                border.color: theme.border
                                color: theme.surfaceVariant
                                implicitHeight: 40
                                implicitWidth: statusLabel.implicitWidth + 24

                                Label {
                                    id: statusLabel
                                    text: model.status + " · " + model.count
                                    anchors.centerIn: parent
                                    color: theme.textSecondary
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Projects"
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 12
                        Layout.fillWidth: true

                        Repeater {
                            model: projectsModel
                            delegate: Rectangle {
                                radius: 12
                                border.color: theme.border
                                color: theme.elevated
                                Layout.fillWidth: true
                                implicitHeight: rowLayout.implicitHeight + 24

                                ColumnLayout {
                                    id: rowLayout
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Label {
                                            text: model.icon + " " + model.name
                                            font.pixelSize: 18
                                            font.bold: true
                                            color: theme.textPrimary
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: root.openProject(model.key)
                                            }
                                        }

                                        Label {
                                            text: "Profile: " + model.lastProfile
                                            color: theme.textSecondary
                                        }

                                        Label {
                                            text: model.status
                                            color: root.statusColor(model.status)
                                        }

                                        Item { Layout.fillWidth: true }

                                        Button {
                                            text: model.active ? "🔴 Stop" : "🟢 Start"
                                            onClicked: root.toggleProject(index)
                                        }

                                        Button {
                                            text: "Open"
                                            onClicked: root.openProject(model.key)
                                        }
                                    }

                                    Flow {
                                        width: parent.width
                                        spacing: 6
                                        Repeater {
                                            model: model.tags.split(",")
                                            delegate: Rectangle {
                                                radius: 6
                                                color: theme.surfaceVariant
                                                border.color: theme.border
                                                implicitHeight: 22
                                                implicitWidth: tagLabel.implicitWidth + 12
                                                visible: modelData.trim().length > 0

                                                Label {
                                                    id: tagLabel
                                                    text: modelData.trim()
                                                    anchors.centerIn: parent
                                                    color: theme.textSecondary
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }
                                        visible: model.tags.length > 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
