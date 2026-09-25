from enum import StrEnum

from pint import Quantity, UnitRegistry
from pint.errors import DimensionalityError

unit_registry = UnitRegistry()


class CanonicalUnit(StrEnum):
    VOLTAGE = "volt"
    CURRENT = "ampere"
    POWER = "watt"
    FREQUENCY = "hertz"
    DIMENSIONLESS = "dimensionless"


def normalize_quantity(
    value: Quantity,
    unit: CanonicalUnit,
) -> Quantity:
    try:
        return value.to(unit.value)  # pyright: ignore[reportUnknownMemberType]
    except DimensionalityError as error:
        raise ValueError(
            f"Quantity is incompatible with canonical unit {unit.value}."
        ) from error
