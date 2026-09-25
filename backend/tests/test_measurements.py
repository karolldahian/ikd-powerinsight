from datetime import UTC, datetime

import pytest

from powerinsight.domain.models import (
    Measurement,
    MeasurementKind,
    MeasurementSession,
)


def test_measurement_session_belongs_to_site() -> None:
    started_at = datetime(2026, 9, 24, 14, 0, tzinfo=UTC)

    session = MeasurementSession(
        id="session-1",
        site_id="site-1",
        started_at=started_at,
    )

    assert session.site_id == "site-1"
    assert session.started_at == started_at
    assert session.ended_at is None


def test_measurement_belongs_to_session() -> None:
    measured_at = datetime(2026, 9, 24, 14, 5, tzinfo=UTC)

    measurement = Measurement(
        id="measurement-1",
        session_id="session-1",
        kind=MeasurementKind.CURRENT,
        measured_at=measured_at,
    )

    assert measurement.session_id == "session-1"
    assert measurement.kind is MeasurementKind.CURRENT
    assert measurement.measured_at == measured_at


def test_measurement_session_rejects_naive_started_at() -> None:
    with pytest.raises(ValueError, match="timezone"):
        MeasurementSession(
            id="session-1",
            site_id="site-1",
            started_at=datetime(2026, 9, 24, 14, 0),
        )


def test_measurement_rejects_naive_measured_at() -> None:
    with pytest.raises(ValueError, match="timezone"):
        Measurement(
            id="measurement-1",
            session_id="session-1",
            kind=MeasurementKind.VOLTAGE,
            measured_at=datetime(2026, 9, 24, 14, 5),
        )


def test_measurement_session_rejects_end_before_start() -> None:
    with pytest.raises(ValueError, match="earlier"):
        MeasurementSession(
            id="session-1",
            site_id="site-1",
            started_at=datetime(2026, 9, 24, 15, 0, tzinfo=UTC),
            ended_at=datetime(2026, 9, 24, 14, 0, tzinfo=UTC),
        )
