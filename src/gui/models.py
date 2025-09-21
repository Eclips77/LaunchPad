"""
Contains Qt Models for bridging Python data to the QML interface.
"""
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt
from typing import List, Any, Optional

# Assuming this path is correct relative to the execution context
from src.core.project import Project

class ProjectListModel(QAbstractListModel):
    """
    A Qt List Model for exposing the list of projects to QML.
    """
    # Define the roles that QML can access.
    # Each role corresponds to a piece of data in the Project object.
    NameRole = Qt.UserRole + 1
    IconRole = Qt.UserRole + 2
    ProfileRole = Qt.UserRole + 3
    TagsRole = Qt.UserRole + 4

    def __init__(self, projects: Optional[List[Project]] = None, parent=None):
        super().__init__(parent)
        self._projects = projects or []

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        """
        Returns the data for a given item index and role.
        This is the central method QML uses to query data.
        """
        if not index.isValid() or not (0 <= index.row() < len(self._projects)):
            return None

        project = self._projects[index.row()]

        if role == self.NameRole:
            return project.name
        elif role == self.IconRole:
            return project.icon
        elif role == self.ProfileRole:
            # For now, just return the name of the default profile
            return project.default_profile_name
        elif role == self.TagsRole:
            return project.tags

        return None

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        """
        Returns the total number of rows in the model.
        """
        return len(self._projects)

    def roleNames(self) -> dict:
        """
        Maps the integer roles to bytestring names that can be used
        as property names in the QML delegate.
        """
        return {
            self.NameRole: b"name",
            self.IconRole: b"icon",
            self.ProfileRole: b"profile",
            self.TagsRole: b"tags",
        }
