from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class MeasurementKind(StrEnum):
    VOLTAGE = "voltage"
    CURRENT = "current"
    ACTIVE_POWER = "active_power"
    REACTIVE_POWER = "reactive_power"
    APPARENT_POWER = "apparent_power"
    POWER_FACTOR = "power_factor"
    FREQUENCY = "frequency"


def _require_aware_datetime(value: datetime, field_name: str) -> None:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError(f"{field_name} must include timezone information.")


@dataclass(frozen=True, slots=True)
class MeasurementSession:
    id: str
    site_id: str
    started_at: datetime
    ended_at: datetime | None = None

    def __post_init__(self) -> None:
        _require_aware_datetime(self.started_at, "started_at")

        if self.ended_at is not None:
            _require_aware_datetime(self.ended_at, "ended_at")

            if self.ended_at < self.started_at:
                raise ValueError("ended_at cannot be earlier than started_at.")


@dataclass(frozen=True, slots=True)
class Measurement:
    id: str
    session_id: str
    kind: MeasurementKind
    measured_at: datetime

    def __post_init__(self) -> None:
        _require_aware_datetime(self.measured_at, "measured_at")
