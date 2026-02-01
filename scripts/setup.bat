@echo off
REM ExerScroll setup - run from project root
cd /d "%~dp0.."
echo Setting up ExerScroll...
if not exist "android\gradlew.bat" (
    echo Running flutter create to add Gradle wrapper...
    call flutter create .
)
call flutter pub get
if errorlevel 1 (
    echo Flutter not found. Add Flutter to PATH or run from a terminal where Flutter is available.
    pause
    exit /b 1
)
echo.
echo Setup complete. Run: flutter run
pause
exit /b 0
