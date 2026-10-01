# Builds the Executor Rework release zips on Windows.
#
# It packs the mod files from a downloaded copy of this repository together with the
# regulation.bin that the Smithbox project saves (the params can only be built there).
# Every zip holds its files at the top level, so it can be extracted straight into a folder.
# The mod files are:
#     regulation.bin
#     action\script\c0000.hks
#     chr\c0000.anibnd.dcx
#     msg\engus\menu_dlc01.msgbnd.dcx   English texts (ability names and descriptions)
#     ExecutorRework-README.txt         notes for players
#
#   ExecutorRework-v<version>.zip (main file): the mod files, for any mod folder a loader
#   (me3 package or other) reads loose game files from
#   ExecutorRework-Standalone-v<version>.zip (optional): the mod files plus
#     executor-rework.me3               me3 profile (package path '.'), for players without a
#                                       mod setup
#   ExecutorRework-SeamlessCoop-v<version>.zip (optional): the mod files plus
#     executor-rework-coop.me3          me3 profile with Seamless Co-op
#                                       (SeamlessCoop\nrsc.dll, loaded early)
#     copy-save-to-coop.bat             copies NR0000.sl2 to the co-op save NR0000.co2
#   ExecutorRework-merge-params-v<version>.zip (optional): the rework's param rows, for
#   merging into another mod's regulation.bin in Smithbox
#     ExecutorRework_SpEffectParam.csv
#     ExecutorRework_HeroParam.csv
#
# Usage (PowerShell, from any folder; the repository is the folder this script sits in):
#   powershell -ExecutionPolicy Bypass -File "<repository>\tools\build_release.ps1" -Version 1.0.0
# Optional: -Repo <extracted repository folder> -Regulation <regulation.bin> -OutDir <folder>

param(
    [string]$Version = "1.0.0",
    [string]$Repo = (Split-Path $PSScriptRoot -Parent),
    [string]$Regulation = "$env:USERPROFILE\ExecutorRework\regulation.bin",
    [string]$OutDir = "$env:USERPROFILE\Downloads"
)

$ErrorActionPreference = "Stop"
$OutDir = (Resolve-Path $OutDir).Path

$modFiles = [ordered]@{
    "regulation.bin"                   = $Regulation
    "action\script\c0000.hks"          = Join-Path $Repo "mod\action\script\c0000.hks"
    "chr\c0000.anibnd.dcx"             = Join-Path $Repo "mod\chr\c0000.anibnd.dcx"
    "msg\engus\menu_dlc01.msgbnd.dcx"  = Join-Path $Repo "mod\msg\engus\menu_dlc01.msgbnd.dcx"
    "ExecutorRework-README.txt"        = Join-Path $Repo "release\README.txt"
}

function With-ModFiles($extra) {
    $files = [ordered]@{}
    foreach ($name in $modFiles.Keys) { $files[$name] = $modFiles[$name] }
    foreach ($name in $extra.Keys) { $files[$name] = $extra[$name] }
    return $files
}

$zips = [ordered]@{
    "ExecutorRework-v$Version" = With-ModFiles @{}
    "ExecutorRework-Standalone-v$Version" = With-ModFiles ([ordered]@{
        "executor-rework.me3"              = Join-Path $Repo "release\executor-rework.me3"
    })
    "ExecutorRework-SeamlessCoop-v$Version" = With-ModFiles ([ordered]@{
        "executor-rework-coop.me3"         = Join-Path $Repo "release\executor-rework-coop.me3"
        "copy-save-to-coop.bat"            = Join-Path $Repo "release\copy-save-to-coop.bat"
    })
    "ExecutorRework-merge-params-v$Version" = [ordered]@{
        "ExecutorRework_SpEffectParam.csv" = Join-Path $Repo "mod\params\SpEffectParam.csv"
        "ExecutorRework_HeroParam.csv"     = Join-Path $Repo "mod\params\HeroParam.csv"
    }
}

foreach ($files in $zips.Values) {
    foreach ($name in $files.Keys) {
        if (-not (Test-Path $files[$name])) { throw "Missing $name ($($files[$name]))" }
    }
}

# Zip entries use forward slashes (Compress-Archive in Windows PowerShell 5.1 can write
# backslashes, which some mod managers and extractors don't read as folders).
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

foreach ($zipName in $zips.Keys) {
    $files = $zips[$zipName]
    $zip = Join-Path $OutDir "$zipName.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($name in $files.Keys) {
            $source = (Resolve-Path $files[$name]).Path
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $source, $name.Replace('\', '/'),
                [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally {
        $archive.Dispose()
    }

    ""
    "{0} ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB)
    foreach ($name in $files.Keys) {
        "  {0,-34} {1,12:N0} bytes" -f $name, (Get-Item $files[$name]).Length
    }
}
