@echo off
setlocal
cd /d "%~dp0"

echo.
echo PotatoCore - Build and CurseForge Installer
echo -------------------------------------------
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Git was not found in PATH. Install Git for Windows first.
    pause
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [ERROR] This folder is not a Git checkout.
    echo Clone https://github.com/wtffidy/PotatoCore first, then run this file.
    pause
    exit /b 1
)

for /f "delims=" %%B in ('git branch --show-current') do set "CURRENT_BRANCH=%%B"
if /i not "%CURRENT_BRANCH%"=="main" (
    echo [ERROR] This checkout is on branch "%CURRENT_BRANCH%", not main.
    echo Switch to main before running the build installer.
    pause
    exit /b 1
)

git diff --quiet
if errorlevel 1 (
    echo [ERROR] Local tracked changes detected. Commit or stash them before updating.
    pause
    exit /b 1
)
git diff --cached --quiet
if errorlevel 1 (
    echo [ERROR] Staged local changes detected. Commit or unstage them before updating.
    pause
    exit /b 1
)

echo [INFO] Pulling the latest PotatoCore from GitHub...
git pull --ff-only origin main
if errorlevel 1 (
    echo.
    echo [ERROR] Git pull failed. Check your connection and local repository state.
    pause
    exit /b 1
)
echo [INFO] Source is up to date.
echo.

echo [INFO] Locating a Java 17 runtime...
set "JAVA_HOME="
set "JAVA_RESULT=%TEMP%\PotatoCore-JavaHome.txt"
if exist "%JAVA_RESULT%" del "%JAVA_RESULT%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'SilentlyContinue'; $candidates = [System.Collections.Generic.List[string]]::new(); if ($env:JAVA_HOME) { $candidates.Add((Join-Path $env:JAVA_HOME 'bin\java.exe')) }; $cmd = Get-Command java.exe -ErrorAction SilentlyContinue; if ($cmd) { $candidates.Add($cmd.Source) }; foreach ($base in @((Join-Path $env:ProgramFiles 'Eclipse Adoptium'), (Join-Path $env:ProgramFiles 'Microsoft'), (Join-Path $env:ProgramFiles 'Java'), (Join-Path $env:LOCALAPPDATA 'Programs\Eclipse Adoptium'))) { Get-ChildItem -LiteralPath $base -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue | ForEach-Object { $candidates.Add((Join-Path $_.FullName 'bin\java.exe')) } }; $runtime = Join-Path $env:APPDATA '.minecraft\runtime\*\windows-x64\*\bin\java.exe'; Get-ChildItem -Path $runtime -File -ErrorAction SilentlyContinue | ForEach-Object { $candidates.Add($_.FullName) }; foreach ($java in ($candidates | Select-Object -Unique)) { if (Test-Path -LiteralPath $java) { $version = (& $java -version 2>&1 | Out-String); $match = [regex]::Match($version, '(?m)version\s+""?(\d+)'); if ($match.Success -and $match.Groups[1].Value -eq '17') { (Split-Path (Split-Path $java -Parent) -Parent) | Set-Content -LiteralPath '%JAVA_RESULT%' -NoNewline; exit 0 } } }; exit 1"
if errorlevel 1 (
    echo.
    echo [ERROR] A Java 17 runtime could not be found.
    echo Install a Java 17 JDK, or configure JAVA_HOME to point to it.
    pause
    exit /b 1
)

if not exist "%JAVA_RESULT%" (
    echo [ERROR] Java detection did not return a valid installation path.
    pause
    exit /b 1
)
set /p "JAVA_HOME="<"%JAVA_RESULT%"
del "%JAVA_RESULT%" >nul 2>nul
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo [ERROR] The detected Java installation is invalid: %JAVA_HOME%
    pause
    exit /b 1
)

if not defined JAVA_HOME (
    echo.
    echo [ERROR] A Java 17 runtime could not be found.
    echo Gradle 8.1.1 cannot run with Java 21.
    echo Install a Java 17 JDK, or configure JAVA_HOME to point to it.
    pause
    exit /b 1
)

set "PATH=%JAVA_HOME%\bin;%PATH%"
echo [INFO] Using Java 17: %JAVA_HOME%
java -version
echo.

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
