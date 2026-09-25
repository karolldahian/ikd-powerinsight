from powerinsight.domain.models import Confidence, DataStatus, Provenance


def test_provenance_represents_data_origin() -> None:
    assert Provenance.OBSERVED.value == "observed"
    assert Provenance.DECLARED.value == "declared"
    assert Provenance.DOCUMENT.value == "document"
    assert Provenance.DERIVED.value == "derived"


def test_data_status_represents_data_availability() -> None:
    assert DataStatus.AVAILABLE.value == "available"
    assert DataStatus.MISSING.value == "missing"
    assert DataStatus.UNKNOWN.value == "unknown"
    assert DataStatus.NOT_APPLICABLE.value == "not_applicable"


def test_confidence_is_qualitative() -> None:
    assert Confidence.LOW.value == "low"
    assert Confidence.MEDIUM.value == "medium"
    assert Confidence.HIGH.value == "high"
