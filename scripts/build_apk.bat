@echo off
REM Build ExerScroll APK - run from project root
cd /d "%~dp0.."
call flutter pub get
call flutter pub upgrade
call flutter build apk --release
if errorlevel 1 (
    echo Build failed. Run: flutter doctor -v
    pause
    exit /b 1
)
echo.
echo APK: build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0
