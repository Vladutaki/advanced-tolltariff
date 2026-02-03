import os
import uvicorn
from tolltariff.packaging_bootstrap import seed_packaged_data

# Safe defaults for Windows single-exe
os.environ.setdefault("HOST", "127.0.0.1")
os.environ.setdefault("PORT", "8000")
os.environ.setdefault("TOLLTARIFF_BOOTSTRAP", "true")

# Ensure bundled assets/raw data are copied to per-user data dir
seed_packaged_data()

if __name__ == "__main__":
    uvicorn.run("tolltariff.api.main:app", host=os.environ["HOST"], port=int(os.environ["PORT"]))
