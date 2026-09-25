from math import sqrt
from typing import cast

from pint import Quantity

from powerinsight.domain.units import CanonicalUnit, normalize_quantity, unit_registry


def _magnitude_as_float(value: Quantity) -> float:
    return float(cast(float, value.magnitude))


def _power_factor_as_float(power_factor: Quantity) -> float:
    normalized = normalize_quantity(
        power_factor,
        CanonicalUnit.DIMENSIONLESS,
    )
    value = _magnitude_as_float(normalized)

    if not 0 <= value <= 1:
        raise ValueError("Power factor must be between 0 and 1.")

    return value


def active_power_from_apparent_and_power_factor(
    apparent_power: Quantity,
    power_factor: Quantity,
) -> Quantity:
    apparent = normalize_quantity(
        apparent_power,
        CanonicalUnit.POWER,
    )
    factor = _power_factor_as_float(power_factor)

    return unit_registry.Quantity(
        _magnitude_as_float(apparent) * factor,
        CanonicalUnit.POWER.value,
    )


def apparent_power_from_active_and_power_factor(
    active_power: Quantity,
    power_factor: Quantity,
) -> Quantity:
    active = normalize_quantity(
        active_power,
        CanonicalUnit.POWER,
    )
    factor = _power_factor_as_float(power_factor)

    if factor == 0:
        raise ValueError(
            "Power factor must be greater than zero to calculate apparent power."
        )

    return unit_registry.Quantity(
        _magnitude_as_float(active) / factor,
        CanonicalUnit.POWER.value,
    )


def reactive_power_magnitude_from_active_and_apparent(
    active_power: Quantity,
    apparent_power: Quantity,
) -> Quantity:
    active = normalize_quantity(
        active_power,
        CanonicalUnit.POWER,
    )
    apparent = normalize_quantity(
        apparent_power,
        CanonicalUnit.POWER,
    )

    active_value = _magnitude_as_float(active)
    apparent_value = _magnitude_as_float(apparent)

    if apparent_value < abs(active_value):
        raise ValueError(
            "Apparent power magnitude cannot be lower than active power magnitude."
        )

    reactive_magnitude = sqrt(apparent_value**2 - active_value**2)

    return unit_registry.Quantity(
        reactive_magnitude,
        CanonicalUnit.POWER.value,
    )
