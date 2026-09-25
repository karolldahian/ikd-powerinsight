from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Organization:
    id: str
    name: str


@dataclass(frozen=True, slots=True)
class Site:
    id: str
    organization_id: str
    name: str


@dataclass(frozen=True, slots=True)
class Supply:
    id: str
    site_id: str
    name: str


@dataclass(frozen=True, slots=True)
class Panel:
    id: str
    supply_id: str
    name: str


@dataclass(frozen=True, slots=True)
class Circuit:
    id: str
    panel_id: str
    name: str


@dataclass(frozen=True, slots=True)
class Equipment:
    id: str
    site_id: str
    name: str
    circuit_id: str | None = None
    notes: str | None = None
    tags: tuple[str, ...] = ()
