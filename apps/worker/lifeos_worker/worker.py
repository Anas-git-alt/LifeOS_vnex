"""Async worker entrypoint placeholder."""

from __future__ import annotations

import os
import time


def main() -> None:
    api_url = os.getenv("LIFEOS_API_BASE_URL", "http://api:8000")
    print(f"lifeos-worker ready; API={api_url}", flush=True)
    while True:
        time.sleep(60)


if __name__ == "__main__":
    main()
