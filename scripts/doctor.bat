@echo off
REM Run Flutter doctor to check environment
cd /d "%~dp0.."
call flutter doctor -v
exit /b %errorlevel%
