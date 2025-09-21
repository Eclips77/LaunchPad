"""Launch orchestration and lifecycle management utilities."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Iterable, List, Optional

from PySide6.QtCore import QObject, Slot

from .project import Component, Project


def _timestamp() -> str:
    """Return the current time formatted for log entries."""

    return datetime.now().strftime("%H:%M")


def _limit(entries: List[str], maximum: int = 100) -> List[str]:
    """Return the last *maximum* entries from *entries*."""

    if len(entries) <= maximum:
        return entries
    return entries[-maximum:]


class LaunchService(QObject):
    """Manage in-memory project definitions and component lifecycle actions."""

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._projects: Dict[str, Project] = {}
        self._load_initial_state()

    # ------------------------------------------------------------------
    # Public API exposed to QML
    # ------------------------------------------------------------------
    @Slot(result="QVariantList")
    def project_overview(self) -> List[Dict[str, Any]]:
        """Return an overview payload for all configured projects."""

        return [project.to_overview() for project in self._iter_projects()]

    @Slot(result="QVariantMap")
    def project_details(self) -> Dict[str, Dict[str, Any]]:
        """Return the detailed payload for every project keyed by slug."""

        return {project.key: project.to_dict() for project in self._iter_projects()}

    @Slot(str, result="QVariantMap")
    def project_detail(self, project_key: str) -> Dict[str, Any]:
        """Return the detail payload for *project_key* if it exists."""

        project = self._projects.get(project_key)
        return project.to_dict() if project else {}

    @Slot(str, result="QVariantMap")
    def project_overview_for(self, project_key: str) -> Dict[str, Any]:
        """Return a single project overview entry."""

        project = self._projects.get(project_key)
        return project.to_overview() if project else {}

    @Slot(str, str, result="QVariantMap")
    def launch_project(self, project_key: str, profile: str = "") -> Dict[str, Any]:
        """Launch every component belonging to *project_key*."""

        project = self._projects.get(project_key)
        if not project:
            return {}

        active_profile = profile or project.last_profile or project.default_profile
        for component in project.components:
            self._set_component_running(component, f"Launch profile {active_profile}")
        project.last_profile = active_profile
        project.add_history(f"Launch ({active_profile})")
        self._finalise_project_update(project)
        return self._result_payload(project)

    @Slot(str, str, result="QVariantMap")
    def start_component(self, project_key: str, component_name: str) -> Dict[str, Any]:
        """Start a specific component."""

        return self._component_action(project_key, component_name, "start")

    @Slot(str, str, result="QVariantMap")
    def stop_component(self, project_key: str, component_name: str) -> Dict[str, Any]:
        """Stop a specific component."""

        return self._component_action(project_key, component_name, "stop")

    @Slot(str, str, result="QVariantMap")
    def pause_component(self, project_key: str, component_name: str) -> Dict[str, Any]:
        """Pause a specific component."""

        return self._component_action(project_key, component_name, "pause")

    @Slot(str, str, result="QVariantMap")
    def resume_component(self, project_key: str, component_name: str) -> Dict[str, Any]:
        """Resume a specific component."""

        return self._component_action(project_key, component_name, "resume")

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _iter_projects(self) -> Iterable[Project]:
        return sorted(self._projects.values(), key=lambda project: project.name.lower())

    def _component_action(self, project_key: str, component_name: str, action: str) -> Dict[str, Any]:
        project = self._projects.get(project_key)
        if not project:
            return {}

        component = self._find_component(project, component_name)
        if component is None:
            return {}

        if action == "start":
            self._set_component_running(component, "Manual start")
            project.add_history(f"Start {component.name}")
        elif action == "stop":
            self._set_component_status(component, "Stopped", "Stopped via LaunchPad")
            project.add_history(f"Stop {component.name}")
        elif action == "pause":
            self._set_component_status(component, "Paused", "Paused via LaunchPad")
            project.add_history(f"Pause {component.name}")
        elif action == "resume":
            self._set_component_running(component, "Resume")
            project.add_history(f"Resume {component.name}")
        else:
            return {}

        self._finalise_project_update(project)
        return self._result_payload(project)

    def _set_component_running(self, component: Component, context: str) -> None:
        self._set_component_status(component, "Running", context)

    def _set_component_status(self, component: Component, status: str, detail: str) -> None:
        component.status = status
        component.status_detail = detail
        log_entry = f"[{_timestamp()}] {status}: {detail}"
        component.logs = _limit([*component.logs, log_entry])

    def _find_component(self, project: Project, component_name: str) -> Optional[Component]:
        for component in project.components:
            if component.name == component_name:
                return component
        return None

    def _finalise_project_update(self, project: Project) -> None:
        project.status = self._derive_project_status(project)
        project.active = project.status in {"Running", "Paused"}
        project.touch()

    def _derive_project_status(self, project: Project) -> str:
        statuses = [component.status.lower() for component in project.components]
        if not statuses:
            return "Ready"
        if any("fail" in status or "error" in status for status in statuses):
            return "Needs Attention"
        if any("running" in status for status in statuses):
            return "Running"
        if any("paused" in status for status in statuses):
            return "Paused"
        if all("stopped" in status for status in statuses):
            return "Stopped"
        return "Ready"

    def _result_payload(self, project: Project) -> Dict[str, Any]:
        return {"project": project.to_dict(), "overview": project.to_overview()}

    def _load_initial_state(self) -> None:
        now = datetime.utcnow()
        for payload in _SAMPLE_PROJECTS:
            project = Project.from_dict(payload)
            project.created_at = now
            project.updated_at = now
            self._finalise_project_update(project)
            self._projects[project.key] = project


_SAMPLE_PROJECTS: List[Dict[str, Any]] = [
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
            }
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


__all__ = ["LaunchService"]
