# Creates a Windows desktop shortcut for the Affiliate Kit ops dashboard.
# Clicking the icon regenerates docs/ops.html from current repo state and
# opens it in Ray's default browser. Single-click "where am I" surface.
#
# Usage:
#   pwsh scripts/install-desktop-shortcut.ps1
#
# Idempotent — overwrites the existing shortcut if it's already there.

$ErrorActionPreference = "Stop"

$repoRoot     = Split-Path -Parent $PSScriptRoot
$opsScript    = Join-Path $repoRoot "scripts/ops.ps1"
$desktopPath  = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Affiliate Kit Ops.lnk"

if (-not (Test-Path $opsScript)) {
    Write-Error "Cannot find $opsScript — run from the affiliate-sites repo."
    exit 1
}

# Resolve pwsh.exe absolute path so the shortcut keeps working from anywhere
$pwshPath = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    Write-Error "pwsh.exe not on PATH. Install PowerShell 7 first."
    exit 1
}

$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($shortcutPath)
$lnk.TargetPath       = $pwshPath
$lnk.Arguments        = "-NoProfile -WindowStyle Hidden -File `"$opsScript`" -Open"
$lnk.WorkingDirectory = $repoRoot
$lnk.IconLocation     = "$env:SystemRoot\System32\shell32.dll,176"  # chart/graph icon
$lnk.Description      = "Affiliate Kit operations dashboard — regenerates and opens docs/ops.html"
$lnk.Save()

# Release COM handle
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wsh) | Out-Null

Write-Host "[ok] Desktop shortcut installed at:"
Write-Host "     $shortcutPath"
Write-Host ""
Write-Host "Double-click the icon any time to regenerate + open the ops dashboard."
