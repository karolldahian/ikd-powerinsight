import pytest
from pydantic import ValidationError

from powerinsight.domain.models import MeasurementKind
from powerinsight.domain.units import unit_registry
from powerinsight.interfaces.schemas import MeasurementInput


def test_measurement_input_parses_external_data() -> None:
    data = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 0.12,
            "unit": "kilovolt",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    assert data.kind is MeasurementKind.VOLTAGE
    assert data.value == 0.12
    assert data.unit == "kilovolt"


def test_measurement_input_rejects_extra_fields() -> None:
    with pytest.raises(ValidationError):
        MeasurementInput.model_validate(
            {
                "id": "measurement-1",
                "session_id": "session-1",
                "kind": "voltage",
                "value": 120,
                "unit": "volt",
                "measured_at": "2026-09-24T14:05:00+00:00",
                "unexpected": "value",
            }
        )


def test_measurement_input_converts_to_domain_model() -> None:
    data = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 0.12,
            "unit": "kilovolt",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    measurement = data.to_domain()

    assert measurement.value.magnitude == pytest.approx(120)
    assert measurement.value.units == unit_registry.volt


def test_domain_still_rejects_naive_datetime() -> None:
    data = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 120,
            "unit": "volt",
            "measured_at": "2026-09-24T14:05:00",
        }
    )

    with pytest.raises(ValueError, match="timezone"):
        data.to_domain()


def test_domain_still_rejects_incompatible_dimension() -> None:
    data = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 10,
            "unit": "ampere",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    with pytest.raises(ValueError, match="incompatible"):
        data.to_domain()
