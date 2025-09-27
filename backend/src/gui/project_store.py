"""QML-facing data model and store for LaunchPad projects."""
from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional, Sequence

from PySide6.QtCore import (
    QAbstractListModel,
    QModelIndex,
    QObject,
    Property,
    Qt,
    Signal,
    Slot,
)

from core.database import ProjectDatabase
from core.project import Project


def _split_tags(value: Any) -> List[str]:
    """Return *value* as a list of tag strings."""

    if value is None:
        return []
    if isinstance(value, str):
        return [item.strip() for item in value.split(",") if item.strip()]
    if isinstance(value, Iterable):
        return [str(item) for item in value if str(item).strip()]
    return [str(value)]


class ProjectListModel(QAbstractListModel):
    """Expose :class:`~core.project.Project` instances to QML."""

    KeyRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    IconRole = Qt.UserRole + 3
    LastProfileRole = Qt.UserRole + 4
    TagsRole = Qt.UserRole + 5
    StatusRole = Qt.UserRole + 6
    FavoriteRole = Qt.UserRole + 7
    ActiveRole = Qt.UserRole + 8
    UsageHoursRole = Qt.UserRole + 9

    countChanged = Signal()

    def __init__(self, store: "ProjectStore", parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._store = store
        self._projects: List[Project] = []
        self._overview: List[Dict[str, Any]] = []
        self._key_to_row: Dict[str, int] = {}
        self._role_names = {
            int(self.KeyRole): b"key",
            int(self.NameRole): b"name",
            int(self.IconRole): b"icon",
            int(self.LastProfileRole): b"lastProfile",
            int(self.TagsRole): b"tags",
            int(self.StatusRole): b"status",
            int(self.FavoriteRole): b"favorite",
            int(self.ActiveRole): b"active",
            int(self.UsageHoursRole): b"usageHours",
        }

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
        overview = self._overview[row]
        if role == Qt.DisplayRole:
            return overview.get("name")
        if role == int(self.KeyRole):
            return overview.get("key")
        if role == int(self.NameRole):
            return overview.get("name")
        if role == int(self.IconRole):
            return overview.get("icon")
        if role == int(self.LastProfileRole):
            return overview.get("lastProfile")
        if role == int(self.TagsRole):
            return overview.get("tags")
        if role == int(self.StatusRole):
            return overview.get("status")
        if role == int(self.FavoriteRole):
            return overview.get("favorite")
        if role == int(self.ActiveRole):
            return overview.get("active")
        if role == int(self.UsageHoursRole):
            return overview.get("usageHours")
        return None

    def roleNames(self) -> Dict[int, bytes]:  # type: ignore[override]
        return self._role_names

    def flags(self, index: QModelIndex) -> Qt.ItemFlags:  # type: ignore[override]
        if not index.isValid():
            return Qt.NoItemFlags
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsEditable

    def setData(self, index: QModelIndex, value: Any, role: int = Qt.EditRole) -> bool:  # type: ignore[override]
        if not index.isValid():
            return False
        row = index.row()
        if row < 0 or row >= len(self._projects):
            return False
        project = self._projects[row]
        changed_roles: List[int] = []

        if role == int(self.FavoriteRole):
            new_value = bool(value)
            if project.favorite == new_value:
                return False
            project.favorite = new_value
            changed_roles.append(role)
        elif role == int(self.ActiveRole):
            new_value = bool(value)
            if project.active == new_value:
                return False
            project.active = new_value
            changed_roles.append(role)
        elif role == int(self.LastProfileRole):
            new_value = str(value)
            if project.last_profile == new_value:
                return False
            project.last_profile = new_value
            changed_roles.append(role)
        elif role == int(self.StatusRole):
            new_value = str(value)
            if project.status == new_value:
                return False
            project.status = new_value
            changed_roles.append(role)
        elif role == int(self.UsageHoursRole):
            try:
                new_value = float(value)
            except (TypeError, ValueError):
                return False
            if project.usage_hours == new_value:
                return False
            project.usage_hours = new_value
            changed_roles.append(role)
        else:
            return False

        self._overview[row] = project.to_overview()
        model_index = self.index(row, 0)
        self.dataChanged.emit(model_index, model_index, changed_roles)
        self._store.on_project_updated(project, changed_roles)
        return True

    @Property(int, notify=countChanged)
    def count(self) -> int:
        return len(self._projects)

    # ------------------------------------------------------------------
    # Model maintenance helpers
    # ------------------------------------------------------------------
    def replace(self, projects: Iterable[Project]) -> None:
        self.beginResetModel()
        self._projects = list(projects)
        self._overview = [project.to_overview() for project in self._projects]
        self._key_to_row = {project.key: row for row, project in enumerate(self._projects)}
        self.endResetModel()
        self.countChanged.emit()

    def add_or_update(self, project: Project) -> bool:
        row = self._key_to_row.get(project.key)
        if row is None:
            row = len(self._projects)
            self.beginInsertRows(QModelIndex(), row, row)
            self._projects.append(project)
            self._overview.append(project.to_overview())
            self._key_to_row[project.key] = row
            self.endInsertRows()
            self.countChanged.emit()
            return True
        self._projects[row] = project
        self._overview[row] = project.to_overview()
        model_index = self.index(row, 0)
        self.dataChanged.emit(model_index, model_index, list(self._role_names.keys()))
        return False

    def iter_projects(self) -> Iterable[Project]:
        return tuple(self._projects)

    @Slot(int, result="QVariant")
    def get(self, row: int) -> Dict[str, Any]:
        if row < 0 or row >= len(self._overview):
            return {}
        return dict(self._overview[row])


class ProjectStore(QObject):
    """Bridge between the SQLite persistence layer and QML views."""

    projectsModelChanged = Signal()
    projectDetailsChanged = Signal()
    tagOptionsChanged = Signal()

    def __init__(self, database: Optional[ProjectDatabase] = None, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._database = database or ProjectDatabase()
        self._model = ProjectListModel(self)
        self._project_details: Dict[str, Dict[str, Any]] = {}
        self._tag_options: List[str] = []
        self._load_initial_projects()

    # ------------------------------------------------------------------
    # Qt properties
    # ------------------------------------------------------------------
    @Property(QObject, notify=projectsModelChanged)
    def projectsModel(self) -> ProjectListModel:
        return self._model

    @Property("QVariantMap", notify=projectDetailsChanged)
    def projectDetails(self) -> Dict[str, Any]:
        return self._project_details

    @Property("QVariantList", notify=tagOptionsChanged)
    def tagOptions(self) -> List[str]:
        return self._tag_options

    # ------------------------------------------------------------------
    # QML API
    # ------------------------------------------------------------------
    @Slot("QVariantMap", result=bool)
    def create_from_summary(self, summary: Dict[str, Any]) -> bool:
        try:
            project = self._project_from_summary(summary)
        except ValueError:
            return False
        project = self._database.upsert_project(project)
        self._model.add_or_update(project)
        self._project_details[project.key] = project.to_dict()
        self.projectDetailsChanged.emit()
        self._update_tag_options()
        return True

    @Slot(str, result="QVariantMap")
    def get_project(self, key: str) -> Dict[str, Any]:
        return self._project_details.get(key, {})

    # ------------------------------------------------------------------
    # Callbacks from the list model
    # ------------------------------------------------------------------
    def on_project_updated(self, project: Project, roles: Sequence[int]) -> None:
        self._database.upsert_project(project)
        self._project_details[project.key] = project.to_dict()
        self.projectDetailsChanged.emit()
        if int(ProjectListModel.TagsRole) in roles:
            self._update_tag_options()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _load_initial_projects(self) -> None:
        projects = self._database.list_projects()
        if not projects:
            projects = [Project.from_dict(payload) for payload in _INITIAL_PROJECTS]
            for project in projects:
                self._database.upsert_project(project)
        self._model.replace(projects)
        self._project_details = {project.key: project.to_dict() for project in self._model.iter_projects()}
        self.projectDetailsChanged.emit()
        self._update_tag_options()

    def _update_tag_options(self) -> None:
        tags = set()
        for project in self._model.iter_projects():
            tags.update(project.tags)
        self._tag_options = sorted(tags)
        self.tagOptionsChanged.emit()

    def _project_from_summary(self, summary: Dict[str, Any]) -> Project:
        key = str(summary.get("key", "")).strip()
        name = str(summary.get("name", "")).strip()
        if not key or not name:
            raise ValueError("Project key and name are required")
        icon = str(summary.get("icon", "📁")) or "📁"
        default_profile = str(summary.get("defaultProfile", "dev")) or "dev"
        last_profile = str(summary.get("lastProfile", default_profile)) or default_profile
        description = str(summary.get("description", summary.get("summary", "")))
        tags = _split_tags(summary.get("tags"))
        status = str(summary.get("status", "Ready")) or "Ready"
        favorite = bool(summary.get("favorite", False))
        active = bool(summary.get("active", False))
        usage_hours = float(summary.get("usageHours", 0.0))
        components = summary.get("components") or []
        quick_links = summary.get("quickLinks") or []
        folders = summary.get("folders") or []
        history = summary.get("history") or []
        health_checks = summary.get("healthChecks") or []

        payload: Dict[str, Any] = {
            "key": key,
            "name": name,
            "icon": icon,
            "defaultProfile": default_profile,
            "lastProfile": last_profile,
            "summary": description,
            "tags": tags,
            "status": status,
            "favorite": favorite,
            "active": active,
            "usageHours": usage_hours,
            "components": components,
            "quickLinks": quick_links,
            "folders": folders,
            "history": history,
            "healthChecks": health_checks,
        }
        return Project.from_dict(payload)


_INITIAL_PROJECTS: List[Dict[str, Any]] = [
    {
        "key": "nebula",
        "name": "Nebula CRM",
        "icon": "🪐",
        "defaultProfile": "dev",
        "lastProfile": "dev",
        "summary": "Customer portal with FastAPI backend and Vue dashboard.",
        "tags": ["fastapi", "postgres", "docker"],
        "status": "Ready",
        "favorite": True,
        "active": True,
        "usageHours": 18.5,
        "components": [
            {
                "name": "FastAPI Service",
                "status": "Running",
                "summary": "Uvicorn server with auto-reload",
                "statusDetail": "HTTP 200 · Port 8000",
                "logs": [
                    "[09:40] Boot sequence started",
                    "[09:40] Loaded environment dev",
                    "[09:41] Listening on 0.0.0.0:8000",
                ],
                "healthChecks": [
                    {"label": "HTTP", "status": "Healthy", "detail": "200 OK"},
                    {"label": "Docker", "status": "Healthy", "detail": "Container healthy"},
                ],
            },
            {
                "name": "Worker Queue",
                "status": "Running",
                "summary": "Celery worker connected to Redis",
                "statusDetail": "Processing 3 jobs",
                "logs": [
                    "[09:39] Worker online",
                    "[09:41] Consumed task send_welcome_email",
                ],
                "healthChecks": [
                    {"label": "Redis", "status": "Healthy", "detail": "Ping 1.2ms"},
                ],
            },
            {
                "name": "Frontend Dev Server",
                "status": "Paused",
                "summary": "Vite dev server for Vue dashboard",
                "statusDetail": "Paused by user",
                "logs": [
                    "[08:12] npm run dev",
                    "[08:15] Hot reload triggered",
                ],
                "healthChecks": [
                    {"label": "HTTP", "status": "Paused", "detail": "Server paused"},
                ],
            },
        ],
        "quickLinks": [
            {"label": "Swagger Docs", "url": "http://localhost:8000/docs"},
            {"label": "Admin Portal", "url": "http://localhost:5173"},
        ],
        "folders": [
            {"label": "Repository", "path": "~/Projects/nebula"},
            {"label": "Docker Compose", "path": "~/Projects/nebula/ops"},
        ],
        "history": [
            {"time": "09:42", "description": "Launch (dev)"},
            {"time": "09:44", "description": "Restart FastAPI"},
            {"time": "09:50", "description": "Teardown frontend"},
        ],
        "healthChecks": [
            {"label": "API endpoint", "status": "Healthy", "detail": "200 OK"},
            {"label": "Docker compose", "status": "Healthy", "detail": "All containers healthy"},
            {"label": "Port 8000", "status": "Healthy", "detail": "Listening"},
        ],
    },
    {
        "key": "aurora",
        "name": "Aurora Analytics",
        "icon": "📊",
        "defaultProfile": "staging",
        "lastProfile": "staging",
        "summary": "Data pipeline with Node + Vite front-end dashboard.",
        "tags": ["data", "frontend", "vite"],
        "status": "Running",
        "favorite": False,
        "active": True,
        "usageHours": 9.2,
        "components": [
            {
                "name": "Ingestion Worker",
                "status": "Running",
                "summary": "Python ETL job",
                "statusDetail": "Processing feed alpha",
                "logs": [
                    "[08:30] Sync started",
                    "[08:45] 1234 records processed",
                ],
                "healthChecks": [
                    {"label": "Database", "status": "Healthy", "detail": "Latency 20ms"},
                ],
            },
            {
                "name": "Analytics UI",
                "status": "Running",
                "summary": "Vite dev server",
                "statusDetail": "Listening on 5174",
                "logs": [
                    "[08:12] yarn dev",
                    "[08:20] Hot reload",
                ],
                "healthChecks": [
                    {"label": "HTTP", "status": "Healthy", "detail": "200 OK"},
                ],
            },
        ],
        "quickLinks": [
            {"label": "Vite Dashboard", "url": "http://localhost:5174"},
            {"label": "Grafana", "url": "http://localhost:3000"},
        ],
        "folders": [
            {"label": "Repository", "path": "~/Projects/aurora"},
        ],
        "history": [
            {"time": "Yesterday", "description": "Deploy staging"},
        ],
        "healthChecks": [
            {"label": "HTTP 5174", "status": "Healthy", "detail": "Dashboard ready"},
            {"label": "Queue depth", "status": "Healthy", "detail": "4 pending"},
        ],
    },
    {
        "key": "lunar",
        "name": "Lunar Ops",
        "icon": "🌗",
        "defaultProfile": "dev",
        "lastProfile": "dev",
        "summary": "Dockerized ops toolkit with mixed services.",
        "tags": ["docker", "compose", "ops"],
        "status": "Needs Attention",
        "favorite": False,
        "active": False,
        "usageHours": 3.4,
        "components": [
            {
                "name": "API Gateway",
                "status": "Failed",
                "summary": "Nginx reverse proxy",
                "statusDetail": "Container exited",
                "logs": [
                    "[07:12] nginx start",
                    "[07:15] missing certificate",
                ],
                "healthChecks": [
                    {"label": "Docker", "status": "Failed", "detail": "Exited (1)"},
                ],
            },
            {
                "name": "Telemetry",
                "status": "Stopped",
                "summary": "Prometheus instance",
                "statusDetail": "Stopped by user",
                "logs": [
                    "[06:50] Shutdown initiated",
                ],
                "healthChecks": [
                    {"label": "Port 9090", "status": "Stopped", "detail": "Not listening"},
                ],
            },
        ],
        "quickLinks": [
            {"label": "Operations Wiki", "url": "http://confluence.local/lunar"},
        ],
        "folders": [
            {"label": "Repository", "path": "~/Projects/lunar"},
            {"label": "Docker", "path": "~/Projects/lunar/docker"},
        ],
        "history": [
            {"time": "Today", "description": "Launch attempt failed"},
        ],
        "healthChecks": [
            {"label": "Gateway", "status": "Failed", "detail": "Container exited"},
            {"label": "Prometheus", "status": "Stopped", "detail": "Inactive"},
        ],
    },
    {
        "key": "quasar",
        "name": "Quasar Docs",
        "icon": "📚",
        "defaultProfile": "dev",
        "lastProfile": "dev",
        "summary": "Documentation toolchain built with mdBook.",
        "tags": ["docs", "mdbook"],
        "status": "Ready",
        "favorite": True,
        "active": False,
        "usageHours": 6.8,
        "components": [
            {
                "name": "mdBook Serve",
                "status": "Running",
                "summary": "mdbook serve --open",
                "statusDetail": "Listening on :3001",
                "logs": [
                    "[08:01] Rebuild complete",
                    "[08:05] Watching files",
                ],
                "healthChecks": [
                    {"label": "HTTP", "status": "Healthy", "detail": "200 OK"},
                ],
            },
        ],
        "quickLinks": [
            {"label": "Docs", "url": "http://localhost:3001"},
            {"label": "GitHub", "url": "https://github.com/org/quasar"},
        ],
        "folders": [
            {"label": "Repository", "path": "~/Projects/quasar"},
        ],
        "history": [
            {"time": "Today", "description": "Launch (dev)"},
        ],
        "healthChecks": [
            {"label": "HTTP", "status": "Healthy", "detail": "200 OK"},
        ],
    },
]

__all__ = ["ProjectStore", "ProjectListModel"]
