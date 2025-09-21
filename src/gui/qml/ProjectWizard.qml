
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var theme
    signal cancelRequested()
    signal completed(var summary)

    property int currentStep: 0
    property string errorMessage: ""

    property var wizardData: ({
        name: "",
        icon: "🚀",
        tags: "",
        template: "None",
        description: "",
        defaultProfile: "dev"
    })

    ListModel {
        id: stepModel
        ListElement { title: "Basic Details" }
        ListElement { title: "Paths & Links" }
        ListElement { title: "Commands" }
        ListElement { title: "URLs" }
        ListElement { title: "Profiles" }
        ListElement { title: "Review" }
    }

    ListModel {
        id: pathModel
        ListElement { label: "IDE"; value: "~/Projects/example"; type: "IDE" }
        ListElement { label: "Repository"; value: "~/Projects/example"; type: "Folder" }
    }

    ListModel {
        id: commandModel
        ListElement { title: "Backend API"; cwd: "./services/api"; command: "uvicorn app.main:app --reload" }
        ListElement { title: "Frontend"; cwd: "./dashboard"; command: "npm run dev" }
    }

    ListModel {
        id: urlModel
        ListElement { label: "Swagger"; url: "http://localhost:8000/docs" }
        ListElement { label: "Frontend"; url: "http://localhost:5173" }
    }

    ListModel {
        id: profileModel
        ListElement { name: "dev"; description: "Local development" }
        ListElement { name: "staging"; description: "Staging environment" }
    }

    property int defaultProfileIndex: 0

    function stepCount() { return stepModel.count }

    function addPath() { pathModel.append({ label: "New entry", value: "", type: "Folder" }) }
    function removePath(index) { if (index >= 0 && index < pathModel.count) pathModel.remove(index) }

    function addCommand() { commandModel.append({ title: "New command", cwd: "", command: "" }) }
    function duplicateCommand(index) {
        if (index >= 0 && index < commandModel.count) {
            var original = commandModel.get(index)
            commandModel.insert(index + 1, { title: original.title + " (copy)", cwd: original.cwd, command: original.command })
        }
    }
    function removeCommand(index) { if (commandModel.count > 1 && index >= 0 && index < commandModel.count) commandModel.remove(index) }

    function addUrl() { urlModel.append({ label: "New link", url: "http://" }) }
    function removeUrl(index) { if (index >= 0 && index < urlModel.count) urlModel.remove(index) }

    function addProfile() { profileModel.append({ name: "profile-" + (profileModel.count + 1), description: "" }) }
    function duplicateProfile(index) {
        if (index >= 0 && index < profileModel.count) {
            var original = profileModel.get(index)
            profileModel.insert(index + 1, { name: original.name + "-copy", description: original.description })
        }
    }
    function removeProfile(index) {
        if (profileModel.count <= 1) return
        if (index >= 0 && index < profileModel.count) {
            profileModel.remove(index)
            if (defaultProfileIndex >= profileModel.count) defaultProfileIndex = profileModel.count - 1
        }
    }

    function setDefaultProfile(index) {
        if (index < 0 || index >= profileModel.count) return
        defaultProfileIndex = index
        wizardData.defaultProfile = profileModel.get(index).name
    }

    function nextStep() {
        errorMessage = ""
        if (currentStep < stepModel.count - 1) currentStep += 1
    }
    function previousStep() {
        if (currentStep > 0) currentStep -= 1
        else cancelRequested()
    }

    function slugify(text) {
        var slug = text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        if (!slug.length) slug = "project-" + Math.round(Math.random() * 10000)
        return slug
    }

    function collectList(model) {
        var result = []
        for (var i = 0; i < model.count; ++i) result.push(model.get(i))
        return result
    }

    function finishWizard() {
        errorMessage = ""
        if (!wizardData.name || wizardData.name.trim().length === 0) {
            errorMessage = "Project name is required."
            currentStep = 0
            return
        }

        var tagsArray = []
        var tags = wizardData.tags.split(",")
        for (var i = 0; i < tags.length; ++i) {
            var tag = tags[i].trim()
            if (tag.length) tagsArray.push(tag)
        }

        if (profileModel.count === 0) addProfile()
        if (defaultProfileIndex >= profileModel.count) defaultProfileIndex = 0
        wizardData.defaultProfile = profileModel.get(defaultProfileIndex).name

        var summary = {
            key: slugify(wizardData.name),
            name: wizardData.name,
            icon: wizardData.icon && wizardData.icon.length ? wizardData.icon : "🚀",
            tags: tagsArray,
            template: wizardData.template,
            description: wizardData.description,
            defaultProfile: wizardData.defaultProfile,
            paths: collectList(pathModel),
            commands: collectList(commandModel),
            urls: collectList(urlModel),
            profiles: collectList(profileModel)
        }

        summary.components = summary.commands.map(function(cmd) {
            return {
                name: cmd.title,
                status: "Pending",
                summary: cmd.cwd,
                statusDetail: cmd.command,
                logs: [],
                healthChecks: []
            }
        })
        summary.quickLinks = summary.urls.map(function(link) { return { label: link.label, url: link.url } })
        summary.folders = summary.paths.map(function(path) { return { label: path.label, path: path.value } })
        summary.history = [{ time: "Now", description: "Project created" }]
        summary.healthChecks = []

        completed(summary)
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
                    text: "← Home"
                    onClicked: cancelRequested()
                }

                ColumnLayout {
                    spacing: 2
                    Label { text: "Create project"; font.pixelSize: 22; font.bold: true; color: theme.textPrimary }
                    Label { text: stepModel.get(currentStep).title; color: theme.textSecondary }
                }

                Item { Layout.fillWidth: true }
                Label { text: (currentStep + 1) + " / " + stepModel.count; color: theme.textSecondary }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Qt.rgba(theme.surfaceVariant.r, theme.surfaceVariant.g, theme.surfaceVariant.b, 0.35)
                border.color: theme.border
                border.width: 1

                ListView {
                    anchors.fill: parent
                    model: stepModel
                    currentIndex: currentStep
                    interactive: false
                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index === currentStep ? theme.elevated : Qt.rgba(0, 0, 0, 0)
                        border.color: theme.border
                        border.width: index === currentStep ? 1 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: index <= currentStep ? theme.accent : theme.surfaceVariant
                                Label { anchors.centerIn: parent; text: index + 1; font.pixelSize: 11; color: index <= currentStep ? "white" : theme.textSecondary }
                            }
                            Label { text: model.title; color: theme.textPrimary; font.bold: index === currentStep }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentStep = index
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0)

                StackLayout {
                    id: stepStack
                    anchors.fill: parent
                    currentIndex: currentStep

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                GroupBox {
                                    title: "Basic information"
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        spacing: 12
                                        Layout.fillWidth: true
                                        FormLayout {
                                            Layout.fillWidth: true
                                            Label { text: "Project name" }
                                            TextField { text: wizardData.name; Layout.fillWidth: true; onTextChanged: wizardData.name = text }
                                            Label { text: "Icon" }
                                            TextField { text: wizardData.icon; Layout.fillWidth: true; onTextChanged: wizardData.icon = text }
                                            Label { text: "Tags" }
                                            TextField { text: wizardData.tags; Layout.fillWidth: true; placeholderText: "comma,separated"; onTextChanged: wizardData.tags = text }
                                            Label { text: "Template" }
                                            ComboBox { model: ["None", "Python FastAPI", "Node + Vite", "Full-stack Docker"]; Layout.fillWidth: true; onActivated: wizardData.template = currentText; Component.onCompleted: currentIndex = 0 }
                                            Label { text: "Description" }
                                            TextArea { text: wizardData.description; Layout.fillWidth: true; implicitHeight: 80; wrapMode: TextEdit.Wrap; onTextChanged: wizardData.description = text }
                                        }
                                    }
                                }
                                Label { text: errorMessage; color: theme.danger; visible: errorMessage.length > 0 }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Label { text: "Paths & resources"; font.pixelSize: 20; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "➕ Add"; onClicked: addPath() }
                                }
                                Repeater {
                                    model: pathModel
                                    delegate: GroupBox {
                                        title: model.label
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            spacing: 8
                                            Layout.fillWidth: true
                                            ComboBox {
                                                property var kinds: ["IDE", "Folder", "File", "Docker"]
                                                model: kinds
                                                Layout.fillWidth: true
                                                currentIndex: Math.max(0, kinds.indexOf(model.type))
                                                onActivated: pathModel.setProperty(index, "type", currentText)
                                            }
                                            TextField { placeholderText: "Label"; text: model.label; Layout.fillWidth: true; onTextChanged: pathModel.setProperty(index, "label", text) }
                                            TextField { placeholderText: "Path or executable"; text: model.value; Layout.fillWidth: true; onTextChanged: pathModel.setProperty(index, "value", text) }
                                            Button { text: "Remove"; onClicked: removePath(index) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Label { text: "Launch commands"; font.pixelSize: 20; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "➕ Add command"; onClicked: addCommand() }
                                }
                                Repeater {
                                    model: commandModel
                                    delegate: GroupBox {
                                        title: model.title
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            spacing: 8
                                            Layout.fillWidth: true
                                            TextField { placeholderText: "Command name"; text: model.title; Layout.fillWidth: true; onTextChanged: commandModel.setProperty(index, "title", text) }
                                            TextField { placeholderText: "Working directory"; text: model.cwd; Layout.fillWidth: true; onTextChanged: commandModel.setProperty(index, "cwd", text) }
                                            TextArea { placeholderText: "Command"; text: model.command; Layout.fillWidth: true; implicitHeight: 100; wrapMode: TextEdit.Wrap; onTextChanged: commandModel.setProperty(index, "command", text) }
                                            RowLayout {
                                                spacing: 8
                                                Button { text: "Duplicate"; onClicked: duplicateCommand(index) }
                                                Button { text: "Remove"; enabled: commandModel.count > 1; onClicked: removeCommand(index) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Label { text: "Web dashboards & docs"; font.pixelSize: 20; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "➕ Add link"; onClicked: addUrl() }
                                }
                                Repeater {
                                    model: urlModel
                                    delegate: GroupBox {
                                        title: model.label
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            spacing: 8
                                            Layout.fillWidth: true
                                            TextField { placeholderText: "Label"; text: model.label; Layout.fillWidth: true; onTextChanged: urlModel.setProperty(index, "label", text) }
                                            TextField { placeholderText: "URL"; text: model.url; Layout.fillWidth: true; onTextChanged: urlModel.setProperty(index, "url", text) }
                                            Button { text: "Remove"; onClicked: removeUrl(index) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Label { text: "Profiles"; font.pixelSize: 20; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "➕ Add profile"; onClicked: addProfile() }
                                }
                                Repeater {
                                    model: profileModel
                                    delegate: GroupBox {
                                        title: model.name
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            spacing: 8
                                            Layout.fillWidth: true
                                            RowLayout {
                                                spacing: 8
                                                RadioButton {
                                                    checked: index === defaultProfileIndex
                                                    text: "Default"
                                                    onToggled: if (checked) setDefaultProfile(index)
                                                }
                                                Button { text: "Duplicate"; onClicked: duplicateProfile(index) }
                                                Button { text: "Remove"; enabled: profileModel.count > 1; onClicked: removeProfile(index) }
                                            }
                                            TextField {
                                                placeholderText: "Profile name"
                                                text: model.name
                                                Layout.fillWidth: true
                                                onTextChanged: {
                                                    profileModel.setProperty(index, "name", text)
                                                    if (index === defaultProfileIndex)
                                                        wizardData.defaultProfile = text
                                                }
                                            }
                                            TextArea { placeholderText: "Description"; text: model.description; Layout.fillWidth: true; implicitHeight: 80; wrapMode: TextEdit.Wrap; onTextChanged: profileModel.setProperty(index, "description", text) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        ScrollView {
                            anchors.fill: parent
                            ColumnLayout {
                                width: parent.width
                                spacing: 16
                                padding: 24
                                Label { text: "Review"; font.pixelSize: 22; font.bold: true }
                                GroupBox {
                                    title: "Summary"
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        spacing: 6
                                        Label { text: "Name: " + wizardData.name; color: theme.textPrimary }
                                        Label { text: "Template: " + wizardData.template; color: theme.textPrimary }
                                        Label { text: "Default profile: " + wizardData.defaultProfile; color: theme.textPrimary }
                                        Label { text: "Tags: " + (wizardData.tags.length ? wizardData.tags : "None") }
                                    }
                                }
                                GroupBox {
                                    title: "Commands"
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        spacing: 4
                                        Repeater {
                                            model: commandModel
                                            delegate: Label {
                                                text: "• " + model.title + " — " + model.command
                                                color: theme.textSecondary
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                                GroupBox {
                                    title: "URLs"
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        spacing: 4
                                        Repeater {
                                            model: urlModel
                                            delegate: Label { text: model.label + ": " + model.url; color: theme.textSecondary; wrapMode: Text.Wrap }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 68
            color: Qt.rgba(theme.surfaceVariant.r, theme.surfaceVariant.g, theme.surfaceVariant.b, 0.4)
            border.color: theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                Button { text: "Cancel"; onClicked: cancelRequested() }
                Item { Layout.fillWidth: true }
                Button { text: "Back"; enabled: currentStep > 0; onClicked: previousStep() }
                Button {
                    visible: currentStep < stepModel.count - 1
                    text: "Next"
                    onClicked: nextStep()
                }
                Button {
                    visible: currentStep === stepModel.count - 1
                    text: "Create project"
                    highlighted: true
                    onClicked: finishWizard()
                }
            }
        }
    }
}
