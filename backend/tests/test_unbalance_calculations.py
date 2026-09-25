import pytest

from powerinsight.domain.calculations import (
    PhaseLoadFact,
    load_unbalance_fact,
)
from powerinsight.domain.models import Phase
from powerinsight.domain.units import unit_registry


def test_balanced_phase_loads_have_zero_unbalance() -> None:
    result = load_unbalance_fact(
        (
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L1,
                demand_power=unit_registry.Quantity(1000, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L2,
                demand_power=unit_registry.Quantity(1000, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L3,
                demand_power=unit_registry.Quantity(1000, "watt"),
            ),
        )
    )

    assert result.average_phase_power.magnitude == pytest.approx(1000)
    assert result.maximum_deviation.magnitude == pytest.approx(0)
    assert result.unbalance_percent.magnitude == pytest.approx(0)


def test_load_unbalance_uses_maximum_deviation_from_average() -> None:
    result = load_unbalance_fact(
        (
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L1,
                demand_power=unit_registry.Quantity(900, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L2,
                demand_power=unit_registry.Quantity(1000, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L3,
                demand_power=unit_registry.Quantity(1100, "watt"),
            ),
        )
    )

    assert result.average_phase_power.magnitude == pytest.approx(1000)
    assert result.maximum_deviation.magnitude == pytest.approx(100)
    assert result.unbalance_percent.magnitude == pytest.approx(10)


def test_load_unbalance_accepts_compatible_power_units() -> None:
    result = load_unbalance_fact(
        (
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L1,
                demand_power=unit_registry.Quantity(0.9, "kilowatt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L2,
                demand_power=unit_registry.Quantity(1000, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L3,
                demand_power=unit_registry.Quantity(1.1, "kilowatt"),
            ),
        )
    )

    assert result.average_phase_power.magnitude == pytest.approx(1000)
    assert result.maximum_deviation.magnitude == pytest.approx(100)
    assert result.unbalance_percent.magnitude == pytest.approx(10)


def test_three_zero_phase_loads_have_zero_unbalance() -> None:
    result = load_unbalance_fact(
        (
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L1,
                demand_power=unit_registry.Quantity(0, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L2,
                demand_power=unit_registry.Quantity(0, "watt"),
            ),
            PhaseLoadFact(
                panel_id="panel-1",
                phase=Phase.L3,
                demand_power=unit_registry.Quantity(0, "watt"),
            ),
        )
    )

    assert result.average_phase_power.magnitude == pytest.approx(0)
    assert result.maximum_deviation.magnitude == pytest.approx(0)
    assert result.unbalance_percent.magnitude == pytest.approx(0)


def test_load_unbalance_rejects_missing_phase() -> None:
    with pytest.raises(ValueError, match="exactly one load for each phase"):
        load_unbalance_fact(
            (
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L1,
                    demand_power=unit_registry.Quantity(1000, "watt"),
                ),
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L2,
                    demand_power=unit_registry.Quantity(1000, "watt"),
                ),
            )
        )


def test_load_unbalance_rejects_duplicate_phase() -> None:
    with pytest.raises(ValueError, match="exactly one load for each phase"):
        load_unbalance_fact(
            (
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L1,
                    demand_power=unit_registry.Quantity(1000, "watt"),
                ),
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L1,
                    demand_power=unit_registry.Quantity(900, "watt"),
                ),
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L3,
                    demand_power=unit_registry.Quantity(1100, "watt"),
                ),
            )
        )


def test_load_unbalance_rejects_wrong_dimension() -> None:
    with pytest.raises(ValueError, match="incompatible"):
        load_unbalance_fact(
            (
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L1,
                    demand_power=unit_registry.Quantity(10, "ampere"),
                ),
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L2,
                    demand_power=unit_registry.Quantity(1000, "watt"),
                ),
                PhaseLoadFact(
                    panel_id="panel-1",
                    phase=Phase.L3,
                    demand_power=unit_registry.Quantity(1000, "watt"),
                ),
            )
        )
