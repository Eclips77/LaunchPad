"""
Contains the data models for projects, profiles, and commands.
"""
import os
import toml
from dataclasses import dataclass, field
from typing import List, Optional, Dict

class ProjectLoadError(Exception):
    """Custom exception for errors during project loading."""
    pass

@dataclass
class Command:
    """Represents a single command to be executed."""
    title: str
    command: str
    directory: str = "."

@dataclass
class URL:
    """Represents a single URL to be opened."""
    label: str
    url: str

@dataclass
class Profile:
    """
    Represents a launch profile within a project, containing a specific
    set of paths, commands, and URLs to be launched.
    """
    name: str
    ide: Optional[str] = None
    folders: List[str] = field(default_factory=list)
    files: List[str] = field(default_factory=list)
    commands: List[Command] = field(default_factory=list)
    urls: List[URL] = field(default_factory=list)

@dataclass
class Project:
    """
    Represents a single project, containing all its configuration and profiles.
    """
    name: str
    config_path: str  # The path to the project's TOML configuration file
    icon: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    profiles: Dict[str, Profile] = field(default_factory=dict)
    default_profile_name: str = "dev"

    def get_default_profile(self) -> Optional[Profile]:
        """Returns the default profile, if it exists."""
        return self.profiles.get(self.default_profile_name)

def load_project_from_toml(filepath: str) -> Project:
    """
    Loads a project configuration from a TOML file.

    Args:
        filepath: The absolute path to the TOML file.

    Returns:
        A Project object populated with the data from the file.

    Raises:
        ProjectLoadError: If the file cannot be found, is not valid TOML,
                          or is missing required fields.
    """
    try:
        data = toml.load(filepath)
    except FileNotFoundError:
        raise ProjectLoadError(f"Project file not found: {filepath}")
    except toml.TomlDecodeError as e:
        raise ProjectLoadError(f"Error decoding TOML file {filepath}: {e}")

    try:
        project_name = data["name"]
    except KeyError:
        raise ProjectLoadError(f"Project file {filepath} is missing required 'name' field.")

    # Load profiles
    profiles_data = data.get("profiles", {})
    profiles = {}
    for profile_name, profile_data in profiles_data.items():
        commands = [Command(**cmd) for cmd in profile_data.get("commands", [])]
        urls = [URL(**url) for url in profile_data.get("urls", [])]

        profiles[profile_name] = Profile(
            name=profile_name,
            ide=profile_data.get("ide"),
            folders=profile_data.get("folders", []),
            files=profile_data.get("files", []),
            commands=commands,
            urls=urls,
        )

    return Project(
        name=project_name,
        config_path=filepath,
        icon=data.get("icon"),
        tags=data.get("tags", []),
        profiles=profiles,
        default_profile_name=data.get("default_profile_name", "dev"),
    )

class ProjectManager:
    """
    Discovers, loads, and manages all projects from the project directory.
    """
    def __init__(self, projects_dir: str):
        self.projects_dir = projects_dir
        self.projects: List[Project] = []
        self.discover_and_load_projects()

    def discover_and_load_projects(self):
        """
        Scans the projects directory for .toml files and loads them.
        """
        self.projects = []
        if not os.path.isdir(self.projects_dir):
            print(f"Warning: Projects directory not found: {self.projects_dir}")
            return

        for filename in os.listdir(self.projects_dir):
            if filename.endswith(".toml"):
                filepath = os.path.join(self.projects_dir, filename)
                try:
                    project = load_project_from_toml(filepath)
                    self.projects.append(project)
                except ProjectLoadError as e:
                    print(f"Error loading project from {filepath}: {e}")

    def get_all_projects(self) -> List[Project]:
        """Returns the list of all loaded projects."""
        return self.projects
