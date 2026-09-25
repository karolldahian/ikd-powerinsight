import pytest

from powerinsight.domain.models import Phase, PhaseAssignment


def test_phase_assignment_accepts_unique_phases() -> None:
    assignment = PhaseAssignment(
        phases=(Phase.L1, Phase.L2, Phase.L3),
        neutral=True,
    )

    assert assignment.phases == (Phase.L1, Phase.L2, Phase.L3)
    assert assignment.neutral is True


def test_phase_assignment_can_exist_without_neutral() -> None:
    assignment = PhaseAssignment(
        phases=(Phase.L1, Phase.L2),
        neutral=False,
    )

    assert assignment.phases == (Phase.L1, Phase.L2)
    assert assignment.neutral is False


def test_phase_assignment_rejects_empty_phases() -> None:
    with pytest.raises(ValueError, match="At least one phase"):
        PhaseAssignment(phases=())


def test_phase_assignment_rejects_duplicate_phases() -> None:
    with pytest.raises(ValueError, match="must be unique"):
        PhaseAssignment(phases=(Phase.L1, Phase.L1))
