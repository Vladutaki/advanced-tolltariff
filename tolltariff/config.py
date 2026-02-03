import os
from typing import Optional

class Settings:
    database_url: str
    base_url: Optional[str]

    def __init__(self) -> None:
        self.database_url = os.getenv("DATABASE_URL", "sqlite:///data.db")
        self.base_url = os.getenv("TOLLTARIFF_BASE_URL")

settings = Settings()
