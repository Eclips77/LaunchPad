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
    readonly property var store: projectStore

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
            projectsModel: window.store ? window.store.projectsModel : null
            tagOptions: window.store ? window.store.tagOptions : []
            projectDetails: window.store ? window.store.projectDetails : ({})
            onCreateProjectRequested: stackView.push(wizardComponent)
            onOpenProject: function(projectKey) {
                var details = window.store && window.store.projectDetails ? window.store.projectDetails[projectKey] : null
                if (!details)
                    details = { name: "Unknown", components: [] }
                stackView.push({ item: projectComponent, properties: { projectData: details } })
            }
            onShowGlobalDashboard: stackView.push(globalComponent)
            onToggleTheme: window.darkMode = !window.darkMode
        }
    }

    Component {
        id: wizardComponent
        ProjectWizard {
            theme: theme
            onCancelRequested: stackView.pop()
            onCompleted: function(summary) {
                stackView.pop()
            }
        }
    }

    Component {
        id: projectComponent
        ProjectDashboard {
            theme: theme
            onBackRequested: stackView.pop()
        }
    }

    Component {
        id: globalComponent
        GlobalDashboard {
            theme: theme
            projectsModel: window.store ? window.store.projectsModel : null
            projectDetails: window.store ? window.store.projectDetails : ({})
            onBackRequested: stackView.pop()
            onOpenProject: function(projectKey) {
                var details = window.store && window.store.projectDetails ? window.store.projectDetails[projectKey] : null
                if (!details)
                    details = { name: "Unknown", components: [] }
                stackView.push({ item: projectComponent, properties: { projectData: details } })
            }
        }
    }
}
