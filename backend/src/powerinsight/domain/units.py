from enum import StrEnum

from pint import UnitRegistry

unit_registry = UnitRegistry()


class CanonicalUnit(StrEnum):
    VOLTAGE = "volt"
    CURRENT = "ampere"
    POWER = "watt"
    FREQUENCY = "hertz"
    DIMENSIONLESS = "dimensionless"
