<#
.SYNOPSIS
  Install affiliate-kit Git hooks from scripts/ into .git/hooks/.

.DESCRIPTION
  The hook *source* lives in scripts/pre-commit-hook.sh so it's
  version-controlled. Git looks for the live hook at .git/hooks/pre-commit
  which isn't versioned — this script copies the source into place. Re-run
  whenever the hook source changes, or after a fresh clone.

.EXAMPLE
  pwsh scripts/install-hooks.ps1
#>

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$hooksDir = Join-Path $repoRoot ".git/hooks"

if (-not (Test-Path $hooksDir)) {
  Write-Host "ERROR: $hooksDir not found. Is this a git checkout?" -ForegroundColor Red
  exit 1
}

$src = Join-Path $repoRoot "scripts/pre-commit-hook.sh"
$dst = Join-Path $hooksDir "pre-commit"

if (-not (Test-Path $src)) {
  Write-Host "ERROR: source hook not found at $src" -ForegroundColor Red
  exit 1
}

Copy-Item -LiteralPath $src -Destination $dst -Force
Write-Host "Installed pre-commit hook -> .git/hooks/pre-commit" -ForegroundColor Green

# On Unix-like systems the hook needs execute perms. Windows ignores chmod,
# but Git for Windows reads the file mode via stat() — try chmod when bash
# is available, harmless if not.
if (Get-Command bash -ErrorAction SilentlyContinue) {
  bash -c "chmod +x '.git/hooks/pre-commit'"
}

Write-Host ""
Write-Host "Hook installed. Test with: git commit --allow-empty -m 'test hook'" -ForegroundColor Cyan
