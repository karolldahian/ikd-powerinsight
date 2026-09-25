from datetime import datetime

from pydantic import BaseModel, ConfigDict

from powerinsight.domain.models import Measurement, MeasurementKind
from powerinsight.domain.units import unit_registry


class MeasurementInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    session_id: str
    kind: MeasurementKind
    value: float
    unit: str
    measured_at: datetime

    def to_domain(self) -> Measurement:
        return Measurement(
            id=self.id,
            session_id=self.session_id,
            kind=self.kind,
            value=unit_registry.Quantity(self.value, self.unit),
            measured_at=self.measured_at,
        )
