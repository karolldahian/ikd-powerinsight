import pytest

from powerinsight.domain.calculations import (
    active_power_from_apparent_and_power_factor,
    apparent_power_from_active_and_power_factor,
    reactive_power_magnitude_from_active_and_apparent,
)
from powerinsight.domain.units import unit_registry


def test_active_power_from_apparent_power_and_power_factor() -> None:
    result = active_power_from_apparent_and_power_factor(
        apparent_power=unit_registry.Quantity(1000, "watt"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(800)
    assert result.units == unit_registry.watt


def test_apparent_power_from_active_power_and_power_factor() -> None:
    result = apparent_power_from_active_and_power_factor(
        active_power=unit_registry.Quantity(800, "watt"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(1000)
    assert result.units == unit_registry.watt


def test_reactive_power_magnitude_from_active_and_apparent() -> None:
    result = reactive_power_magnitude_from_active_and_apparent(
        active_power=unit_registry.Quantity(800, "watt"),
        apparent_power=unit_registry.Quantity(1000, "watt"),
    )

    assert result.magnitude == pytest.approx(600)
    assert result.units == unit_registry.watt


def test_power_functions_accept_compatible_power_units() -> None:
    result = active_power_from_apparent_and_power_factor(
        apparent_power=unit_registry.Quantity(1.5, "kilowatt"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(1200)
    assert result.units == unit_registry.watt


def test_power_factor_above_one_is_rejected() -> None:
    with pytest.raises(ValueError, match="between 0 and 1"):
        active_power_from_apparent_and_power_factor(
            apparent_power=unit_registry.Quantity(1000, "watt"),
            power_factor=unit_registry.Quantity(1.1, "dimensionless"),
        )


def test_power_factor_with_wrong_dimension_is_rejected() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        active_power_from_apparent_and_power_factor(
            apparent_power=unit_registry.Quantity(1000, "watt"),
            power_factor=unit_registry.Quantity(10, "ampere"),
        )


def test_zero_power_factor_cannot_calculate_apparent_power() -> None:
    with pytest.raises(ValueError, match="greater than zero"):
        apparent_power_from_active_and_power_factor(
            active_power=unit_registry.Quantity(800, "watt"),
            power_factor=unit_registry.Quantity(0, "dimensionless"),
        )


def test_apparent_power_cannot_be_lower_than_active_power_magnitude() -> None:
    with pytest.raises(ValueError, match="cannot be lower"):
        reactive_power_magnitude_from_active_and_apparent(
            active_power=unit_registry.Quantity(1000, "watt"),
            apparent_power=unit_registry.Quantity(800, "watt"),
        )
