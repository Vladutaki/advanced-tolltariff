@echo off
setlocal
REM Build single executable using PyInstaller (run on Windows)

where pyinstaller >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Installing PyInstaller...
  pip install pyinstaller
)

pyinstaller --onefile --name advanced-tolltariff ^
  --add-data "frontend;frontend" ^
  --add-data "data\raw;data\raw" ^
  tolltariff\windows_main.py

if %ERRORLEVEL% EQU 0 (
  echo Built dist\advanced-tolltariff.exe
) else (
  echo Build failed.
)
endlocal
