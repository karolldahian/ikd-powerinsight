from datetime import UTC, datetime

import pytest
from pint.errors import UndefinedUnitError

from powerinsight.domain.models import (
    Measurement,
    MeasurementKind,
    MeasurementSession,
)
from powerinsight.domain.units import unit_registry
from powerinsight.interfaces.schemas import MeasurementInput


@pytest.mark.parametrize(
    "kind",
    [
        MeasurementKind.ACTIVE_POWER,
        MeasurementKind.REACTIVE_POWER,
        MeasurementKind.APPARENT_POWER,
    ],
)
def test_power_measurements_normalize_to_watts(
    kind: MeasurementKind,
) -> None:
    measurement = Measurement(
        id="measurement-1",
        session_id="session-1",
        kind=kind,
        value=unit_registry.Quantity(1.5, "kilowatt"),
        measured_at=datetime(2026, 9, 24, 14, 5, tzinfo=UTC),
    )

    assert measurement.kind is kind
    assert measurement.value.magnitude == pytest.approx(1500)
    assert measurement.value.units == unit_registry.watt


def test_power_factor_normalizes_to_dimensionless() -> None:
    measurement = Measurement(
        id="measurement-1",
        session_id="session-1",
        kind=MeasurementKind.POWER_FACTOR,
        value=unit_registry.Quantity(95, "percent"),
        measured_at=datetime(2026, 9, 24, 14, 5, tzinfo=UTC),
    )

    assert measurement.value.dimensionless
    assert measurement.value.magnitude == pytest.approx(0.95)


def test_measurement_session_rejects_naive_ended_at() -> None:
    with pytest.raises(ValueError, match="timezone"):
        MeasurementSession(
            id="session-1",
            site_id="site-1",
            started_at=datetime(2026, 9, 24, 14, 0, tzinfo=UTC),
            ended_at=datetime(2026, 9, 24, 15, 0),
        )


def test_unknown_unit_is_rejected_when_boundary_enters_domain() -> None:
    data = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 120,
            "unit": "not_a_real_unit",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    with pytest.raises(UndefinedUnitError):
        data.to_domain()
