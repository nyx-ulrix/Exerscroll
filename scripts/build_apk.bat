@echo off
REM Build ExerScroll APK - run from project root
cd /d "%~dp0.."

REM Delete previously generated APKs
if exist "build\app\outputs\apk\release\Exerscroll.apk" del "build\app\outputs\apk\release\Exerscroll.apk"
if exist "build\app\outputs\flutter-apk\app-release.apk" del "build\app\outputs\flutter-apk\app-release.apk"
if exist "build\app\outputs\flutter-apk\app-release.apk.sha1" del "build\app\outputs\flutter-apk\app-release.apk.sha1"
if exist "build\app\outputs\flutter-apk\Exerscroll.apk" del "build\app\outputs\flutter-apk\Exerscroll.apk"

call flutter pub get
call flutter pub upgrade
call flutter build apk --release
if errorlevel 1 (
    echo Build failed. Run: flutter doctor -v
    pause
    exit /b 1
)
copy /Y "build\app\outputs\apk\release\Exerscroll.apk" "build\app\outputs\flutter-apk\Exerscroll.apk"
echo.
echo APK: build\app\outputs\flutter-apk\Exerscroll.apk
pause
exit /b 0
