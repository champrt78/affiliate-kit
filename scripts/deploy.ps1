#Requires -Version 7

<#
.SYNOPSIS
  Build a site and deploy it to its Cloudflare Pages project.

.DESCRIPTION
  Wraps `pnpm --filter <Site> build` plus `wrangler pages deploy` into one command.
  Used as a manual deploy when CF Pages is NOT wired to GitHub auto-deploy
  (the bootstrap-from-2026-05-12 state on this project), and as a manual hotfix
  trigger when GitHub auto-deploy IS wired up.

  The CF Pages project name follows the bootstrap convention `affkit-<Site>`.

.PARAMETER Site
  The site slug (matches a directory under `sites/`). e.g. `mywildlifecam`.

.PARAMETER SkipBuild
  Skip the `pnpm --filter <Site> build` step. Useful when you already have a
  fresh dist and just want to push it (e.g. retry after a flaky network deploy).

.PARAMETER Branch
  The CF Pages branch label to deploy to. Defaults to `main`. CF Pages treats
  the `main` branch as production; any other branch shows as a preview deploy.

.EXAMPLE
  pwsh scripts/deploy.ps1 -Site mywildlifecam

.EXAMPLE
  pwsh scripts/deploy.ps1 -Site fussybean -SkipBuild
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$Site,

	[switch]$SkipBuild,

	[string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$siteRoot = Join-Path $repoRoot "sites/$Site"
$distPath = Join-Path $siteRoot "dist"

# -----------------------------------------------------------------------------
# Validate
# -----------------------------------------------------------------------------

if (-not (Test-Path $siteRoot -PathType Container)) {
	Write-Error "[err] Site directory not found: $siteRoot. Expected sites/$Site/. Available sites: $(Get-ChildItem (Join-Path $repoRoot 'sites') -Directory | Select-Object -ExpandProperty Name | Join-String -Separator ', ')"
	exit 2
}

# Per-site CF Pages project name. Originally all 5 sites used the
# `affkit-<slug>` convention from the 2026-05-12 bootstrap. mywildlifecam
# migrated to a new `mywildlifecam` Pages project on 2026-05-16 (custom
# domain detached from affkit-mywildlifecam and re-attached to the new
# Git-wired project). Other 4 sites still on the affkit-prefix convention
# until they migrate too. If/when a satellite migrates, update its entry
# here.
$projectNameMap = @{
	"mywildlifecam"   = "mywildlifecam"
	"detailerpicks"   = "affkit-detailerpicks"
	"fussybean"       = "affkit-fussybean"
	"starteraquarium" = "affkit-starteraquarium"
	"gameovergear"    = "affkit-gameovergear"
}
$projectName = $projectNameMap[$Site]
if (-not $projectName) {
	Write-Error "[err] No CF Pages project name known for site '$Site'. Update the projectNameMap in scripts/deploy.ps1."
	exit 2
}

# -----------------------------------------------------------------------------
# Build (unless skipped)
# -----------------------------------------------------------------------------

if (-not $SkipBuild) {
	Write-Host "[..] Building $Site via pnpm --filter $Site build"
	Push-Location $repoRoot
	try {
		& pnpm --filter $Site build
		if ($LASTEXITCODE -ne 0) {
			Write-Error "[err] Build failed for $Site (exit $LASTEXITCODE). Not deploying. Fix the build first."
			exit 1
		}
	} finally {
		Pop-Location
	}
	Write-Host "[ok] Build complete: $distPath"
} else {
	Write-Host "[..] -SkipBuild set; using existing $distPath"
}

if (-not (Test-Path $distPath -PathType Container)) {
	Write-Error "[err] dist directory not found at $distPath. Run without -SkipBuild to build first."
	exit 1
}

# -----------------------------------------------------------------------------
# Deploy via wrangler
# -----------------------------------------------------------------------------

Write-Host "[..] Deploying $distPath to CF Pages project $projectName (branch=$Branch)"
Push-Location $repoRoot
try {
	& npx wrangler pages deploy $distPath --project-name $projectName --branch $Branch
	if ($LASTEXITCODE -ne 0) {
		Write-Error "[err] wrangler pages deploy failed for $projectName (exit $LASTEXITCODE)."
		exit 1
	}
} finally {
	Pop-Location
}

Write-Host ""
Write-Host "Next:"
Write-Host "  - Verify live: https://$Site.com/ (or whichever apex is attached in CF)"
Write-Host "  - For piece pages: hit the new slug directly to confirm robots: index/follow and the content is current"
Write-Host "  - If you have GitHub auto-deploy wired up (option 2 from 2026-05-16), future pushes auto-deploy and this script is only needed for manual hotfixes"
