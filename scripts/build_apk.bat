@echo off
REM Build ExerScroll APK - run from project root
cd /d "%~dp0.."

REM Clean previous builds and artifacts
echo Cleaning previous builds...
call flutter clean

REM Delete previously generated APKs
if exist "build\app\outputs\apk\release\Exerscroll.apk" del "build\app\outputs\apk\release\Exerscroll.apk"
if exist "build\app\outputs\flutter-apk\app-release.apk" del "build\app\outputs\flutter-apk\app-release.apk"
if exist "build\app\outputs\flutter-apk\app-release.apk.sha1" del "build\app\outputs\flutter-apk\app-release.apk.sha1"
if exist "build\app\outputs\flutter-apk\Exerscroll.apk" del "build\app\outputs\flutter-apk\Exerscroll.apk"

REM Get dependencies
echo Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo Failed to get dependencies. Check internet connection.
    pause
    exit /b 1
)

REM Upgrade dependencies
echo Upgrading dependencies...
call flutter pub upgrade

REM Build APK
echo Building APK...
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
