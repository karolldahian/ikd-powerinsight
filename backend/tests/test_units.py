import pytest
from pint.errors import DimensionalityError

from powerinsight.domain.units import CanonicalUnit, unit_registry


def test_voltage_can_be_converted_to_canonical_unit() -> None:
    voltage = unit_registry.Quantity(0.12, "kilovolt")

    canonical = voltage.to(CanonicalUnit.VOLTAGE)

    assert canonical.magnitude == pytest.approx(120)
    assert canonical.units == unit_registry.volt


def test_current_can_be_converted_to_canonical_unit() -> None:
    current = unit_registry.Quantity(2500, "milliampere")

    canonical = current.to(CanonicalUnit.CURRENT)

    assert canonical.magnitude == pytest.approx(2.5)
    assert canonical.units == unit_registry.ampere


def test_frequency_can_be_converted_to_canonical_unit() -> None:
    frequency = unit_registry.Quantity(0.06, "kilohertz")

    canonical = frequency.to(CanonicalUnit.FREQUENCY)

    assert canonical.magnitude == pytest.approx(60)
    assert canonical.units == unit_registry.hertz


def test_power_factor_is_dimensionless() -> None:
    power_factor = unit_registry.Quantity(0.95, CanonicalUnit.DIMENSIONLESS)

    assert power_factor.dimensionless
    assert power_factor.magnitude == pytest.approx(0.95)


def test_incompatible_dimensions_cannot_be_converted() -> None:
    current = unit_registry.Quantity(10, "ampere")

    with pytest.raises(DimensionalityError):
        current.to(CanonicalUnit.VOLTAGE)
