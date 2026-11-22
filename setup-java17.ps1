param(
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"
$stage = "initializing"

function Get-JavaMajorVersion {
    param([string]$JavaPath)

    if (-not (Test-Path -LiteralPath $JavaPath -PathType Leaf)) {
        return $null
    }

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $versionOutput = (& $JavaPath -version 2>&1 | Out-String)
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    $match = [regex]::Match($versionOutput, 'version\s+"?(\d+)')
    if (-not $match.Success) {
        return $null
    }

    return [int]$match.Groups[1].Value
}

function Test-Jdk17 {
    param([string]$JavaHome)

    $javaExe = Join-Path -Path $JavaHome -ChildPath "bin\java.exe"
    $javacExe = Join-Path -Path $JavaHome -ChildPath "bin\javac.exe"

    return (Test-Path -LiteralPath $javacExe -PathType Leaf) -and ((Get-JavaMajorVersion -JavaPath $javaExe) -eq 17)
}

try {
    $stage = "locating an existing Java 17 JDK"

    $searchRoots = @(
        (Join-Path -Path $env:ProgramFiles -ChildPath "Eclipse Adoptium"),
        (Join-Path -Path $env:ProgramFiles -ChildPath "Java"),
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs\Eclipse Adoptium"),
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs\Java")
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container)
    }

    $javaHome = $null
    foreach ($root in $searchRoots) {
        Write-Host "[INFO] Checking for a JDK in: $root"
        $javaCandidates = Get-ChildItem -LiteralPath $root -Filter "javac.exe" -File -Recurse -ErrorAction SilentlyContinue

        foreach ($candidate in $javaCandidates) {
            $candidateHome = Split-Path -Path (Split-Path -Path $candidate.FullName -Parent) -Parent
            if (Test-Jdk17 -JavaHome $candidateHome) {
                $javaHome = $candidateHome
                break
            }
        }

        if ($javaHome) {
            break
        }
    }

    if ($javaHome) {
        Write-Host "[INFO] Reusing existing Java 17 JDK: $javaHome"
    }
    else {
        $stage = "preparing a local Java 17 JDK installation"

        if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
            throw "LOCALAPPDATA is not defined in this Windows session."
        }

        $installRoot = Join-Path -Path $env:LOCALAPPDATA -ChildPath "PotatoCore"
        $javaHome = Join-Path -Path $installRoot -ChildPath "jdk-17"
        $stagingRoot = Join-Path -Path $env:TEMP -ChildPath "PotatoCore-JDK17-Install"
        $archivePath = Join-Path -Path $stagingRoot -ChildPath "temurin-17-windows-x64.zip"
        $downloadUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        if (Test-Path -LiteralPath $stagingRoot) {
            Remove-Item -LiteralPath $stagingRoot -Recurse -Force
        }
        New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

        $stage = "downloading Eclipse Temurin JDK 17"
        Write-Host "[INFO] CurseForge's Java 17 is a runtime without javac."
        Write-Host "[INFO] Downloading a build-only JDK 17 from Adoptium..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

        $stage = "extracting Java 17 JDK"
        Write-Host "[INFO] Extracting JDK 17..."
        Expand-Archive -LiteralPath $archivePath -DestinationPath $stagingRoot -Force

        $stage = "locating the extracted Java compiler"
        $jdkFolder = Get-ChildItem -LiteralPath $stagingRoot -Directory | Where-Object {
            (Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath "bin\java.exe") -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath "bin\javac.exe") -PathType Leaf)
        } | Select-Object -First 1

        if (-not $jdkFolder) {
            throw "The downloaded archive did not contain a valid JDK with java.exe and javac.exe."
        }

        $stage = "installing the local Java 17 JDK"
        if (Test-Path -LiteralPath $javaHome) {
            Remove-Item -LiteralPath $javaHome -Recurse -Force
        }
        Move-Item -LiteralPath $jdkFolder.FullName -Destination $javaHome
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force

        $stage = "verifying Java 17 compiler installation"
        if (-not (Test-Jdk17 -JavaHome $javaHome)) {
            throw "The installed JDK did not report Java major version 17 or javac.exe was missing."
        }

        Write-Host "[INFO] Build JDK installed at: $javaHome"
    }

    $stage = "writing Java 17 JDK path for build installer"
    $fullOutputFile = [System.IO.Path]::GetFullPath($OutputFile)
    $outputDirectory = [System.IO.Path]::GetDirectoryName($fullOutputFile)
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($fullOutputFile, $javaHome, [System.Text.Encoding]::ASCII)
    Write-Host "[INFO] Java 17 JDK is ready (java.exe + javac.exe)."
    exit 0
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Java 17 JDK setup failed during: $stage" -ForegroundColor Red
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.TargetObject) {
        Write-Host "[ERROR] Target: $($_.TargetObject)" -ForegroundColor Red
    }
    exit 1
}
