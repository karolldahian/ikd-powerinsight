from hypothesis import given
from hypothesis import strategies as st

import powerinsight


def test_package_is_importable() -> None:
    assert powerinsight is not None


@given(value=st.integers())
def test_hypothesis_is_operational(value: int) -> None:
    assert value == value
