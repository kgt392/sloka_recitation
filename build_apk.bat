@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Sloka Recitation - Build Release APK
echo ===================================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not found in your PATH.
    echo Please install Flutter from https://docs.flutter.dev/get-started/install
    echo or ensure flutter/bin is added to your environment variables.
    echo.
    pause
    exit /b 1
)

echo [1/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to fetch packages.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/3] Building release APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    exit /b %errorlevel%
)

echo.
echo [3/3] Copying APK to project root...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "sloka_recitation_release.apk" >nul
    echo.
    echo ===================================================
    echo  SUCCESS: APK generated successfully!
    echo  Location: %~dp0sloka_recitation_release.apk
    echo ===================================================
) else (
    echo [WARNING] APK built but not found at expected path.
)

pause
