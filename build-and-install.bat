@echo off
setlocal
cd /d "%~dp0"
echo.
echo PotatoCore - Build and CurseForge Installer
echo -------------------------------------------
where gradle >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Gradle was not found in PATH. Install Gradle 8.1.1 and Java 17.
    pause
    exit /b 1
)
gradle build installToCurseForge --no-daemon
if errorlevel 1 (
    echo.
    echo [ERROR] Build or CurseForge install failed.
    pause
    exit /b 1
)
echo.
echo [SUCCESS] PotatoCore was built and copied to Project Infinity 0.1.
pause
