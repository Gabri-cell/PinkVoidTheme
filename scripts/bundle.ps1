#!/usr/bin/env pwsh
#
# scripts/bundle.ps1
#
# Build zip bundles for PinkVoidTheme browser extensions using only
# Windows built-ins (PowerShell Compress-Archive) — no `zip` install needed.
#
# Output (one per browser):
#   dist/pink-void.chrome.zip   # Chrome / Edge (Manifest V3)
#   dist/pink-void.firefox.zip  # Firefox (Manifest V2)
#   dist/pink-void.edge.zip     # Edge Add-ons (same payload as Chrome)
#
# Each zip places files at its root (no wrapper folder):
#   manifest.json
#   styles/bubble-dark-pink.css
#
# Usage:
#   .\scripts\bundle.ps1                         # bundle all browsers
#   .\scripts\bundle.ps1 -Browser chrome         # single browser
#   .\scripts\bundle.ps1 -Browser firefox -OutputDir ./build
#   .\scripts\bundle.ps1 -Clean                  # remove old zips first
#
[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$Browser = @(),

    [Parameter()]
    [string]$OutputDir = "",

    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot  = Resolve-Path (Join-Path $scriptDir "..")

$srcDir      = Join-Path $repoRoot "src"
$stylesDir   = Join-Path $srcDir "styles"
$cssFile     = Join-Path $stylesDir "bubble-dark-pink.css"
$chromeManifest = Join-Path $srcDir "chrome\manifest.json"
$firefoxManifest = Join-Path $srcDir "firefox\manifest.json"
$defaultOutputDir = Join-Path $repoRoot "dist"

$browserManifest = @{
    chrome  = $chromeManifest
    edge    = $chromeManifest   # Edge reuses the Chrome (MV3) manifest
    firefox = $firefoxManifest
}

$allBrowsers = @("chrome", "firefox", "edge")

# Resolve OUTPUT_DIR to an absolute path.
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = $defaultOutputDir
}
if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if (-not (Test-Path $cssFile -PathType Leaf)) {
    throw "shared CSS not found: $cssFile"
}

# Read version from the Chrome manifest (single source of truth)
$manifestText = Get-Content -Raw $chromeManifest
$version = "unknown"
if ($manifestText -match '"version"\s*:\s*"([0-9]+\.[0-9]+(?:\.[0-9]+)?)"') {
    $version = $Matches[1]
}

if (-not (Test-Path $OutputDir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $OutputDir -Force
}

if ($Clean) {
    Write-Host "==> Cleaning old bundles in $OutputDir"
    Get-ChildItem -Path $OutputDir -Filter "pink-void.*.zip" -File |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
$browsers = if ($Browser.Count -eq 0) { $allBrowsers } else { $Browser }

$failed = $false
foreach ($browser in $browsers) {
    $manifest = $browserManifest[$browser]
    if (-not $manifest) {
        Write-Warning "unsupported browser '$browser' - skipping"
        continue
    }
    if (-not (Test-Path $manifest -PathType Leaf)) {
        Write-Warning "manifest not found for '$browser': $manifest - skipping"
        continue
    }

    $zipName  = "pink-void.$browser.zip"
    $zipPath  = Join-Path $OutputDir $zipName

    Write-Host "==> building $browser (v$version) -> $zipPath"

    # Stage files so they land at the zip root with clean paths:
    #   manifest.json
    #   styles/bubble-dark-pink.css
    $stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
        "${browser}_" + ([System.Guid]::NewGuid().ToString("N"))
    )
    $null = New-Item -ItemType Directory -Path (Join-Path $stageRoot "styles") -Force

    Copy-Item $manifest (Join-Path $stageRoot "manifest.json") -Force
    Copy-Item $cssFile  (Join-Path $stageRoot "styles\bubble-dark-pink.css") -Force

    if (Test-Path $zipPath -PathType Leaf) {
        Remove-Item $zipPath -Force
    }

    # Compress from the staging root so files are stored at the zip root.
    Push-Location $stageRoot
    try {
        Compress-Archive -Path @("manifest.json", "styles") `
            -DestinationPath $zipPath
    } finally {
        Pop-Location
    }

    Remove-Item -Recurse -Force $stageRoot -ErrorAction SilentlyContinue

    if (Test-Path $zipPath -PathType Leaf) {
        $size = (Get-Item $zipPath).Length
        if ($size -ge 1MB) {
            $sizeStr = ([math]::Round($size / 1MB, 2)).ToString() + " MB"
        } elseif ($size -ge 1KB) {
            $sizeStr = ([math]::Round($size / 1KB, 2)).ToString() + " KB"
        } else {
            $sizeStr = $size.ToString() + " bytes"
        }
        Write-Host "  $zipName ready ($sizeStr)"
    } else {
        Write-Error "failed to create $zipPath"
        $failed = $true
    }
}

if ($failed) {
    throw "one or more bundles failed to build"
}

Write-Host ("done - bundles in " + $OutputDir + "/")
Get-ChildItem -Path $OutputDir -Filter "pink-void.*.zip" -File |
    ForEach-Object { Write-Host ("  " + $_.Name) }
