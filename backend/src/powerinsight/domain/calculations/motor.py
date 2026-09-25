from typing import cast

from pint import Quantity

from powerinsight.domain.calculations.current import current_from_active_power
from powerinsight.domain.calculations.power import (
    apparent_power_from_active_and_power_factor,
)
from powerinsight.domain.models import ElectricalTopology
from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


def _efficiency_as_float(efficiency: Quantity) -> float:
    normalized = normalize_quantity(
        efficiency,
        CanonicalUnit.DIMENSIONLESS,
    )
    value = _magnitude_as_float(normalized)

    if not 0 < value <= 1:
        raise ValueError("Efficiency must be greater than 0 and at most 1.")

    return value


def active_input_power_from_motor_output(
    output_power: Quantity,
    efficiency: Quantity,
) -> Quantity:
    output = normalize_quantity(
        output_power,
        CanonicalUnit.POWER,
    )
    efficiency_value = _efficiency_as_float(efficiency)

    return unit_registry.Quantity(
        _magnitude_as_float(output) / efficiency_value,
        CanonicalUnit.POWER.value,
    )


def apparent_power_from_motor_output(
    output_power: Quantity,
    efficiency: Quantity,
    power_factor: Quantity,
) -> Quantity:
    active_input_power = active_input_power_from_motor_output(
        output_power,
        efficiency,
    )

    return apparent_power_from_active_and_power_factor(
        active_input_power,
        power_factor,
    )


def current_from_motor_output(
    output_power: Quantity,
    efficiency: Quantity,
    power_factor: Quantity,
    voltage: Quantity,
    topology: ElectricalTopology,
) -> Quantity:
    active_input_power = active_input_power_from_motor_output(
        output_power,
        efficiency,
    )

    return current_from_active_power(
        active_input_power,
        voltage,
        power_factor,
        topology,
    )
