from dataclasses import dataclass
from enum import StrEnum


class Phase(StrEnum):
    L1 = "L1"
    L2 = "L2"
    L3 = "L3"


class ElectricalTopology(StrEnum):
    SINGLE_PHASE_TWO_WIRE = "single_phase_two_wire"
    SINGLE_PHASE_THREE_WIRE = "single_phase_three_wire"
    THREE_PHASE_THREE_WIRE = "three_phase_three_wire"
    THREE_PHASE_FOUR_WIRE = "three_phase_four_wire"


@dataclass(frozen=True, slots=True)
class PhaseAssignment:
    phases: tuple[Phase, ...]
    neutral: bool = False

    def __post_init__(self) -> None:
        if not self.phases:
            raise ValueError("At least one phase must be assigned.")

        if len(set(self.phases)) != len(self.phases):
            raise ValueError("Assigned phases must be unique.")
