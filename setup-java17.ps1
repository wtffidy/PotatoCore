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

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $versionOutput = (& $JavaPath -version 2>&1 | Out-String)
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $versionMatch = [regex]::Match($versionOutput, 'version\s+"?(\d+)')
    if (-not $versionMatch.Success) {
        return $null
    }

    return [int]$versionMatch.Groups[1].Value
}

try {
    $stage = "locating the active CurseForge Minecraft installation"

    $searchRoots = @(
        (Join-Path -Path $env:USERPROFILE -ChildPath "curseforge\minecraft\Install\java"),
        (Join-Path -Path $env:APPDATA -ChildPath ".minecraft\runtime"),
        (Join-Path -Path $env:APPDATA -ChildPath "CurseForge\Minecraft\Install\java"),
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath "CurseForge\Minecraft\Install\java")
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container)
    }

    $java17Path = $null
    foreach ($root in $searchRoots) {
        Write-Host "[INFO] Checking CurseForge runtime folder: $root"

        $javaCandidates = Get-ChildItem -LiteralPath $root -Filter "java.exe" -File -Recurse -ErrorAction SilentlyContinue
        foreach ($candidate in $javaCandidates) {
            $majorVersion = Get-JavaMajorVersion -JavaPath $candidate.FullName
            if ($majorVersion -eq 17) {
                $java17Path = $candidate.FullName
                break
            }
        }

        if ($java17Path) {
            break
        }
    }

    if (-not $java17Path) {
        throw "No Java 17 runtime was found in the usual CurseForge or Minecraft runtime folders. Set the Minecraft installation location or install Java 17."
    }

    $javaHome = Split-Path -Path (Split-Path -Path $java17Path -Parent) -Parent
    Write-Host "[INFO] Found CurseForge Java 17: $java17Path"

    $stage = "verifying selected Java 17 runtime"
    if ((Get-JavaMajorVersion -JavaPath $java17Path) -ne 17) {
        throw "The selected Java executable did not report major version 17."
    }

    $stage = "writing Java 17 path for build installer"
    $fullOutputFile = [System.IO.Path]::GetFullPath($OutputFile)
    $outputDirectory = [System.IO.Path]::GetDirectoryName($fullOutputFile)
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($fullOutputFile, $javaHome, [System.Text.Encoding]::ASCII)
    Write-Host "[INFO] Reusing CurseForge Java 17. No separate Java installation is needed."
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
