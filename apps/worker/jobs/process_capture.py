"""Capture processing job placeholder."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ProcessCaptureJob:
    capture_id: str
