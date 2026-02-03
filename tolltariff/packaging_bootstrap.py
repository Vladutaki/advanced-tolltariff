import sys
from pathlib import Path
import shutil
from .config import settings


def _meipass_dir() -> Path | None:
    base = getattr(sys, "_MEIPASS", None)
    if not base:
        return None
    return Path(base)


def seed_packaged_data() -> bool:
    """If running from a PyInstaller onefile exe, copy bundled frontend and raw data
    into the per-user data directory so the app can serve UI and import without network.
    """
    base = _meipass_dir()
    if not base:
        return False

    # Frontend
    src_frontend = base / "frontend"
    dst_frontend = settings.data_dir / "frontend"
    try:
        if src_frontend.exists():
            if not dst_frontend.exists():
                shutil.copytree(src_frontend, dst_frontend, dirs_exist_ok=True)
    except Exception:
        pass

    # Raw JSONs
    src_raw = base / "data" / "raw"
    dst_raw = settings.data_dir / "raw"
    try:
        if src_raw.exists():
            dst_raw.mkdir(parents=True, exist_ok=True)
            for p in src_raw.glob("*.json"):
                target = dst_raw / p.name
                if not target.exists():
                    shutil.copy2(p, target)
    except Exception:
        pass

    return True
