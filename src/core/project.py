"""Data model definitions for LaunchPad projects."""
from __future__ import annotations

from collections.abc import Iterable as IterableABC, Mapping as MappingABC
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Mapping, Optional


def _normalize_sequence(value: Any) -> List[Any]:
    """Return *value* as a plain list.

    The QML layer historically worked with a mixture of comma separated strings
    and JSON arrays.  To keep backwards compatibility the helper accepts strings
    (splitting on commas) as well as arbitrary iterables.  ``None`` values are
    converted into an empty list.
    """

    if value is None:
        return []
    if isinstance(value, str):
        return [item.strip() for item in value.split(",") if item.strip()]
    if isinstance(value, MappingABC):
        return [value]
    if isinstance(value, IterableABC):
        return [item for item in value]
    return [value]


@dataclass
class HealthCheck:
    """Status information about a component or project."""

    label: str
    status: str
    detail: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "label": self.label,
            "status": self.status,
            "detail": self.detail,
        }

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "HealthCheck":
        return cls(
            label=str(payload.get("label", "")),
            status=str(payload.get("status", "")),
            detail=str(payload.get("detail", "")),
        )


@dataclass
class QuickLink:
    """Represents a quick access link for a project."""

    label: str
    url: str

    def to_dict(self) -> Dict[str, str]:
        return {"label": self.label, "url": self.url}

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "QuickLink":
        return cls(
            label=str(payload.get("label", "")),
            url=str(payload.get("url", "")),
        )


@dataclass
class FolderLink:
    """Represents a folder shortcut displayed in the UI."""

    label: str
    path: str

    def to_dict(self) -> Dict[str, str]:
        return {"label": self.label, "path": self.path}

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "FolderLink":
        return cls(
            label=str(payload.get("label", "")),
            path=str(payload.get("path", "")),
        )


@dataclass
class HistoryEvent:
    """Represents a single entry in the project activity log."""

    time: str
    description: str

    def to_dict(self) -> Dict[str, str]:
        return {"time": self.time, "description": self.description}

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "HistoryEvent":
        return cls(
            time=str(payload.get("time", "")),
            description=str(payload.get("description", "")),
        )


@dataclass
class Component:
    """Represents one component in a LaunchPad project."""

    name: str
    status: str
    summary: str = ""
    status_detail: str = ""
    logs: List[str] = field(default_factory=list)
    health_checks: List[HealthCheck] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status,
            "summary": self.summary,
            "statusDetail": self.status_detail,
            "logs": list(self.logs),
            "healthChecks": [check.to_dict() for check in self.health_checks],
        }

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "Component":
        logs = _normalize_sequence(payload.get("logs"))
        health_data = payload.get("healthChecks", [])
        health_checks = [
            HealthCheck.from_dict(item)
            for item in _normalize_sequence(health_data)
            if isinstance(item, MappingABC)
        ]
        return cls(
            name=str(payload.get("name", "")),
            status=str(payload.get("status", "")),
            summary=str(payload.get("summary", "")),
            status_detail=str(payload.get("statusDetail", payload.get("status_detail", ""))),
            logs=[str(item) for item in logs],
            health_checks=health_checks,
        )


@dataclass
class Project:
    """Data class describing a LaunchPad project and its metadata."""

    key: str
    name: str
    icon: str = "📁"
    default_profile: str = "dev"
    summary: str = ""
    tags: List[str] = field(default_factory=list)
    status: str = "Ready"
    favorite: bool = False
    active: bool = False
    last_profile: Optional[str] = None
    usage_hours: float = 0.0
    components: List[Component] = field(default_factory=list)
    quick_links: List[QuickLink] = field(default_factory=list)
    folders: List[FolderLink] = field(default_factory=list)
    history: List[HistoryEvent] = field(default_factory=list)
    health_checks: List[HealthCheck] = field(default_factory=list)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def __post_init__(self) -> None:
        if self.last_profile is None:
            self.last_profile = self.default_profile
        self.tags = [tag for tag in _normalize_sequence(self.tags)]
        self.usage_hours = float(self.usage_hours)

    # ------------------------------------------------------------------
    # Serialization helpers
    # ------------------------------------------------------------------
    def to_dict(self) -> Dict[str, Any]:
        """Convert the project into a JSON serialisable dictionary."""

        payload: Dict[str, Any] = {
            "key": self.key,
            "name": self.name,
            "icon": self.icon,
            "defaultProfile": self.default_profile,
            "lastProfile": self.last_profile,
            "summary": self.summary,
            "tags": list(self.tags),
            "status": self.status,
            "favorite": self.favorite,
            "active": self.active,
            "usageHours": self.usage_hours,
            "components": [component.to_dict() for component in self.components],
            "quickLinks": [link.to_dict() for link in self.quick_links],
            "folders": [folder.to_dict() for folder in self.folders],
            "history": [event.to_dict() for event in self.history],
            "healthChecks": [check.to_dict() for check in self.health_checks],
        }
        if self.created_at is not None:
            payload["createdAt"] = self.created_at.isoformat()
        if self.updated_at is not None:
            payload["updatedAt"] = self.updated_at.isoformat()
        return payload

    def to_overview(self) -> Dict[str, Any]:
        """Return only the fields required for the home screen grid."""

        return {
            "key": self.key,
            "name": self.name,
            "icon": self.icon,
            "lastProfile": self.last_profile,
            "tags": ", ".join(self.tags),
            "status": self.status,
            "favorite": self.favorite,
            "active": self.active,
            "usageHours": self.usage_hours,
        }

    @property
    def tags_as_text(self) -> str:
        """Return the project tags as a comma separated string."""

        return ", ".join(self.tags)

    @classmethod
    def from_dict(cls, payload: Mapping[str, Any]) -> "Project":
        """Create a project instance from a mapping."""

        tags = payload.get("tags", [])
        components_raw = payload.get("components", [])
        quick_links_raw = payload.get("quickLinks", [])
        folders_raw = payload.get("folders", [])
        history_raw = payload.get("history", [])
        health_checks_raw = payload.get("healthChecks", [])

        created_at = payload.get("createdAt")
        updated_at = payload.get("updatedAt")

        return cls(
            key=str(payload.get("key", "")),
            name=str(payload.get("name", "")),
            icon=str(payload.get("icon", "📁")),
            default_profile=str(payload.get("defaultProfile", payload.get("default_profile", "dev"))),
            last_profile=payload.get("lastProfile", payload.get("last_profile")),
            summary=str(payload.get("summary", "")),
            tags=_normalize_sequence(tags),
            status=str(payload.get("status", "Ready")),
            favorite=bool(payload.get("favorite", False)),
            active=bool(payload.get("active", False)),
            usage_hours=float(payload.get("usageHours", payload.get("usage_hours", 0.0))),
            components=[
                component
                if isinstance(component, Component)
                else Component.from_dict(component)
                for component in components_raw
                if isinstance(component, (MappingABC, Component))
            ],
            quick_links=[
                link
                if isinstance(link, QuickLink)
                else QuickLink.from_dict(link)
                for link in quick_links_raw
                if isinstance(link, (MappingABC, QuickLink))
            ],
            folders=[
                folder
                if isinstance(folder, FolderLink)
                else FolderLink.from_dict(folder)
                for folder in folders_raw
                if isinstance(folder, (MappingABC, FolderLink))
            ],
            history=[
                event
                if isinstance(event, HistoryEvent)
                else HistoryEvent.from_dict(event)
                for event in history_raw
                if isinstance(event, (MappingABC, HistoryEvent))
            ],
            health_checks=[
                check
                if isinstance(check, HealthCheck)
                else HealthCheck.from_dict(check)
                for check in health_checks_raw
                if isinstance(check, (MappingABC, HealthCheck))
            ],
            created_at=datetime.fromisoformat(created_at) if created_at else None,
            updated_at=datetime.fromisoformat(updated_at) if updated_at else None,
        )

    # ------------------------------------------------------------------
    # Domain helpers
    # ------------------------------------------------------------------
    def add_history(self, description: str, timestamp: Optional[str] = None) -> None:
        """Append a new history entry."""

        if timestamp is None:
            timestamp = datetime.now().strftime("%H:%M")
        self.history.append(HistoryEvent(time=timestamp, description=description))

    def set_favorite(self, is_favorite: bool) -> None:
        self.favorite = bool(is_favorite)

    def touch(self) -> None:
        """Update the ``updated_at`` timestamp to *now*."""

        self.updated_at = datetime.utcnow()

    def ensure_component(self, component: Component) -> None:
        """Add or replace a component with the same name."""

        for index, existing in enumerate(self.components):
            if existing.name == component.name:
                self.components[index] = component
                break
        else:
            self.components.append(component)


__all__ = [
    "HealthCheck",
    "QuickLink",
    "FolderLink",
    "HistoryEvent",
    "Component",
    "Project",
]
