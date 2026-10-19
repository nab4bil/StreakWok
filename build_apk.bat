@echo off
setlocal
title StreakWok - Build Android APK
echo ========================================================
echo   Building StreakWok Android APK (Debug)
echo ========================================================

set "JAVA_HOME=%~dp0..\jdk-17\jdk-17.0.12+7"
set "PATH=%JAVA_HOME%\bin;%PATH%"

cd /d "%~dp0android"

echo Syncing latest web assets to Android assets...
copy /y "%~dp0*.html" "%~dp0android\app\src\main\assets\" >nul
copy /y "%~dp0*.json" "%~dp0android\app\src\main\assets\" >nul
copy /y "%~dp0*.js" "%~dp0android\app\src\main\assets\" >nul
copy /y "%~dp0*.png" "%~dp0android\app\src\main\assets\" >nul

echo Compiling via Gradle...
call gradlew.bat assembleDebug

if exist "app\build\outputs\apk\debug\app-debug.apk" (
    copy /y "app\build\outputs\apk\debug\app-debug.apk" "%~dp0StreakWok.apk" >nul
    copy /y "app\build\outputs\apk\debug\app-debug.apk" "%USERPROFILE%\Desktop\StreakWok.apk" >nul
    echo.
    echo ========================================================
    echo   [SUCCESS] APK built successfully!
    echo   Output 1: %~dp0StreakWok.apk
    echo   Output 2: %USERPROFILE%\Desktop\StreakWok.apk
    echo ========================================================
) else (
    echo.
    echo [ERROR] Build failed. Please check Gradle output above.
)

pause
