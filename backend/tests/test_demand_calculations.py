import pytest

from powerinsight.domain.calculations import DemandFact, demand_fact
from powerinsight.domain.units import unit_registry


def test_demand_fact_calculates_demand_power() -> None:
    result = demand_fact(
        connected_power=unit_registry.Quantity(1000, "watt"),
        demand_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    assert isinstance(result, DemandFact)
    assert result.connected_power.magnitude == pytest.approx(1000)
    assert result.demand_factor.magnitude == pytest.approx(0.8)
    assert result.demand_power.magnitude == pytest.approx(800)
    assert result.demand_power.units == unit_registry.watt


def test_demand_fact_normalizes_connected_power() -> None:
    result = demand_fact(
        connected_power=unit_registry.Quantity(1.5, "kilowatt"),
        demand_factor=unit_registry.Quantity(0.5, "dimensionless"),
    )

    assert result.connected_power.magnitude == pytest.approx(1500)
    assert result.connected_power.units == unit_registry.watt
    assert result.demand_power.magnitude == pytest.approx(750)


def test_demand_fact_accepts_percentage_factor() -> None:
    result = demand_fact(
        connected_power=unit_registry.Quantity(1000, "watt"),
        demand_factor=unit_registry.Quantity(50, "percent"),
    )

    assert result.demand_factor.magnitude == pytest.approx(0.5)
    assert result.demand_power.magnitude == pytest.approx(500)


@pytest.mark.parametrize(
    ("factor", "expected"),
    [
        (0, 0),
        (1, 1000),
    ],
)
def test_demand_factor_accepts_boundary_values(
    factor: float,
    expected: float,
) -> None:
    result = demand_fact(
        connected_power=unit_registry.Quantity(1000, "watt"),
        demand_factor=unit_registry.Quantity(factor, "dimensionless"),
    )

    assert result.demand_power.magnitude == pytest.approx(expected)


@pytest.mark.parametrize(
    "factor",
    [-0.1, 1.1],
)
def test_demand_factor_out_of_range_is_rejected(factor: float) -> None:
    with pytest.raises(ValueError, match="between 0 and 1"):
        demand_fact(
            connected_power=unit_registry.Quantity(1000, "watt"),
            demand_factor=unit_registry.Quantity(factor, "dimensionless"),
        )


def test_demand_factor_with_wrong_dimension_is_rejected() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        demand_fact(
            connected_power=unit_registry.Quantity(1000, "watt"),
            demand_factor=unit_registry.Quantity(10, "ampere"),
        )


def test_connected_power_with_wrong_dimension_is_rejected() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        demand_fact(
            connected_power=unit_registry.Quantity(10, "ampere"),
            demand_factor=unit_registry.Quantity(0.8, "dimensionless"),
        )
