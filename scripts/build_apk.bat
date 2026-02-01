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
copy /Y "build\app\outputs\apk\release\Exerscroll.apk" "build\app\outputs\flutter-apk\Exerscroll.apk" >nul 2>&1
echo.
echo APK: build\app\outputs\flutter-apk\Exerscroll.apk
pause
exit /b 0
