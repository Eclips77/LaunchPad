"""SQLite-backed persistence layer for LaunchPad projects."""
from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Iterable, Iterator, List, Optional

from .project import Project

_DEFAULT_DB_NAME = "projects.db"


class ProjectDatabase:
    """Manage persistence for :class:`~launchpad.core.project.Project` objects."""

    def __init__(self, path: str | Path | None = None) -> None:
        self._path = self._resolve_path(path)
        self._connection: Optional[sqlite3.Connection] = None

    # ------------------------------------------------------------------
    # Connection management
    # ------------------------------------------------------------------
    @staticmethod
    def _resolve_path(path: str | Path | None) -> str:
        if path is None:
            base = Path.home() / ".launchpad"
            base.mkdir(parents=True, exist_ok=True)
            return str(base / _DEFAULT_DB_NAME)
        if isinstance(path, Path):
            candidate = path.expanduser()
        else:
            candidate = Path(path).expanduser()
        if str(candidate) != ":memory:":
            candidate.parent.mkdir(parents=True, exist_ok=True)
        return str(candidate)

    def connect(self) -> sqlite3.Connection:
        if self._connection is None:
            self._connection = sqlite3.connect(self._path)
            self._connection.row_factory = sqlite3.Row
            self._apply_pragmas()
            self._ensure_schema()
        return self._connection

    def _apply_pragmas(self) -> None:
        conn = self._connection
        if conn is None:
            return
        conn.execute("PRAGMA foreign_keys = ON")

    def _ensure_schema(self) -> None:
        conn = self._connection
        if conn is None:
            return
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS projects (
                key TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT,
                default_profile TEXT,
                last_profile TEXT,
                summary TEXT,
                tags TEXT,
                status TEXT,
                favorite INTEGER NOT NULL DEFAULT 0,
                active INTEGER NOT NULL DEFAULT 0,
                usage_hours REAL NOT NULL DEFAULT 0,
                data TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_projects_status
            ON projects(status)
            """
        )
        conn.commit()

    def close(self) -> None:
        if self._connection is not None:
            self._connection.close()
            self._connection = None

    def __enter__(self) -> "ProjectDatabase":
        self.connect()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    @contextmanager
    def transaction(self) -> Iterator[sqlite3.Connection]:
        conn = self.connect()
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise

    # ------------------------------------------------------------------
    # Project CRUD operations
    # ------------------------------------------------------------------
    def list_projects(self) -> List[Project]:
        conn = self.connect()
        cursor = conn.execute("SELECT data FROM projects ORDER BY name ASC")
        return [self._row_to_project(row) for row in cursor.fetchall()]

    def get_project(self, key: str) -> Optional[Project]:
        conn = self.connect()
        row = conn.execute("SELECT data FROM projects WHERE key = ?", (key,)).fetchone()
        if row is None:
            return None
        return self._row_to_project(row)

    def upsert_project(self, project: Project) -> Project:
        conn = self.connect()
        now = datetime.utcnow()
        existing = self.get_project(project.key)
        if project.created_at is None:
            project.created_at = existing.created_at if existing else now
        project.updated_at = now
        payload = project.to_dict()
        data_json = json.dumps(payload, ensure_ascii=False, sort_keys=True)
        with self.transaction() as txn:
            txn.execute(
                """
                INSERT INTO projects (
                    key, name, icon, default_profile, last_profile, summary, tags,
                    status, favorite, active, usage_hours, data, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    name=excluded.name,
                    icon=excluded.icon,
                    default_profile=excluded.default_profile,
                    last_profile=excluded.last_profile,
                    summary=excluded.summary,
                    tags=excluded.tags,
                    status=excluded.status,
                    favorite=excluded.favorite,
                    active=excluded.active,
                    usage_hours=excluded.usage_hours,
                    data=excluded.data,
                    updated_at=excluded.updated_at
                """,
                (
                    project.key,
                    project.name,
                    project.icon,
                    project.default_profile,
                    project.last_profile,
                    project.summary,
                    project.tags_as_text,
                    project.status,
                    int(project.favorite),
                    int(project.active),
                    project.usage_hours,
                    data_json,
                    project.created_at.isoformat(),
                    project.updated_at.isoformat(),
                ),
            )
        return project

    def delete_project(self, key: str) -> bool:
        conn = self.connect()
        with self.transaction() as txn:
            cursor = txn.execute("DELETE FROM projects WHERE key = ?", (key,))
        return cursor.rowcount > 0

    def set_favorite(self, key: str, is_favorite: bool) -> Optional[Project]:
        project = self.get_project(key)
        if not project:
            return None
        project.set_favorite(is_favorite)
        return self.upsert_project(project)

    def update_last_profile(self, key: str, profile: str) -> Optional[Project]:
        project = self.get_project(key)
        if not project:
            return None
        project.last_profile = profile
        return self.upsert_project(project)

    def record_history(self, key: str, description: str, timestamp: Optional[str] = None) -> Optional[Project]:
        project = self.get_project(key)
        if not project:
            return None
        project.add_history(description, timestamp)
        return self.upsert_project(project)

    def bulk_import(self, projects: Iterable[Project]) -> None:
        for project in projects:
            self.upsert_project(project)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _row_to_project(row: sqlite3.Row) -> Project:
        payload = json.loads(row["data"])
        return Project.from_dict(payload)


__all__ = ["ProjectDatabase"]
