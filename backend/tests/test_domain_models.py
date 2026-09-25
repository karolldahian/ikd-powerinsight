from powerinsight.domain.models import (
    Circuit,
    Equipment,
    Organization,
    Panel,
    Site,
    Supply,
)


def test_domain_entities_can_be_created() -> None:
    organization = Organization(id="org-1", name="IKD Foods")
    site = Site(id="site-1", organization_id=organization.id, name="Sede Cali")
    supply = Supply(id="supply-1", site_id=site.id, name="Acometida principal")
    panel = Panel(id="panel-1", supply_id=supply.id, name="Tablero general")
    circuit = Circuit(id="circuit-1", panel_id=panel.id, name="Cocina")
    equipment = Equipment(
        id="equipment-1",
        site_id=site.id,
        circuit_id=circuit.id,
        name="Horno",
    )

    assert site.organization_id == organization.id
    assert supply.site_id == site.id
    assert panel.supply_id == supply.id
    assert circuit.panel_id == panel.id
    assert equipment.circuit_id == circuit.id


def test_equipment_can_exist_without_confirmed_circuit() -> None:
    equipment = Equipment(
        id="equipment-1",
        site_id="site-1",
        name="Nevera",
    )

    assert equipment.circuit_id is None
