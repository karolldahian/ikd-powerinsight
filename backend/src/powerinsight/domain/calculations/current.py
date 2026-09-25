from math import sqrt
from typing import cast

from pint import Quantity

from powerinsight.domain.calculations.power import (
    apparent_power_from_active_and_power_factor,
)
from powerinsight.domain.models import ElectricalTopology
from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


def _require_positive_voltage(voltage: Quantity) -> float:
    normalized = normalize_quantity(
        voltage,
        CanonicalUnit.VOLTAGE,
    )
    value = _magnitude_as_float(normalized)

    if value <= 0:
        raise ValueError("Voltage must be greater than zero.")

    return value


def current_from_apparent_power(
    apparent_power: Quantity,
    voltage: Quantity,
    topology: ElectricalTopology,
) -> Quantity:
    apparent = normalize_quantity(
        apparent_power,
        CanonicalUnit.POWER,
    )
    voltage_value = _require_positive_voltage(voltage)
    apparent_value = _magnitude_as_float(apparent)

    if topology in {
        ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
        ElectricalTopology.SINGLE_PHASE_THREE_WIRE,
    }:
        current_value = apparent_value / voltage_value
    else:
        current_value = apparent_value / (sqrt(3) * voltage_value)

    return unit_registry.Quantity(
        current_value,
        CanonicalUnit.CURRENT.value,
    )


def current_from_active_power(
    active_power: Quantity,
    voltage: Quantity,
    power_factor: Quantity,
    topology: ElectricalTopology,
) -> Quantity:
    apparent_power = apparent_power_from_active_and_power_factor(
        active_power,
        power_factor,
    )

    return current_from_apparent_power(
        apparent_power,
        voltage,
        topology,
    )
