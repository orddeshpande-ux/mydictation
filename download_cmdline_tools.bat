@echo off
set "SDK=C:\Users\or_de\AppData\Local\Android\sdk"
set "ZIP=%TEMP%\commandlinetools-win-9477386_latest.zip"
if exist "%SDK%\cmdline-tools" rmdir /s /q "%SDK%\cmdline-tools"
if exist "%ZIP%" del /f /q "%ZIP%"
curl -L -o "%ZIP%" "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%SDK%\cmdline-tools' -Force"
del /f /q "%ZIP%"
