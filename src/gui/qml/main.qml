import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "LaunchPad"
    property bool darkMode: true

    QtObject {
        id: theme
        property color background: window.darkMode ? "#0f172a" : "#f8fafc"
        property color surface: window.darkMode ? "#1e293b" : "#ffffff"
        property color surfaceVariant: window.darkMode ? "#14213b" : "#e2e8f0"
        property color elevated: window.darkMode ? "#1b253d" : "#ffffff"
        property color textPrimary: window.darkMode ? "#f8fafc" : "#0f172a"
        property color textSecondary: window.darkMode ? "#cbd5f5" : "#475569"
        property color muted: window.darkMode ? "#94a3b8" : "#64748b"
        property color border: window.darkMode ? "#24334f" : "#cbd5f5"
        property color accent: "#6366f1"
        property color success: "#22c55e"
        property color warning: "#f97316"
        property color danger: "#ef4444"
    }

    color: theme.background

    function statusColor(status) {
        if (!status)
            return theme.muted
        var lowered = status.toLowerCase()
        if (lowered.indexOf("run") !== -1 || lowered.indexOf("ready") !== -1 || lowered.indexOf("healthy") !== -1)
            return theme.success
        if (lowered.indexOf("fail") !== -1 || lowered.indexOf("error") !== -1)
            return theme.danger
        if (lowered.indexOf("pause") !== -1 || lowered.indexOf("stop") !== -1)
            return theme.warning
        return theme.accent
    }

    ListModel {
        id: projectListModel
    }

    property var projectDetails: ({})

    property var tagOptions: []

    function indexOfProject(key) {
        if (!projectListModel)
            return -1
        for (var i = 0; i < projectListModel.count; ++i) {
            var item = projectListModel.get(i)
            if (item.key === key)
                return i
        }
        return -1
    }

    function updateOverviewRow(index, overview) {
        if (!projectListModel || index < 0 || !overview)
            return
        var fields = Object.keys(overview)
        for (var i = 0; i < fields.length; ++i)
            projectListModel.setProperty(index, fields[i], overview[fields[i]])
    }

    function applyProjectUpdate(detail, overview) {
        if (!detail || !detail.key)
            return
        var summary = overview
        if (!summary && typeof projectLauncher !== "undefined" && projectLauncher.project_overview_for)
            summary = projectLauncher.project_overview_for(detail.key)
        var index = indexOfProject(detail.key)
        if (index !== -1 && summary)
            updateOverviewRow(index, summary)
        var next = {}
        for (var key in projectDetails)
            next[key] = projectDetails[key]
        next[detail.key] = detail
        projectDetails = next
        updateTagOptions()
    }

    function loadProjects() {
        if (typeof projectLauncher === "undefined")
            return
        var overview = projectLauncher.project_overview()
        projectListModel.clear()
        if (overview) {
            for (var i = 0; i < overview.length; ++i)
                projectListModel.append(overview[i])
        }
        var details = projectLauncher.project_details()
        projectDetails = details ? details : ({})
        updateTagOptions()
    }

    function updateTagOptions() {
        var seen = {}
        for (var i = 0; i < projectListModel.count; ++i) {
            var entry = projectListModel.get(i)
            var tagText = entry && entry.tags ? entry.tags : ""
            var tags = tagText.split(",")
            for (var j = 0; j < tags.length; ++j) {
                var tag = tags[j].trim()
                if (tag.length)
                    seen[tag] = true
            }
        }
        var list = []
        for (var key in seen)
            list.push(key)
        list.sort()
        tagOptions = list
    }

    Component.onCompleted: loadProjects()

    header: ToolBar {
        padding: 12
        contentHeight: implicitHeight
        background: Rectangle {
            color: Qt.rgba(0, 0, 0, 0)
        }
        RowLayout {
            anchors.fill: parent
            spacing: 12

            Label {
                text: "LaunchPad"
                font.pixelSize: 24
                font.bold: true
                color: theme.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }

            Label {
                text: "One-click project command center"
                color: theme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                text: window.darkMode ? "☀️ Light" : "🌙 Dark"
                onClicked: window.darkMode = !window.darkMode
                padding: 8
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        anchors.topMargin: header.height
        initialItem: homeComponent
    }

    Component {
        id: homeComponent
        HomeScreen {
            theme: theme
            projectsModel: projectListModel
            tagOptions: window.tagOptions
            projectDetails: window.projectDetails
            onCreateProjectRequested: stackView.push(wizardComponent)
            onOpenProject: function(projectKey) {
                var details = window.projectDetails[projectKey]
                if (!details)
                    details = { name: "Unknown", components: [] }
                stackView.push({ item: projectComponent, properties: { projectData: details } })
            }
            onShowGlobalDashboard: stackView.push(globalComponent)
            onToggleTheme: window.darkMode = !window.darkMode
            onProjectStateUpdated: window.applyProjectUpdate(projectDetail, overviewData)
        }
    }

    Component {
        id: wizardComponent
        ProjectWizard {
            theme: theme
            onCancelRequested: stackView.pop()
            onCompleted: function(summary) {
                var slug = summary.key
                var displayTags = summary.tags.join(", ")
                projectListModel.append({
                    key: slug,
                    name: summary.name,
                    icon: summary.icon,
                    lastProfile: summary.defaultProfile,
                    tags: displayTags,
                    status: "Ready",
                    favorite: false,
                    active: false,
                    usageHours: 0
                })
                window.projectDetails[slug] = summary
                window.updateTagOptions()
                stackView.pop()
            }
        }
    }

    Component {
        id: projectComponent
        ProjectDashboard {
            theme: theme
            onBackRequested: stackView.pop()
            onProjectStateUpdated: window.applyProjectUpdate(projectDetail, overviewData)
        }
    }

    Component {
        id: globalComponent
        GlobalDashboard {
            theme: theme
            projectsModel: projectListModel
            projectDetails: window.projectDetails
            onBackRequested: stackView.pop()
            onOpenProject: function(projectKey) {
                var details = window.projectDetails[projectKey]
                if (!details)
                    details = { name: "Unknown", components: [] }
                stackView.push({ item: projectComponent, properties: { projectData: details } })
            }
        }
    }
}
