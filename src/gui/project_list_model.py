"""Qt list model exposing :class:`~core.project.Project` instances to QML."""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from PySide6.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Slot

from core.database import ProjectDatabase
from core.project import Project


class ProjectListModel(QAbstractListModel):
    """Expose project overview information to Qt's model/view layer."""

    KeyRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    IconRole = Qt.UserRole + 3
    LastProfileRole = Qt.UserRole + 4
    TagsRole = Qt.UserRole + 5
    StatusRole = Qt.UserRole + 6
    FavoriteRole = Qt.UserRole + 7
    ActiveRole = Qt.UserRole + 8
    UsageHoursRole = Qt.UserRole + 9

    _ROLE_NAMES = {
        KeyRole: b"key",
        NameRole: b"name",
        IconRole: b"icon",
        LastProfileRole: b"lastProfile",
        TagsRole: b"tags",
        StatusRole: b"status",
        FavoriteRole: b"favorite",
        ActiveRole: b"active",
        UsageHoursRole: b"usageHours",
    }

    def __init__(self, database: ProjectDatabase, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._database = database
        self._projects: List[Project] = []
        self.refresh()

    # ------------------------------------------------------------------
    # Qt model API
    # ------------------------------------------------------------------
    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # type: ignore[override]
        if parent.isValid():
            return 0
        return len(self._projects)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:  # type: ignore[override]
        if not index.isValid():
            return None
        row = index.row()
        if row < 0 or row >= len(self._projects):
            return None
        project = self._projects[row]
        if role in (Qt.DisplayRole, ProjectListModel.NameRole):
            return project.name
        if role == ProjectListModel.KeyRole:
            return project.key
        if role == ProjectListModel.IconRole:
            return project.icon
        if role == ProjectListModel.LastProfileRole:
            return project.last_profile
        if role == ProjectListModel.TagsRole:
            return ", ".join(project.tags)
        if role == ProjectListModel.StatusRole:
            return project.status
        if role == ProjectListModel.FavoriteRole:
            return project.favorite
        if role == ProjectListModel.ActiveRole:
            return project.active
        if role == ProjectListModel.UsageHoursRole:
            return project.usage_hours
        return None

    def roleNames(self) -> Dict[int, bytes]:  # type: ignore[override]
        return dict(ProjectListModel._ROLE_NAMES)

    def flags(self, index: QModelIndex) -> Qt.ItemFlags:  # type: ignore[override]
        base_flags = super().flags(index)
        if not index.isValid():
            return base_flags
        return base_flags | Qt.ItemIsEditable

    def setData(self, index: QModelIndex, value: Any, role: int = Qt.EditRole) -> bool:  # type: ignore[override]
        if not index.isValid():
            return False
        row = index.row()
        if row < 0 or row >= len(self._projects):
            return False

        project = self._projects[row]
        changed = False

        if role == ProjectListModel.KeyRole:
            new_value = str(value)
            if new_value and new_value != project.key:
                project.key = new_value
                changed = True
        elif role == ProjectListModel.NameRole:
            new_value = str(value)
            if new_value != project.name:
                project.name = new_value
                changed = True
        elif role == ProjectListModel.IconRole:
            new_value = str(value)
            if new_value != project.icon:
                project.icon = new_value
                changed = True
        elif role == ProjectListModel.LastProfileRole:
            new_value = str(value)
            if new_value != project.last_profile:
                project.last_profile = new_value
                changed = True
        elif role == ProjectListModel.TagsRole:
            text = str(value)
            tags = [item.strip() for item in text.split(",") if item.strip()]
            if tags != project.tags:
                project.tags = tags
                changed = True
        elif role == ProjectListModel.StatusRole:
            new_value = str(value)
            if new_value != project.status:
                project.status = new_value
                changed = True
        elif role == ProjectListModel.FavoriteRole:
            new_value = bool(value)
            if new_value != project.favorite:
                project.favorite = new_value
                changed = True
        elif role == ProjectListModel.ActiveRole:
            new_value = bool(value)
            if new_value != project.active:
                project.active = new_value
                changed = True
        elif role == ProjectListModel.UsageHoursRole:
            try:
                new_value = float(value)
            except (TypeError, ValueError):
                new_value = project.usage_hours
            if new_value != project.usage_hours:
                project.usage_hours = new_value
                changed = True
        else:
            # Unsupported role
            return False

        if not changed:
            return False

        self._database.upsert_project(project)
        self.dataChanged.emit(index, index, [role])
        return True

    # ------------------------------------------------------------------
    # Data management helpers
    # ------------------------------------------------------------------
    def refresh(self) -> None:
        self.beginResetModel()
        self._projects = self._database.list_projects()
        self.endResetModel()

    def _project_overview(self, project: Project) -> Dict[str, Any]:
        return {
            "key": project.key,
            "name": project.name,
            "icon": project.icon,
            "lastProfile": project.last_profile,
            "tags": ", ".join(project.tags),
            "status": project.status,
            "favorite": project.favorite,
            "active": project.active,
            "usageHours": project.usage_hours,
        }

    def _project_by_key(self, key: str) -> Optional[Project]:
        for project in self._projects:
            if project.key == key:
                return project
        return None

    # ------------------------------------------------------------------
    # Invokable helpers for QML
    # ------------------------------------------------------------------
    @Slot(int, result="QVariant")
    def get(self, row: int) -> Dict[str, Any]:
        if 0 <= row < len(self._projects):
            return self._project_overview(self._projects[row])
        return {}

    @Slot(str, result="QVariant")
    def getProject(self, key: str) -> Dict[str, Any]:
        if not key:
            return {}
        project = self._project_by_key(key)
        if project is None:
            project = self._database.get_project(key)
        if project is None:
            return {}
        return project.to_dict()

    @Slot("QVariant", result=bool)
    def addProject(self, payload: Any) -> bool:
        if payload is None:
            return False
        if isinstance(payload, dict):
            data = dict(payload)
        else:
            try:
                data = dict(payload)
            except TypeError:
                return False

        description = data.get("description")
        if description and not data.get("summary"):
            data["summary"] = str(description)

        try:
            project = Project.from_dict(data)
        except Exception:
            return False

        self._database.upsert_project(project)
        self.refresh()
        return True

    @Slot()
    def reload(self) -> None:
        self.refresh()


__all__ = ["ProjectListModel"]
