import json

from powerinsight.interfaces.schemas import MeasurementInput


def test_measurement_input_serializes_to_json() -> None:
    measurement_input = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "voltage",
            "value": 120,
            "unit": "volt",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    serialized = json.loads(measurement_input.model_dump_json())

    assert serialized["id"] == "measurement-1"
    assert serialized["session_id"] == "session-1"
    assert serialized["kind"] == "voltage"
    assert serialized["value"] == 120
    assert serialized["unit"] == "volt"
    assert serialized["measured_at"] == "2026-09-24T14:05:00Z"


def test_measurement_input_json_round_trip() -> None:
    original = MeasurementInput.model_validate(
        {
            "id": "measurement-1",
            "session_id": "session-1",
            "kind": "current",
            "value": 2.5,
            "unit": "ampere",
            "measured_at": "2026-09-24T14:05:00+00:00",
        }
    )

    restored = MeasurementInput.model_validate_json(original.model_dump_json())

    assert restored == original
