import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: root
    property var theme
    property var projectsModel
    property var tagOptions: []
    signal createProjectRequested()
    signal openProject(string projectKey)
    signal showGlobalDashboard()
    signal toggleTheme()

    property string searchText: ""
    property bool favoritesOnly: false
    property string tagFilter: "All Tags"
    property string statusFilter: "All Statuses"

    readonly property var statusOptions: [
        "All Statuses",
        "Ready",
        "Running",
        "Needs Attention",
        "Failed",
        "Stopped",
        "Paused"
    ]

    function matchesSearch(project) {
        if (!searchText.length)
            return true
        var text = searchText.toLowerCase()
        var haystack = (project.name + " " + project.tags + " " + project.status + " " + project.lastProfile).toLowerCase()
        return haystack.indexOf(text) !== -1
    }

    function matchesTag(project) {
        if (!tagFilter || tagFilter === "All Tags")
            return true
        return project.tags.toLowerCase().indexOf(tagFilter.toLowerCase()) !== -1
    }

    function matchesStatus(project) {
        if (!statusFilter || statusFilter === "All Statuses")
            return true
        return project.status === statusFilter
    }

    function includeProject(index) {
        if (!projectsModel || index < 0 || index >= projectsModel.count)
            return false
        var project = projectsModel.get(index)
        if (favoritesOnly && !project.favorite)
            return false
        if (!matchesSearch(project))
            return false
        if (!matchesTag(project))
            return false
        if (!matchesStatus(project))
            return false
        return true
    }

    function countMatches(favoritesFlag) {
        if (!projectsModel)
            return 0
        var total = 0
        for (var i = 0; i < projectsModel.count; ++i) {
            var project = projectsModel.get(i)
            if (favoritesFlag === true && !project.favorite)
                continue
            if (favoritesFlag === false && project.favorite)
                continue
            if (includeProject(i))
                total += 1
        }
        return total
    }

    function toggleFavorite(index) {
        if (!projectsModel)
            return
        var project = projectsModel.get(index)
        projectsModel.setProperty(index, "favorite", !project.favorite)
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                color: Qt.rgba(theme.surfaceVariant.r, theme.surfaceVariant.g, theme.surfaceVariant.b, 0.4)
                border.color: theme.border
                border.width: 1

                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: sidebarContent.implicitHeight + 32
                    clip: true

                    ColumnLayout {
                        id: sidebarContent
                        width: parent.width
                        spacing: 18
                        anchors.margins: 20

                        Label {
                            text: "Search"
                            font.bold: true
                            color: theme.textPrimary
                        }

                        TextField {
                            id: searchField
                            placeholderText: "Find by name, tag, status"
                            text: searchText
                            onTextChanged: root.searchText = text
                        }

                        Label {
                            text: "Filters"
                            font.bold: true
                            color: theme.textPrimary
                        }

                        CheckBox {
                            text: "Favorites only"
                            checked: favoritesOnly
                            onToggled: favoritesOnly = checked
                        }

                        ComboBox {
                            id: tagSelector
                            model: ["All Tags"].concat(tagOptions)
                            currentIndex: 0
                            onActivated: tagFilter = currentText
                            Layout.fillWidth: true
                        }

                        ComboBox {
                            id: statusSelector
                            model: statusOptions
                            currentIndex: 0
                            onActivated: statusFilter = currentText
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme.border
                            opacity: 0.4
                        }

                        Label {
                            text: "Global"
                            font.bold: true
                            color: theme.textPrimary
                        }

                        Button {
                            text: "🔄 Sync"
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "⚙️ Settings"
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "🗂 Global dashboard"
                            Layout.fillWidth: true
                            onClicked: root.showGlobalDashboard()
                        }

                        Button {
                            text: "Toggle theme"
                            Layout.fillWidth: true
                            onClicked: root.toggleTheme()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "Projects"
                                font.pixelSize: 26
                                font.bold: true
                                color: theme.textPrimary
                            }

                            Label {
                                text: projectsModel ? projectsModel.count + " configured" : "No projects"
                                color: theme.textSecondary
                            }
                        }

                        ToolButton {
                            text: "➕ Add project"
                            onClicked: root.createProjectRequested()
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Column {
                            width: parent.width
                            spacing: 24

                            Column {
                                spacing: 12
                                visible: countMatches(true) > 0

                                Label {
                                    text: "⭐ Favorites"
                                    font.bold: true
                                    color: theme.textSecondary
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 16
                                    Repeater {
                                        model: projectsModel
                                        delegate: ProjectCard {
                                            visible: includeProject(index) && model.favorite
                                            key: model.key
                                            iconGlyph: model.icon
                                            projectName: model.name
                                            lastProfile: model.lastProfile
                                            status: model.status
                                            favorite: model.favorite
                                            tags: model.tags
                                            theme: root.theme
                                            onQuickLaunch: root.openProject(model.key)
                                            onOpenDetails: root.openProject(model.key)
                                            onFavoriteToggled: root.toggleFavorite(index)
                                        }
                                    }
                                }
                            }

                            Column {
                                spacing: 12

                                Label {
                                    text: favoritesOnly ? "Favorites" : "All projects"
                                    font.bold: true
                                    color: theme.textSecondary
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 16
                                    Repeater {
                                        model: projectsModel
                                        delegate: ProjectCard {
                                            visible: includeProject(index) && !model.favorite
                                            key: model.key
                                            iconGlyph: model.icon
                                            projectName: model.name
                                            lastProfile: model.lastProfile
                                            status: model.status
                                            favorite: model.favorite
                                            tags: model.tags
                                            theme: root.theme
                                            onQuickLaunch: root.openProject(model.key)
                                            onOpenDetails: root.openProject(model.key)
                                            onFavoriteToggled: root.toggleFavorite(index)
                                        }
                                    }
                                }

                                Label {
                                    text: "No projects match your filters."
                                    color: theme.textSecondary
                                    visible: countMatches(true) === 0 && countMatches(false) === 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
