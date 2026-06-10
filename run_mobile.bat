@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   OmniScribe AI Mobile Deployment
echo ============================================================
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
echo Building and deploying to your mobile device...
echo.
flutter run -d android
pause
