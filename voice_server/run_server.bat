@echo off
echo ============================================================
echo   OmniScribe Voice Server (Coqui XTTS v2)
echo ============================================================
echo.
echo Prerequisites:
echo   - Python 3.10+ installed
echo   - FFmpeg installed and on PATH
echo   - GPU recommended (NVIDIA with CUDA)
echo.
echo Installing dependencies...
pip install -r requirements.txt
echo.
echo Starting server on http://localhost:5050 ...
echo.
python server.py
pause
