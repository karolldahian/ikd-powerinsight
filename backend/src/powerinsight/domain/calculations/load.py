from dataclasses import dataclass
from typing import cast

from pint import Quantity

from powerinsight.domain.calculations.demand import DemandFact
from powerinsight.domain.models import Circuit, Panel, Phase
from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


@dataclass(frozen=True, slots=True)
class CircuitLoadFact:
    circuit_id: str
    panel_id: str
    demand_power: Quantity


@dataclass(frozen=True, slots=True)
class PanelLoadFact:
    panel_id: str
    demand_power: Quantity


@dataclass(frozen=True, slots=True)
class PhaseLoadContribution:
    panel_id: str
    circuit_id: str
    phase: Phase
    demand_power: Quantity


@dataclass(frozen=True, slots=True)
class PhaseLoadFact:
    panel_id: str
    phase: Phase
    demand_power: Quantity


def circuit_load_fact(
    circuit: Circuit,
    demand: DemandFact,
) -> CircuitLoadFact:
    return CircuitLoadFact(
        circuit_id=circuit.id,
        panel_id=circuit.panel_id,
        demand_power=normalize_quantity(
            demand.demand_power,
            CanonicalUnit.POWER,
        ),
    )


def panel_load_fact(
    panel: Panel,
    circuit_loads: tuple[CircuitLoadFact, ...],
) -> PanelLoadFact:
    total = 0.0

    for load in circuit_loads:
        if load.panel_id != panel.id:
            raise ValueError("All circuit loads must belong to the requested panel.")

        normalized = normalize_quantity(
            load.demand_power,
            CanonicalUnit.POWER,
        )
        total += _magnitude_as_float(normalized)

    return PanelLoadFact(
        panel_id=panel.id,
        demand_power=unit_registry.Quantity(
            total,
            CanonicalUnit.POWER.value,
        ),
    )


def phase_load_fact(
    panel: Panel,
    phase: Phase,
    contributions: tuple[PhaseLoadContribution, ...],
) -> PhaseLoadFact:
    total = 0.0

    for contribution in contributions:
        if contribution.panel_id != panel.id:
            raise ValueError(
                "All phase contributions must belong to the requested panel."
            )

        if contribution.phase is not phase:
            raise ValueError("All phase contributions must match the requested phase.")

        normalized = normalize_quantity(
            contribution.demand_power,
            CanonicalUnit.POWER,
        )
        total += _magnitude_as_float(normalized)

    return PhaseLoadFact(
        panel_id=panel.id,
        phase=phase,
        demand_power=unit_registry.Quantity(
            total,
            CanonicalUnit.POWER.value,
        ),
    )
