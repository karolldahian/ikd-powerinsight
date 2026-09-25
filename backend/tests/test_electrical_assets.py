from powerinsight.domain.models import (
    ConductorRun,
    Nameplate,
    ProtectionDevice,
    ProtectionDeviceType,
)


def test_nameplate_belongs_to_equipment() -> None:
    nameplate = Nameplate(
        id="nameplate-1",
        equipment_id="equipment-1",
        manufacturer="Example Manufacturer",
        model="MODEL-100",
    )

    assert nameplate.equipment_id == "equipment-1"
    assert nameplate.manufacturer == "Example Manufacturer"
    assert nameplate.model == "MODEL-100"


def test_nameplate_can_preserve_raw_text() -> None:
    nameplate = Nameplate(
        id="nameplate-1",
        equipment_id="equipment-1",
        raw_text="Manufacturer plate text",
    )

    assert nameplate.raw_text == "Manufacturer plate text"


def test_protection_device_belongs_to_circuit() -> None:
    protection = ProtectionDevice(
        id="protection-1",
        circuit_id="circuit-1",
        device_type=ProtectionDeviceType.CIRCUIT_BREAKER,
    )

    assert protection.circuit_id == "circuit-1"
    assert protection.device_type is ProtectionDeviceType.CIRCUIT_BREAKER


def test_conductor_run_belongs_to_circuit() -> None:
    conductor_run = ConductorRun(
        id="conductor-run-1",
        circuit_id="circuit-1",
    )

    assert conductor_run.circuit_id == "circuit-1"
