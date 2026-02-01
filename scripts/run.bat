@echo off
REM Run ExerScroll on connected device/emulator
call flutter pub get
call flutter run
exit /b %errorlevel%
