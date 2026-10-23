"""Fixtures exercising every anti-slop-python evidence rule.

Each `# BAD:` block should be flagged; each `# GOOD:` block should pass.
Run the ast-grep lane against this file and confirm exactly the BAD markers
are reported (see tests/README.md).
"""
from typing import Any, cast

from myapp.models import User


# BAD: explicit Any with no SAFETY justification.
def process_any(data: Any) -> None:
    print(data)


# GOOD: concrete domain type.
def process_user(data: User) -> None:
    print(data)


def promote(raw: object) -> User:
    # SAFETY: parse_user validates the payload is a User before this cast.
    return cast(User, raw)


def promote_bad(raw: object) -> User:
    return cast(User, raw)  # BAD: cast with no SAFETY


def read_attr(obj: User) -> object:
    return getattr(obj, "name")  # BAD: string attribute access


def mock_bad() -> None:
    from unittest.mock import patch

    patch("myapp.service.fetch")  # BAD: module mocking


def ignore_bad(value: object) -> int:
    return value  # type: ignore  # BAD: blanket ignore


def ignore_good(value: object) -> int:
    return value  # type: ignore[return-value]  # SAFETY: upstream stub lies
