import pytest

from powerinsight.domain.calculations import (
    PhaseLoadContribution,
    circuit_load_fact,
    demand_fact,
    panel_load_fact,
    phase_load_fact,
)
from powerinsight.domain.models import Circuit, Panel, Phase
from powerinsight.domain.units import unit_registry


def test_circuit_load_fact_uses_demand_power() -> None:
    circuit = Circuit(
        id="circuit-1",
        panel_id="panel-1",
        name="Circuit 1",
    )
    demand = demand_fact(
        connected_power=unit_registry.Quantity(1000, "watt"),
        demand_factor=unit_registry.Quantity(0.8, "dimensionless"),
    )

    result = circuit_load_fact(circuit, demand)

    assert result.circuit_id == "circuit-1"
    assert result.panel_id == "panel-1"
    assert result.demand_power.magnitude == pytest.approx(800)
    assert result.demand_power.units == unit_registry.watt


def test_panel_load_fact_sums_circuit_loads() -> None:
    panel = Panel(
        id="panel-1",
        supply_id="supply-1",
        name="Main Panel",
    )

    circuit_1 = Circuit(
        id="circuit-1",
        panel_id="panel-1",
        name="Circuit 1",
    )
    circuit_2 = Circuit(
        id="circuit-2",
        panel_id="panel-1",
        name="Circuit 2",
    )

    load_1 = circuit_load_fact(
        circuit_1,
        demand_fact(
            connected_power=unit_registry.Quantity(1000, "watt"),
            demand_factor=unit_registry.Quantity(0.8, "dimensionless"),
        ),
    )
    load_2 = circuit_load_fact(
        circuit_2,
        demand_fact(
            connected_power=unit_registry.Quantity(500, "watt"),
            demand_factor=unit_registry.Quantity(0.6, "dimensionless"),
        ),
    )

    result = panel_load_fact(
        panel,
        (load_1, load_2),
    )

    assert result.panel_id == "panel-1"
    assert result.demand_power.magnitude == pytest.approx(1100)
    assert result.demand_power.units == unit_registry.watt


def test_panel_load_fact_rejects_circuit_from_other_panel() -> None:
    panel = Panel(
        id="panel-1",
        supply_id="supply-1",
        name="Main Panel",
    )
    other_circuit = Circuit(
        id="circuit-2",
        panel_id="panel-2",
        name="Other Circuit",
    )

    other_load = circuit_load_fact(
        other_circuit,
        demand_fact(
            connected_power=unit_registry.Quantity(500, "watt"),
            demand_factor=unit_registry.Quantity(1, "dimensionless"),
        ),
    )

    with pytest.raises(ValueError, match="requested panel"):
        panel_load_fact(
            panel,
            (other_load,),
        )


def test_phase_load_fact_sums_explicit_phase_contributions() -> None:
    panel = Panel(
        id="panel-1",
        supply_id="supply-1",
        name="Main Panel",
    )

    contribution_1 = PhaseLoadContribution(
        panel_id="panel-1",
        circuit_id="circuit-1",
        phase=Phase.L1,
        demand_power=unit_registry.Quantity(500, "watt"),
    )
    contribution_2 = PhaseLoadContribution(
        panel_id="panel-1",
        circuit_id="circuit-2",
        phase=Phase.L1,
        demand_power=unit_registry.Quantity(0.75, "kilowatt"),
    )

    result = phase_load_fact(
        panel,
        Phase.L1,
        (contribution_1, contribution_2),
    )

    assert result.panel_id == "panel-1"
    assert result.phase is Phase.L1
    assert result.demand_power.magnitude == pytest.approx(1250)
    assert result.demand_power.units == unit_registry.watt


def test_phase_load_fact_rejects_other_phase() -> None:
    panel = Panel(
        id="panel-1",
        supply_id="supply-1",
        name="Main Panel",
    )

    contribution = PhaseLoadContribution(
        panel_id="panel-1",
        circuit_id="circuit-1",
        phase=Phase.L2,
        demand_power=unit_registry.Quantity(500, "watt"),
    )

    with pytest.raises(ValueError, match="requested phase"):
        phase_load_fact(
            panel,
            Phase.L1,
            (contribution,),
        )


def test_phase_load_fact_rejects_other_panel() -> None:
    panel = Panel(
        id="panel-1",
        supply_id="supply-1",
        name="Main Panel",
    )

    contribution = PhaseLoadContribution(
        panel_id="panel-2",
        circuit_id="circuit-1",
        phase=Phase.L1,
        demand_power=unit_registry.Quantity(500, "watt"),
    )

    with pytest.raises(ValueError, match="requested panel"):
        phase_load_fact(
            panel,
            Phase.L1,
            (contribution,),
        )
