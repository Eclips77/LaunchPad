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
        ListElement {
            key: "nebula"
            name: "Nebula CRM"
            icon: "🪐"
            lastProfile: "dev"
            tags: "fastapi,postgres,docker"
            status: "Ready"
            favorite: true
            active: true
            usageHours: 18.5
        }
        ListElement {
            key: "aurora"
            name: "Aurora Analytics"
            icon: "📊"
            lastProfile: "staging"
            tags: "data,frontend,vite"
            status: "Running"
            favorite: false
            active: true
            usageHours: 9.2
        }
        ListElement {
            key: "lunar"
            name: "Lunar Ops"
            icon: "🌗"
            lastProfile: "dev"
            tags: "docker,compose,ops"
            status: "Needs Attention"
            favorite: false
            active: false
            usageHours: 3.4
        }
        ListElement {
            key: "quasar"
            name: "Quasar Docs"
            icon: "📚"
            lastProfile: "dev"
            tags: "docs,mdbook"
            status: "Ready"
            favorite: true
            active: false
            usageHours: 6.8
        }
    }

    property var projectDetails: ({
        "nebula": {
            key: "nebula",
            name: "Nebula CRM",
            icon: "🪐",
            defaultProfile: "dev",
            summary: "Customer portal with FastAPI backend and Vue dashboard.",
            components: [
                {
                    name: "FastAPI Service",
                    status: "Running",
                    summary: "Uvicorn server with auto-reload",
                    statusDetail: "HTTP 200 · Port 8000",
                    logs: [
                        "[09:40] Boot sequence started",
                        "[09:40] Loaded environment dev",
                        "[09:41] Listening on 0.0.0.0:8000"
                    ],
                    healthChecks: [
                        { label: "HTTP", status: "Healthy", detail: "200 OK" },
                        { label: "Docker", status: "Healthy", detail: "Container healthy" }
                    ]
                },
                {
                    name: "Worker Queue",
                    status: "Running",
                    summary: "Celery worker connected to Redis",
                    statusDetail: "Processing 3 jobs",
                    logs: [
                        "[09:39] Worker online",
                        "[09:41] Consumed task send_welcome_email"
                    ],
                    healthChecks: [
                        { label: "Redis", status: "Healthy", detail: "Ping 1.2ms" }
                    ]
                },
                {
                    name: "Frontend Dev Server",
                    status: "Paused",
                    summary: "Vite dev server for Vue dashboard",
                    statusDetail: "Paused by user",
                    logs: [
                        "[08:12] npm run dev",
                        "[08:15] Hot reload triggered"
                    ],
                    healthChecks: [
                        { label: "HTTP", status: "Paused", detail: "Server paused" }
                    ]
                }
            ],
            quickLinks: [
                { label: "Swagger Docs", url: "http://localhost:8000/docs" },
                { label: "Admin Portal", url: "http://localhost:5173" }
            ],
            folders: [
                { label: "Repository", path: "~/Projects/nebula" },
                { label: "Docker Compose", path: "~/Projects/nebula/ops" }
            ],
            history: [
                { time: "09:42", description: "Launch (dev)" },
                { time: "09:44", description: "Restart FastAPI" },
                { time: "09:50", description: "Teardown frontend" }
            ],
            healthChecks: [
                { label: "API endpoint", status: "Healthy", detail: "200 OK" },
                { label: "Docker compose", status: "Healthy", detail: "All containers healthy" },
                { label: "Port 8000", status: "Healthy", detail: "Listening" }
            ]
        },
        "aurora": {
            key: "aurora",
            name: "Aurora Analytics",
            icon: "📊",
            defaultProfile: "staging",
            summary: "Data pipeline with Node + Vite front-end dashboard.",
            components: [
                {
                    name: "Ingestion Worker",
                    status: "Running",
                    summary: "Python ETL job",
                    statusDetail: "Processing feed alpha",
                    logs: [
                        "[08:30] Sync started",
                        "[08:45] 1234 records processed"
                    ],
                    healthChecks: [
                        { label: "Database", status: "Healthy", detail: "Latency 20ms" }
                    ]
                },
                {
                    name: "Analytics UI",
                    status: "Running",
                    summary: "Vite dev server",
                    statusDetail: "Listening on 5174",
                    logs: [
                        "[08:12] yarn dev",
                        "[08:20] Hot reload" 
                    ],
                    healthChecks: [
                        { label: "HTTP", status: "Healthy", detail: "200 OK" }
                    ]
                }
            ],
            quickLinks: [
                { label: "Vite Dashboard", url: "http://localhost:5174" },
                { label: "Grafana", url: "http://localhost:3000" }
            ],
            folders: [
                { label: "Repository", path: "~/Projects/aurora" }
            ],
            history: [
                { time: "Yesterday", description: "Deploy staging" }
            ],
            healthChecks: [
                { label: "HTTP 5174", status: "Healthy", detail: "Dashboard ready" },
                { label: "Queue depth", status: "Healthy", detail: "4 pending" }
            ]
        },
        "lunar": {
            key: "lunar",
            name: "Lunar Ops",
            icon: "🌗",
            defaultProfile: "dev",
            summary: "Dockerized ops toolkit with mixed services.",
            components: [
                {
                    name: "API Gateway",
                    status: "Failed",
                    summary: "Nginx reverse proxy",
                    statusDetail: "Container exited",
                    logs: [
                        "[07:12] nginx start",
                        "[07:15] missing certificate"
                    ],
                    healthChecks: [
                        { label: "Docker", status: "Failed", detail: "Exited (1)" }
                    ]
                },
                {
                    name: "Telemetry",
                    status: "Stopped",
                    summary: "Prometheus instance",
                    statusDetail: "Stopped by user",
                    logs: [
                        "[06:50] Shutdown initiated"
                    ],
                    healthChecks: [
                        { label: "Port 9090", status: "Stopped", detail: "Not listening" }
                    ]
                }
            ],
            quickLinks: [
                { label: "Operations Wiki", url: "http://confluence.local/lunar" }
            ],
            folders: [
                { label: "Repository", path: "~/Projects/lunar" },
                { label: "Docker", path: "~/Projects/lunar/docker" }
            ],
            history: [
                { time: "Today", description: "Launch attempt failed" }
            ],
            healthChecks: [
                { label: "Gateway", status: "Failed", detail: "Container exited" },
                { label: "Prometheus", status: "Stopped", detail: "Inactive" }
            ]
        },
        "quasar": {
            key: "quasar",
            name: "Quasar Docs",
            icon: "📚",
            defaultProfile: "dev",
            summary: "Documentation toolchain built with mdBook.",
            components: [
                {
                    name: "mdBook Serve",
                    status: "Running",
                    summary: "mdbook serve --open",
                    statusDetail: "Listening on :3001",
                    logs: [
                        "[08:01] Rebuild complete",
                        "[08:05] Watching files"
                    ],
                    healthChecks: [
                        { label: "HTTP", status: "Healthy", detail: "200 OK" }
                    ]
                }
            ],
            quickLinks: [
                { label: "Docs", url: "http://localhost:3001" },
                { label: "GitHub", url: "https://github.com/org/quasar" }
            ],
            folders: [
                { label: "Repository", path: "~/Projects/quasar" }
            ],
            history: [
                { time: "Today", description: "Launch (dev)" }
            ],
            healthChecks: [
                { label: "HTTP", status: "Healthy", detail: "200 OK" }
            ]
        }
    })

    property var tagOptions: []

    function updateTagOptions() {
        var seen = {}
        for (var i = 0; i < projectListModel.count; ++i) {
            var tags = projectListModel.get(i).tags.split(",")
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

    Component.onCompleted: updateTagOptions()

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
