"""
Tests for the project loading logic in src.core.project.
"""
import pytest
from src.core.project import (
    Project,
    Profile,
    Command,
    URL,
    ProjectManager,
    load_project_from_toml,
    ProjectLoadError,
)

SAMPLE_PROJECT_PATH = "projects/sample_project.toml"

def test_load_project_from_toml_success():
    """Tests successful loading and parsing of a valid project TOML file."""
    project = load_project_from_toml(SAMPLE_PROJECT_PATH)

    # Assert top-level project properties
    assert isinstance(project, Project)
    assert project.name == "LaunchPad Dev"
    assert project.config_path == SAMPLE_PROJECT_PATH
    assert project.default_profile_name == "dev"
    assert "python" in project.tags

    # Assert that the profile was loaded
    assert "dev" in project.profiles
    dev_profile = project.get_default_profile()
    assert isinstance(dev_profile, Profile)

    # Assert details of the profile
    assert dev_profile.ide == "vscode"
    assert len(dev_profile.urls) == 2
    assert len(dev_profile.commands) == 2

    # Assert details of a specific nested object
    assert dev_profile.urls[0].label == "PySide6 Docs"
    assert dev_profile.urls[0].url == "https://doc.qt.io/qtforpython/"
    assert dev_profile.commands[1].title == "Start Application"
    assert dev_profile.commands[1].command == "python src/main.py"

def test_load_project_not_found():
    """Tests that ProjectLoadError is raised for a non-existent file."""
    with pytest.raises(ProjectLoadError, match="not found"):
        load_project_from_toml("non_existent_project.toml")

def test_load_project_malformed_toml(tmp_path):
    """Tests that ProjectLoadError is raised for a malformed TOML file."""
    malformed_file = tmp_path / "malformed.toml"
    malformed_file.write_text("this is not valid toml = ")
    with pytest.raises(ProjectLoadError, match="Error decoding TOML"):
        load_project_from_toml(str(malformed_file))

def test_load_project_missing_name(tmp_path):
    """Tests that ProjectLoadError is raised when the required 'name' field is missing."""
    missing_name_file = tmp_path / "missing_name.toml"
    missing_name_file.write_text('[profiles.dev]\nide = "vscode"')
    with pytest.raises(ProjectLoadError, match="missing required 'name' field"):
        load_project_from_toml(str(missing_name_file))


def test_project_manager_discovery():
    """Tests that the ProjectManager correctly discovers and loads projects."""
    manager = ProjectManager(projects_dir="projects")
    projects = manager.get_all_projects()

    assert len(projects) == 1
    assert isinstance(projects[0], Project)
    assert projects[0].name == "LaunchPad Dev"

def test_project_manager_non_existent_dir():
    """Tests that the ProjectManager handles a non-existent directory gracefully."""
    manager = ProjectManager(projects_dir="non_existent_dir")
    projects = manager.get_all_projects()
    assert len(projects) == 0
