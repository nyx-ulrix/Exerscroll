@echo off
REM Run ExerScroll on connected device/emulator
cd /d "%~dp0.."
call flutter pub get
call flutter run
pause
exit /b %errorlevel%
