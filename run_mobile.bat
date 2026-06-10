@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   OmniScribe AI Mobile Deployment
echo ============================================================
echo.

REM Start the server in the background
echo Starting local AI background services on this laptop...
start "OmniScribe AI Server" /min cmd /c "cd voice_server && run_server.bat"
echo.

REM 1. Check for Android SDK
set SDK_FOUND=0
if exist "%LOCALAPPDATA%\Android\Sdk" (
    set SDK_FOUND=1
    set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
) else if not "%ANDROID_HOME%"=="" (
    if exist "%ANDROID_HOME%" (
        set SDK_FOUND=1
        set SDK_PATH=%ANDROID_HOME%
    )
) else if not "%ANDROID_SDK_ROOT%"=="" (
    if exist "%ANDROID_SDK_ROOT%" (
        set SDK_FOUND=1
        set SDK_PATH=%ANDROID_SDK_ROOT%
    )
)

if %SDK_FOUND%==0 (
    echo [ERROR] Android SDK not found.
    echo.
    echo To deploy to an Android phone, Flutter needs the Android SDK.
    echo Since you have Android Studio installed, please follow these steps:
    echo.
    echo   1. Launch Android Studio from the Windows Start menu or run:
    echo      "C:\Program Files\Android\Android Studio\bin\studio64.exe"
    echo.
    echo   2. Run the Setup Wizard to download the Android SDK and Platform Tools.
    echo      (This will automatically install it to C:\Users\or_de\AppData\Local\Android\Sdk)
    echo.
    echo   3. Once the installation completes, run this script again.
    echo.
    echo Press any key to open Android Studio and exit...
    pause > nul
    start "" "C:\Program Files\Android\Android Studio\bin\studio64.exe"
    goto :eof
)

echo Android SDK detected at: %SDK_PATH%
echo.

REM 2. Check for connected mobile devices
echo Checking connected devices...
echo.

set TEMP_FILE=%TEMP%\flutter_devices.txt
flutter devices > "%TEMP_FILE%"
type "%TEMP_FILE%"
echo.

findstr /i "android" "%TEMP_FILE%" > nul
if %errorlevel% neq 0 (
    echo [WARNING] No connected Android devices or emulators were found.
    echo.
    echo Please make sure:
    echo   1. Your Android phone is connected to your laptop via USB.
    echo   2. "USB Debugging" is enabled in Settings -> Developer Options on your phone.
    echo      (To enable Developer Options, tap Settings -> About Phone -> "Build number" 7 times)
    echo   3. You have allowed USB debugging on your phone's screen prompt.
    echo   4. The phone's USB connection mode is set to "File Transfer" or "MTP" (not just Charging).
    echo.
    echo If you want to use an emulator, please start it from Android Studio first.
    echo.
    del "%TEMP_FILE%"
    pause
    goto :eof
)

del "%TEMP_FILE%"

REM 3. Deploy
echo.
echo Connected Android device detected!
echo.
echo What would you like to do?
echo   [1] Build and Sideload (Install permanent standalone app on phone) - RECOMMENDED
echo   [2] Run in Test Mode (Launch temporary app for editing/debugging)
echo.
set /p CHOICE="Enter choice (1 or 2, default is 1): "

if "%CHOICE%"=="" set CHOICE=1

if "%CHOICE%"=="1" (
    echo.
    echo Building permanent release application (APK)...
    call flutter build apk --release
    echo.
    echo Installing (sideloading) application onto your phone...
    "%SDK_PATH%\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
    if !errorlevel! equ 0 (
        echo.
        echo ============================================================
        echo   OmniScribe AI has been successfully installed on your phone!
        echo   You can find it on your home screen or app drawer.
        echo ============================================================
    ) else (
        echo [ERROR] Failed to install application. Ensure your phone screen is unlocked.
    )
) else (
    echo.
    echo Building and deploying in Test Mode...
    call flutter run -d android
)

REM 4. Sync files (audios, videos, voice profiles)
echo.
echo ============================================================
echo   Syncing generated audio/video files and voice profiles...
echo ============================================================
echo.

REM Create directories on phone
"%SDK_PATH%\platform-tools\adb.exe" shell mkdir -p /sdcard/Download/OmniScribe
"%SDK_PATH%\platform-tools\adb.exe" shell mkdir -p /sdcard/Download/OmniScribe/Profiles

if exist "voice_server\output" (
    echo Syncing generated MP3/MP4 files to phone...
    "%SDK_PATH%\platform-tools\adb.exe" push voice_server\output\. /sdcard/Download/OmniScribe/
)
if exist "voice_server\voices" (
    echo Syncing voice profiles metadata to phone...
    "%SDK_PATH%\platform-tools\adb.exe" push voice_server\voices\. /sdcard/Download/OmniScribe/Profiles/
)

echo.
echo ============================================================
echo   Sync complete! You can find your files on your phone under:
echo   Files -> Downloads -> OmniScribe
echo ============================================================
echo.

pause
