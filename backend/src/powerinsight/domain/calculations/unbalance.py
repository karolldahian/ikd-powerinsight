from dataclasses import dataclass
from typing import cast

from pint import Quantity

from powerinsight.domain.calculations.load import PhaseLoadFact
from powerinsight.domain.models import Phase
from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


@dataclass(frozen=True, slots=True)
class LoadUnbalanceFact:
    average_phase_power: Quantity
    maximum_deviation: Quantity
    unbalance_percent: Quantity


def load_unbalance_fact(
    phase_loads: tuple[PhaseLoadFact, ...],
) -> LoadUnbalanceFact:
    expected_phases = {Phase.L1, Phase.L2, Phase.L3}
    received_phases = {load.phase for load in phase_loads}

    if len(phase_loads) != 3 or received_phases != expected_phases:
        raise ValueError(
            "Load unbalance requires exactly one load for each phase: L1, L2 and L3."
        )

    normalized_values = [
        _magnitude_as_float(
            normalize_quantity(
                load.demand_power,
                CanonicalUnit.POWER,
            )
        )
        for load in phase_loads
    ]

    average = sum(normalized_values) / 3

    if average == 0:
        maximum_deviation = 0.0
        unbalance = 0.0
    else:
        maximum_deviation = max(abs(value - average) for value in normalized_values)
        unbalance = maximum_deviation / average * 100

    return LoadUnbalanceFact(
        average_phase_power=unit_registry.Quantity(
            average,
            CanonicalUnit.POWER.value,
        ),
        maximum_deviation=unit_registry.Quantity(
            maximum_deviation,
            CanonicalUnit.POWER.value,
        ),
        unbalance_percent=unit_registry.Quantity(
            unbalance,
            "percent",
        ),
    )
