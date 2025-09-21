
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var theme
    property var projectData
    signal backRequested()
    signal projectStateUpdated(var projectDetail, var overviewData)

    property var componentsData: []
    property var healthData: []
    property var historyData: []
    property var linksData: []
    property var folderData: []

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

    function updateLocalData() {
        componentsData = projectData && projectData.components ? projectData.components : []
        healthData = projectData && projectData.healthChecks ? projectData.healthChecks : []
        historyData = projectData && projectData.history ? projectData.history : []
        linksData = projectData && projectData.quickLinks ? projectData.quickLinks : []
        folderData = projectData && projectData.folders ? projectData.folders : []
    }

    function handleServiceResult(result) {
        if (!result || !result.project)
            return
        projectData = result.project
        updateLocalData()
        var overview = result.overview
        if (!overview && typeof projectLauncher !== "undefined" && projectLauncher.project_overview_for)
            overview = projectLauncher.project_overview_for(projectData.key)
        if (overview)
            projectStateUpdated(result.project, overview)
    }

    onProjectDataChanged: updateLocalData()
    Component.onCompleted: updateLocalData()

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
                    text: (projectData && projectData.icon ? projectData.icon + " " : "") + (projectData && projectData.name ? projectData.name : "Project")
                    font.pixelSize: 24
                    font.bold: true
                    color: theme.textPrimary
                }

                Label {
                    text: projectData && projectData.defaultProfile ? "Profile: " + projectData.defaultProfile : ""
                    color: theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Quick launch"
                    onClicked: {
                        if (!projectData || !projectData.key || typeof projectLauncher === "undefined")
                            return
                        var profile = projectData.lastProfile ? projectData.lastProfile : projectData.defaultProfile
                        handleServiceResult(projectLauncher.launch_project(projectData.key, profile))
                    }
                }
                Button { text: "Advanced launch" }
                Button { text: "Edit" }
                Button { text: "Delete" }
                Button { text: "Logs" }
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

                GroupBox {
                    title: "Project overview"
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Label {
                            text: projectData && projectData.summary ? projectData.summary : "Configure commands, folders, and health checks for a one-click launch."
                            wrapMode: Text.Wrap
                            color: theme.textSecondary
                        }

                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: folderData
                                delegate: Rectangle {
                                    radius: 6
                                    border.color: theme.border
                                    color: theme.surfaceVariant
                                    implicitHeight: 28
                                    implicitWidth: folderLabel.implicitWidth + 20

                                    Label {
                                        id: folderLabel
                                        text: model.label + " · " + model.path
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        color: theme.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Components"
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 16
                        Layout.fillWidth: true

                        Repeater {
                            model: componentsData
                            delegate: Rectangle {
                                radius: 12
                                border.color: theme.border
                                color: theme.elevated
                                Layout.fillWidth: true
                                implicitHeight: componentLayout.implicitHeight + 24

                                ColumnLayout {
                                    id: componentLayout
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: statusColor(model.status)
                                        }

                                        Label {
                                            text: model.name
                                            font.pixelSize: 18
                                            font.bold: true
                                            color: theme.textPrimary
                                        }

                                        Item { Layout.fillWidth: true }

                                        Label {
                                            text: model.status
                                            color: statusColor(model.status)
                                            font.bold: true
                                        }
                                    }

                                    Label {
                                        text: model.summary
                                        color: theme.textSecondary
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: 8

                                        Button {
                                            text: "Start"
                                            onClicked: {
                                                if (!projectData || !projectData.key || typeof projectLauncher === "undefined")
                                                    return
                                                handleServiceResult(projectLauncher.start_component(projectData.key, model.name))
                                            }
                                        }
                                        Button {
                                            text: "Stop"
                                            onClicked: {
                                                if (!projectData || !projectData.key || typeof projectLauncher === "undefined")
                                                    return
                                                handleServiceResult(projectLauncher.stop_component(projectData.key, model.name))
                                            }
                                        }
                                        Button {
                                            text: "Pause"
                                            onClicked: {
                                                if (!projectData || !projectData.key || typeof projectLauncher === "undefined")
                                                    return
                                                handleServiceResult(projectLauncher.pause_component(projectData.key, model.name))
                                            }
                                        }
                                        Button {
                                            text: "Resume"
                                            onClicked: {
                                                if (!projectData || !projectData.key || typeof projectLauncher === "undefined")
                                                    return
                                                handleServiceResult(projectLauncher.resume_component(projectData.key, model.name))
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 4
                                        Layout.fillWidth: true
                                        visible: model.healthChecks && model.healthChecks.length > 0

                                        Label {
                                            text: "Health checks"
                                            font.pixelSize: 12
                                            color: theme.textSecondary
                                        }

                                        Repeater {
                                            model: model.healthChecks
                                            delegate: RowLayout {
                                                spacing: 6
                                                Label {
                                                    text: modelData.label
                                                    color: theme.textPrimary
                                                }
                                                Label {
                                                    text: modelData.status
                                                    color: statusColor(modelData.status)
                                                }
                                                Label {
                                                    text: modelData.detail
                                                    color: theme.textSecondary
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 4
                                        Layout.fillWidth: true

                                        Label {
                                            text: "Recent logs"
                                            font.pixelSize: 12
                                            color: theme.textSecondary
                                        }

                                        Rectangle {
                                            radius: 8
                                            border.color: theme.border
                                            color: theme.surfaceVariant
                                            Layout.fillWidth: true
                                            implicitHeight: logText.implicitHeight + 16

                                            Text {
                                                id: logText
                                                text: model.logs ? model.logs.slice(Math.max(0, model.logs.length - 10)).join("
") : "No logs yet"
                                                anchors.margins: 8
                                                anchors.fill: parent
                                                color: theme.textSecondary
                                                font.pixelSize: 12
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    GroupBox {
                        title: "Health checks"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.4 * parent.width

                        ColumnLayout {
                            spacing: 8
                            Repeater {
                                model: healthData
                                delegate: RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: statusColor(model.status)
                                    }
                                    Label {
                                        text: model.label
                                        color: theme.textPrimary
                                    }
                                    Label {
                                        text: model.detail
                                        color: theme.textSecondary
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                            Label {
                                text: healthData.length === 0 ? "No health checks configured yet." : ""
                                visible: healthData.length === 0
                                color: theme.textSecondary
                            }
                        }
                    }

                    GroupBox {
                        title: "Quick links"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.3 * parent.width

                        ColumnLayout {
                            spacing: 8
                            Repeater {
                                model: linksData
                                delegate: Button {
                                    text: model.label
                                    Layout.fillWidth: true
                                }
                            }
                            Label {
                                text: linksData.length === 0 ? "No links yet." : ""
                                visible: linksData.length === 0
                                color: theme.textSecondary
                            }
                        }
                    }

                    GroupBox {
                        title: "Recent actions"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.3 * parent.width

                        ColumnLayout {
                            spacing: 8
                            Repeater {
                                model: historyData
                                delegate: Label {
                                    text: model.time + " · " + model.description
                                    color: theme.textSecondary
                                }
                            }
                            Label {
                                text: historyData.length === 0 ? "No recorded actions yet." : ""
                                visible: historyData.length === 0
                                color: theme.textSecondary
                            }
                        }
                    }
                }

                Rectangle {
                    radius: 12
                    border.color: theme.border
                    color: theme.surfaceVariant
                    Layout.fillWidth: true
                    implicitHeight: teardownLayout.implicitHeight + 24

                    ColumnLayout {
                        id: teardownLayout
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Label {
                                text: "Recovery"
                                font.pixelSize: 18
                                font.bold: true
                                color: theme.textPrimary
                            }
                        }

                        RowLayout {
                            spacing: 12
                            Button { text: "Retry failed only" }
                            Button { text: "View error logs" }
                        }

                        RowLayout {
                            spacing: 12
                            Button { text: "Teardown all" }
                            Button { text: "Teardown selected" }
                        }
                    }
                }
            }
        }
    }
}
