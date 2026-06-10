@echo off
echo Starting local AI background services...
start "OmniScribe AI Server" /min cmd /c "cd voice_server && run_server.bat"
echo.
echo Running OmniScribe AI on Chrome...
flutter run -d chrome
pause
