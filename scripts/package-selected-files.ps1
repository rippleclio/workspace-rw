param(
    [string]$OutputZipPath = (Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'documents') 'selected-files.zip'),
    [switch]$SkipMissing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$relativePaths = @(
    'core-platform\deploy\.env',
    'rippleclio-admin-console\.env',
    'rippleclio-content\deploy\.env',
    'rippleclio-web\.env',
    'wabifair-admin-console\.env',
    'wabifair-commerce\deploy\.env',
    'wabifair-storefront-web\.env'
)

$missing = @()
$filesToPack = foreach ($relativePath in $relativePaths) {
    $fullPath = Join-Path $root $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        [PSCustomObject]@{
            RelativePath = $relativePath
            FullPath     = $fullPath
        }
        continue
    }

    $missing += $relativePath
}

if ($missing.Count -gt 0 -and -not $SkipMissing) {
    throw "The following files do not exist. Packaging stopped:`n$($missing -join "`n")"
}

$outputDir = Split-Path -Parent $OutputZipPath
if ([string]::IsNullOrWhiteSpace($outputDir)) {
    $outputDir = $root
    $OutputZipPath = Join-Path $outputDir $OutputZipPath
}

if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

if (Test-Path -LiteralPath $OutputZipPath) {
    Remove-Item -LiteralPath $OutputZipPath -Force
}

$zip = [System.IO.Compression.ZipFile]::Open($OutputZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $filesToPack) {
        $entryName = ($file.RelativePath -replace '\\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip,
            $file.FullPath,
            $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
}
finally {
    $zip.Dispose()
}

Write-Host "ZIP:$OutputZipPath"
if ($missing.Count -gt 0) {
    Write-Warning ("The following files do not exist and were skipped:`n" + ($missing -join "`n"))
}
