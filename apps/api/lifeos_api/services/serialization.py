"""Small serialization helpers for API responses."""

from datetime import date, datetime
from decimal import Decimal
from typing import Any


def jsonable(value: Any) -> Any:
    if isinstance(value, datetime | date):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, list):
        return [jsonable(item) for item in value]
    if isinstance(value, dict):
        return {key: jsonable(item) for key, item in value.items()}
    return value


def row_to_dict(row: Any, fields: list[str]) -> dict[str, Any]:
    return {field: jsonable(getattr(row, field)) for field in fields}
