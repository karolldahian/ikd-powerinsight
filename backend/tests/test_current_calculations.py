from math import sqrt

import pytest

from powerinsight.domain.calculations import (
    current_from_active_power,
    current_from_apparent_power,
)
from powerinsight.domain.models import ElectricalTopology
from powerinsight.domain.units import unit_registry


def test_current_from_apparent_power_single_phase_two_wire() -> None:
    result = current_from_apparent_power(
        apparent_power=unit_registry.Quantity(2400, "watt"),
        voltage=unit_registry.Quantity(240, "volt"),
        topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
    )

    assert result.magnitude == pytest.approx(10)
    assert result.units == unit_registry.ampere


def test_current_from_apparent_power_single_phase_three_wire_total_system() -> None:
    result = current_from_apparent_power(
        apparent_power=unit_registry.Quantity(2400, "watt"),
        voltage=unit_registry.Quantity(240, "volt"),
        topology=ElectricalTopology.SINGLE_PHASE_THREE_WIRE,
    )

    assert result.magnitude == pytest.approx(10)
    assert result.units == unit_registry.ampere


@pytest.mark.parametrize(
    "topology",
    [
        ElectricalTopology.THREE_PHASE_THREE_WIRE,
        ElectricalTopology.THREE_PHASE_FOUR_WIRE,
    ],
)
def test_current_from_apparent_power_three_phase(
    topology: ElectricalTopology,
) -> None:
    result = current_from_apparent_power(
        apparent_power=unit_registry.Quantity(6000, "watt"),
        voltage=unit_registry.Quantity(400, "volt"),
        topology=topology,
    )

    expected = 6000 / (sqrt(3) * 400)

    assert result.magnitude == pytest.approx(expected)
    assert result.units == unit_registry.ampere


def test_current_from_active_power_uses_power_factor() -> None:
    result = current_from_active_power(
        active_power=unit_registry.Quantity(1840, "watt"),
        voltage=unit_registry.Quantity(230, "volt"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
        topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
    )

    assert result.magnitude == pytest.approx(10)
    assert result.units == unit_registry.ampere


@pytest.mark.parametrize(
    "voltage",
    [
        unit_registry.Quantity(0, "volt"),
        unit_registry.Quantity(-120, "volt"),
    ],
)
def test_current_rejects_non_positive_voltage(voltage) -> None:
    with pytest.raises(ValueError, match="greater than zero"):
        current_from_apparent_power(
            apparent_power=unit_registry.Quantity(1000, "watt"),
            voltage=voltage,
            topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
        )


def test_current_rejects_voltage_with_wrong_dimension() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        current_from_apparent_power(
            apparent_power=unit_registry.Quantity(1000, "watt"),
            voltage=unit_registry.Quantity(10, "ampere"),
            topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
        )


def test_current_rejects_power_with_wrong_dimension() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        current_from_apparent_power(
            apparent_power=unit_registry.Quantity(10, "ampere"),
            voltage=unit_registry.Quantity(230, "volt"),
            topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
        )
