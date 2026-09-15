<#
.SYNOPSIS
    Rewrite the absolute asset/script paths in the tracked OBS scene
    collection(s) so they point at THIS clone's location.

.DESCRIPTION
    OBS stores media sources and loaded Lua/Python scripts as absolute
    paths inside the scene-collection JSON. When the repo is cloned or
    moved to a new folder those baked-in paths no longer resolve, so
    media, logos and the Grid/camera scripts silently fail to load.

    This script anchors on the repo-relative folders that the paths point
    into ("/media/..." and "/data/obs-plugins/frontend-tools/scripts/...")
    and replaces whatever absolute prefix precedes them with the current
    repo root. It is location-independent and idempotent - safe to re-run
    any time the folder is moved.

    Run it standalone after moving the folder, or let unpack.bat call it
    as the final bootstrap step.
#>

$ErrorActionPreference = 'Stop'

# Repo root = the folder this script lives in, forward-slashed, no trailing slash.
$root = (Split-Path -Parent $MyInvocation.MyCommand.Path).TrimEnd('\','/') -replace '\\','/'

$sceneDir = Join-Path $root 'config/obs-studio/basic/scenes'
if (-not (Test-Path $sceneDir)) {
    Write-Host "[normalize] No scene folder at $sceneDir - nothing to do."
    return
}

# Match a quoted absolute path (drive-letter) up to the first repo-relative
# anchor, capturing the anchor so we can rebuild the path under $root.
#   "C:/old/place/media/logos/x.png"  ->  "<root>/media/logos/x.png"
$pattern     = '(?i)"[A-Za-z]:[^"]*?/(media|data/obs-plugins/frontend-tools/scripts)/'
$replacement = '"' + $root + '/$1/'
$utf8NoBom   = New-Object System.Text.UTF8Encoding($false)
$total       = 0

Get-ChildItem -Path $sceneDir -Filter '*.json' -File | ForEach-Object {
    $text    = [System.IO.File]::ReadAllText($_.FullName)
    $matches = [regex]::Matches($text, $pattern).Count
    if ($matches -gt 0) {
        $new = [regex]::Replace($text, $pattern, $replacement)
        if ($new -ne $text) {
            [System.IO.File]::WriteAllText($_.FullName, $new, $utf8NoBom)
            Write-Host ("[normalize] {0}: repointed {1} path(s) to {2}" -f $_.Name, $matches, $root)
            $total += $matches
        } else {
            Write-Host ("[normalize] {0}: already current." -f $_.Name)
        }
    }
}

Write-Host ("[normalize] Done. {0} path(s) updated to root: {1}" -f $total, $root)
