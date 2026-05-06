# ADR 0001: Review Before Truth

Status: accepted

LifeOS stores raw capture as evidence, not truth. AI interpretation can propose review items, memory candidates, tasks, and finance entries, but important durable changes must go through Approval Manager policy and the command bus.

This prevents messy capture and model inference from silently rewriting the user's life state.
