@echo off
cd /d "%~dp0"
echo ============================================================
echo   OmniScribe Voice Server (Coqui XTTS v2)
echo ============================================================
echo.

REM Check if uv is installed
where uv >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Found uv package manager.
    if not exist ".venv" (
        echo [INFO] Creating local virtual environment for Python 3.10...
        uv venv --python 3.10
    )
    echo [INFO] Installing/updating dependencies...
    uv pip install -r requirements.txt
    echo.
    echo Starting server on http://localhost:5050 ...
    .venv\Scripts\python.exe server.py
    goto :end
)

REM Fallback if uv is not installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed on your system PATH and uv was not found.
    echo.
    echo To fix this, please run:
    echo   uv python install
    echo Or install Python 3.10 from https://www.python.org/
    echo.
    pause
    goto :eof
)

echo Installing dependencies...
pip install -r requirements.txt
echo.
echo Starting server on http://localhost:5050 ...
python server.py

:end
pause
