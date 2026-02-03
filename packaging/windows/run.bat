@echo off
setlocal
REM Start Advanced Tolltariff locally on Windows without admin
REM Uses per-user data dir in %LOCALAPPDATA%\AdvancedTolltariff

set PORT=8000
set HOST=127.0.0.1
set TOLLTARIFF_BOOTSTRAP=true
set TOLLTARIFF_DATA_DIR=%LOCALAPPDATA%\AdvancedTolltariff
set DATABASE_URL=sqlite:///%TOLLTARIFF_DATA_DIR%/data.db

REM Prefer Python from PATH; if using venv, activate here
REM call .venv\Scripts\activate

python -m uvicorn tolltariff.api.main:app --host %HOST% --port %PORT%

endlocal
