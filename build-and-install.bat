@echo off
setlocal
cd /d "%~dp0"

echo.
echo PotatoCore - Build and CurseForge Installer
echo -------------------------------------------
echo.

where java >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Java was not found in PATH.
    echo Install a Java 17 JDK and make sure JAVA_HOME or PATH is configured.
    pause
    exit /b 1
)

set "GRADLE_VERSION=8.1.1"
set "GRADLE_ROOT=%LOCALAPPDATA%\PotatoCore"
set "GRADLE_HOME=%GRADLE_ROOT%\gradle-%GRADLE_VERSION%"
set "GRADLE_EXE=%GRADLE_HOME%\bin\gradle.bat"

if exist "%GRADLE_EXE%" goto build

echo [INFO] Gradle %GRADLE_VERSION% is not installed locally.
echo [INFO] Downloading Gradle. This only needs to happen once.
echo.

if not exist "%GRADLE_ROOT%" mkdir "%GRADLE_ROOT%"
if errorlevel 1 (
    echo [ERROR] Could not create %GRADLE_ROOT%.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $version = '%GRADLE_VERSION%'; $root = '%GRADLE_ROOT%'; $zip = Join-Path $root ('gradle-' + $version + '-bin.zip'); $url = 'https://services.gradle.org/distributions/gradle-' + $version + '-bin.zip'; Write-Host '[INFO] Downloading from services.gradle.org...'; Invoke-WebRequest -Uri $url -OutFile $zip; Write-Host '[INFO] Extracting Gradle...'; Expand-Archive -LiteralPath $zip -DestinationPath $root -Force; Remove-Item -LiteralPath $zip -Force"
if errorlevel 1 (
    echo.
    echo [ERROR] Gradle download or extraction failed.
    echo Check your internet connection and try again.
    pause
    exit /b 1
)

if not exist "%GRADLE_EXE%" (
    echo [ERROR] Gradle installation could not be found after extraction.
    pause
    exit /b 1
)

:build
echo [INFO] Using Gradle %GRADLE_VERSION%.
echo [INFO] Building PotatoCore and installing to Project Infinity 0.1...
echo.

call "%GRADLE_EXE%" build installToCurseForge --no-daemon
if errorlevel 1 (
    echo.
    echo [ERROR] Build or CurseForge install failed.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] PotatoCore was built and copied to Project Infinity 0.1.
echo [INFO] Restart Minecraft if it is currently running.
pause
