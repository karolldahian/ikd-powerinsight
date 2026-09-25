import pytest

from powerinsight.domain.calculations import (
    active_input_power_from_motor_output,
    apparent_power_from_motor_output,
    current_from_motor_output,
)
from powerinsight.domain.models import ElectricalTopology
from powerinsight.domain.units import unit_registry


def test_active_input_power_from_motor_output() -> None:
    result = active_input_power_from_motor_output(
        output_power=unit_registry.Quantity(750, "watt"),
        efficiency=unit_registry.Quantity(0.75, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(1000)
    assert result.units == unit_registry.watt


def test_motor_output_power_accepts_compatible_units() -> None:
    result = active_input_power_from_motor_output(
        output_power=unit_registry.Quantity(1.5, "kilowatt"),
        efficiency=unit_registry.Quantity(0.75, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(2000)
    assert result.units == unit_registry.watt


def test_apparent_power_from_motor_output() -> None:
    result = apparent_power_from_motor_output(
        output_power=unit_registry.Quantity(750, "watt"),
        efficiency=unit_registry.Quantity(0.75, "dimensionless"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    assert result.magnitude == pytest.approx(1250)
    assert result.units == unit_registry.watt


def test_current_from_motor_output_single_phase() -> None:
    result = current_from_motor_output(
        output_power=unit_registry.Quantity(736, "watt"),
        efficiency=unit_registry.Quantity(0.8, "dimensionless"),
        power_factor=unit_registry.Quantity(0.8, "dimensionless"),
        voltage=unit_registry.Quantity(230, "volt"),
        topology=ElectricalTopology.SINGLE_PHASE_TWO_WIRE,
    )

    assert result.magnitude == pytest.approx(5)
    assert result.units == unit_registry.ampere


@pytest.mark.parametrize(
    "efficiency",
    [
        unit_registry.Quantity(0, "dimensionless"),
        unit_registry.Quantity(-0.1, "dimensionless"),
        unit_registry.Quantity(1.1, "dimensionless"),
    ],
)
def test_motor_efficiency_out_of_range_is_rejected(efficiency) -> None:
    with pytest.raises(ValueError, match="Efficiency"):
        active_input_power_from_motor_output(
            output_power=unit_registry.Quantity(750, "watt"),
            efficiency=efficiency,
        )


def test_motor_efficiency_with_wrong_dimension_is_rejected() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        active_input_power_from_motor_output(
            output_power=unit_registry.Quantity(750, "watt"),
            efficiency=unit_registry.Quantity(10, "ampere"),
        )


def test_motor_output_power_with_wrong_dimension_is_rejected() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        active_input_power_from_motor_output(
            output_power=unit_registry.Quantity(10, "ampere"),
            efficiency=unit_registry.Quantity(0.8, "dimensionless"),
        )
