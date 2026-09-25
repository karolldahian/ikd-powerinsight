from dataclasses import dataclass
from enum import StrEnum


class ProtectionDeviceType(StrEnum):
    CIRCUIT_BREAKER = "circuit_breaker"
    FUSE = "fuse"
    OTHER = "other"


@dataclass(frozen=True, slots=True)
class Nameplate:
    id: str
    equipment_id: str
    manufacturer: str | None = None
    model: str | None = None
    raw_text: str | None = None


@dataclass(frozen=True, slots=True)
class ProtectionDevice:
    id: str
    circuit_id: str
    device_type: ProtectionDeviceType


@dataclass(frozen=True, slots=True)
class ConductorRun:
    id: str
    circuit_id: str
