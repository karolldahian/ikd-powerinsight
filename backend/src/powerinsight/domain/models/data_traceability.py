from enum import StrEnum


class Provenance(StrEnum):
    OBSERVED = "observed"
    DECLARED = "declared"
    DOCUMENT = "document"
    DERIVED = "derived"


class DataStatus(StrEnum):
    AVAILABLE = "available"
    MISSING = "missing"
    UNKNOWN = "unknown"
    NOT_APPLICABLE = "not_applicable"


class Confidence(StrEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
