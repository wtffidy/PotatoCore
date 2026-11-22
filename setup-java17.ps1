param(
    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [string]$ExistingJavaHome = ""
)

$ErrorActionPreference = "Stop"

function Test-Java17 {
    param([string]$JavaPath)

    if (-not (Test-Path -LiteralPath $JavaPath -PathType Leaf)) {
        return $false
    }

    $versionOutput = (& $JavaPath -version 2>&1 | Out-String)
    $versionMatch = [regex]::Match($versionOutput, 'version\s+"?(\d+)')

    return $LASTEXITCODE -eq 0 -and $versionMatch.Success -and $versionMatch.Groups[1].Value -eq "17"
}

function Find-Java17 {
    param([string]$PreferredJavaHome)

    $candidates = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($PreferredJavaHome)) {
        $candidates.Add((Join-Path $PreferredJavaHome "bin\java.exe"))
    }

    $pathJava = Get-Command "java.exe" -ErrorAction SilentlyContinue
    if ($pathJava) {
        $candidates.Add($pathJava.Source)
    }

    $searchRoots = @(
        (Join-Path $env:ProgramFiles "Eclipse Adoptium"),
        (Join-Path $env:ProgramFiles "Microsoft"),
        (Join-Path $env:ProgramFiles "Java"),
        (Join-Path $env:LOCALAPPDATA "Programs\Eclipse Adoptium"),
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft")
    )

    foreach ($searchRoot in $searchRoots) {
        if (Test-Path -LiteralPath $searchRoot -PathType Container) {
            Get-ChildItem -LiteralPath $searchRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $candidates.Add((Join-Path $_.FullName "bin\java.exe"))
            }
        }
    }

    $minecraftRuntime = Join-Path $env:APPDATA ".minecraft\runtime\*\windows-x64\*\bin\java.exe"
    Get-ChildItem -Path $minecraftRuntime -File -ErrorAction SilentlyContinue | ForEach-Object {
        $candidates.Add($_.FullName)
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Java17 -JavaPath $candidate) {
            return (Split-Path (Split-Path $candidate -Parent) -Parent)
        }
    }

    return $null
}

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $javaHome = Find-Java17 -PreferredJavaHome $ExistingJavaHome

    if (-not $javaHome) {
        $installRoot = Join-Path $env:LOCALAPPDATA "PotatoCore"
        $javaHome = Join-Path $installRoot "jdk-17"
        $downloadRoot = Join-Path $installRoot "java17-download"
        $archivePath = Join-Path $installRoot "temurin-17-windows-x64.zip"
        $downloadUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

        if (Test-Path -LiteralPath $downloadRoot) {
            Remove-Item -LiteralPath $downloadRoot -Recurse -Force
        }

        if (Test-Path -LiteralPath $archivePath) {
            Remove-Item -LiteralPath $archivePath -Force
        }

        Write-Host "[INFO] Java 17 was not found. Downloading Eclipse Temurin JDK 17..."
        Write-Host "[INFO] Downloading from the official Adoptium API. This is a one-time setup."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

        Write-Host "[INFO] Extracting Java 17..."
        New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
        Expand-Archive -LiteralPath $archivePath -DestinationPath $downloadRoot -Force

        $jdkFolder = Get-ChildItem -LiteralPath $downloadRoot -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName "bin\java.exe") -PathType Leaf
        } | Select-Object -First 1

        if (-not $jdkFolder) {
            throw "The downloaded archive did not contain a valid JDK."
        }

        if (Test-Path -LiteralPath $javaHome) {
            Remove-Item -LiteralPath $javaHome -Recurse -Force
        }

        Move-Item -LiteralPath $jdkFolder.FullName -Destination $javaHome
        Remove-Item -LiteralPath $downloadRoot -Recurse -Force
        Remove-Item -LiteralPath $archivePath -Force

        if (-not (Test-Java17 -JavaPath (Join-Path $javaHome "bin\java.exe"))) {
            throw "The downloaded Java runtime failed its Java 17 version check."
        }

        Write-Host "[INFO] Java 17 installed locally at $javaHome"
    }
    else {
        Write-Host "[INFO] Found an existing Java 17 runtime at $javaHome"
    }

    $outputDirectory = Split-Path -Parent $OutputFile
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    Set-Content -LiteralPath $OutputFile -Value $javaHome -NoNewline -Encoding ASCII
    exit 0
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Java 17 setup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
