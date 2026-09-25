from dataclasses import dataclass
from typing import cast

from pint import Quantity

from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


def _demand_factor_as_float(demand_factor: Quantity) -> float:
    normalized = normalize_quantity(
        demand_factor,
        CanonicalUnit.DIMENSIONLESS,
    )
    value = _magnitude_as_float(normalized)

    if not 0 <= value <= 1:
        raise ValueError("Demand factor must be between 0 and 1.")

    return value


@dataclass(frozen=True, slots=True)
class DemandFact:
    connected_power: Quantity
    demand_factor: Quantity
    demand_power: Quantity


def demand_fact(
    connected_power: Quantity,
    demand_factor: Quantity,
) -> DemandFact:
    connected = normalize_quantity(
        connected_power,
        CanonicalUnit.POWER,
    )
    factor = _demand_factor_as_float(demand_factor)

    demand = unit_registry.Quantity(
        _magnitude_as_float(connected) * factor,
        CanonicalUnit.POWER.value,
    )

    return DemandFact(
        connected_power=connected,
        demand_factor=unit_registry.Quantity(
            factor,
            CanonicalUnit.DIMENSIONLESS.value,
        ),
        demand_power=demand,
    )
