@echo off
setlocal
title StreakWok
cd /d "%~dp0"

echo ========================================================
echo   Launching StreakWok Mobile App Simulator
echo ========================================================

:: Check if port 8000 is already in use
netstat -ano | findstr :8000 >nul
if %errorLevel% neq 0 (
    echo Starting Python HTTP Server on port 8000...
    start /min python -m http.server 8000
    timeout /t 1 >nul
) else (
    echo Server on port 8000 is already running.
)

echo Opening StreakWok Dashboard in Chrome Mobile Window...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app="http://localhost:8000/dashboard_screen.html" --window-size=412,892 --window-position=480,30
exit
