param(
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"
$stage = "initializing"

function Test-Java17 {
    param([string]$JavaPath)

    if (-not (Test-Path -LiteralPath $JavaPath -PathType Leaf)) {
        return $false
    }

    $versionOutput = (& $JavaPath -version 2>&1 | Out-String)
    $versionMatch = [regex]::Match($versionOutput, 'version\s+"?(\d+)')

    return $versionMatch.Success -and $versionMatch.Groups[1].Value -eq "17"
}

try {
    $stage = "checking Windows local application data folder"
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw "LOCALAPPDATA is not defined in this Windows session."
    }

    $installRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $env:LOCALAPPDATA -ChildPath "PotatoCore"))
    $javaHome = Join-Path -Path $installRoot -ChildPath "jdk-17"
    $javaExe = Join-Path -Path $javaHome -ChildPath "bin\java.exe"

    $stage = "checking cached Java 17 installation"
    if (-not (Test-Java17 -JavaPath $javaExe)) {
        $downloadRoot = Join-Path -Path $installRoot -ChildPath "jdk-extract"
        $archivePath = Join-Path -Path $installRoot -ChildPath "temurin-17-windows-x64.zip"
        $downloadUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

        $stage = "creating local Java installation folder"
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

        if (Test-Path -LiteralPath $downloadRoot) {
            Remove-Item -LiteralPath $downloadRoot -Recurse -Force
        }
        if (Test-Path -LiteralPath $archivePath) {
            Remove-Item -LiteralPath $archivePath -Force
        }
        if (Test-Path -LiteralPath $javaHome) {
            Remove-Item -LiteralPath $javaHome -Recurse -Force
        }

        $stage = "downloading Eclipse Temurin JDK 17"
        Write-Host "[INFO] Downloading Eclipse Temurin JDK 17 from Adoptium..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

        $stage = "extracting Java 17 archive"
        Write-Host "[INFO] Extracting Java 17..."
        New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
        Expand-Archive -LiteralPath $archivePath -DestinationPath $downloadRoot -Force

        $stage = "locating the extracted JDK"
        $jdkFolder = Get-ChildItem -LiteralPath $downloadRoot -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath "bin\java.exe") -PathType Leaf
        } | Select-Object -First 1

        if (-not $jdkFolder) {
            throw "The downloaded archive did not contain a valid Windows JDK."
        }

        $stage = "installing Java 17 locally"
        Move-Item -LiteralPath $jdkFolder.FullName -Destination $javaHome
        Remove-Item -LiteralPath $downloadRoot -Recurse -Force
        Remove-Item -LiteralPath $archivePath -Force

        $stage = "verifying downloaded Java version"
        if (-not (Test-Java17 -JavaPath $javaExe)) {
            throw "The downloaded runtime did not report Java major version 17."
        }

        Write-Host "[INFO] Java 17 installed at: $javaHome"
    }
    else {
        Write-Host "[INFO] Reusing cached Java 17 at: $javaHome"
    }

    $stage = "writing Java 17 path for build installer"
    $fullOutputFile = [System.IO.Path]::GetFullPath($OutputFile)
    $outputDirectory = [System.IO.Path]::GetDirectoryName($fullOutputFile)
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($fullOutputFile, $javaHome, [System.Text.Encoding]::ASCII)

    Write-Host "[INFO] Java 17 is ready."
    exit 0
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Java 17 setup failed during: $stage" -ForegroundColor Red
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.TargetObject) {
        Write-Host "[ERROR] Target: $($_.TargetObject)" -ForegroundColor Red
    }
    exit 1
}
