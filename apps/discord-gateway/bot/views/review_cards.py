"""Review card rendering contracts for Discord."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ReviewCardViewModel:
    review_id: str
    title: str
    body_md: str
    risk_level: str
    sensitivity: str
