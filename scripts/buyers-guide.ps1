# Scaffolds a new buyer's guide: copies templates/buyers-guide.md.tmpl,
# fills frontmatter, writes the cloaked-link KV entry via scripts/add-link.ps1,
# prints next steps.
#
# Buyer's guides cover products Ray does NOT own. Frontmatter shape is
# `products[]` (per the buyersGuides Zod schema) — for v1 we seed a single
# product. No `rating` field — buyer's guides don't carry a personal score.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Site,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$ProductName,

    [Parameter(Mandatory = $true)]
    [string]$Brand,

    [Parameter(Mandatory = $true)]
    [string]$AmazonUrl,

    [string]$Description = "",

    [string]$Tag = "",

    [switch]$NoKV,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot "templates/buyers-guide.md.tmpl"
$targetDir = Join-Path $repoRoot "sites/$Site/src/content/buyers-guides"
$targetPath = Join-Path $targetDir "$Slug.md"

if (-not (Test-Path $templatePath)) {
    Write-Host "[err] Template not found: $templatePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $repoRoot "sites/$Site"))) {
    Write-Host "[err] Site directory not found: sites/$Site" -ForegroundColor Red
    Write-Host "       Known sites live under sites/. Did you mean to bootstrap first?" -ForegroundColor Red
    exit 1
}

if ((Test-Path $targetPath) -and -not $Force) {
    Write-Host "[err] Buyer's guide already exists: $targetPath" -ForegroundColor Red
    Write-Host "       Re-run with -Force to overwrite." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$pubDate = (Get-Date -Format "yyyy-MM-dd")

$content = Get-Content $templatePath -Raw

$substitutions = [ordered]@{
    "__PRODUCT_NAME__"             = $ProductName
    "__PRODUCT_BRAND__"            = $Brand
    "__SLUG__"                     = $Slug
    "__PUB_DATE__"                 = $pubDate
    "__AMAZON_URL__"               = $AmazonUrl
    "__SHORT_DESCRIPTION__"        = $Description
    "__TAGLINE_HOOK_ONE_LINER__"   = ""
    "__FAQ_QUESTION_1__"           = ""
    "__FAQ_QUESTION_2__"           = ""
    "__FAQ_QUESTION_3__"           = ""
}

foreach ($key in $substitutions.Keys) {
    $content = $content.Replace($key, $substitutions[$key])
}

# Preserve the template's trailing-newline state.
Set-Content -Path $targetPath -Value $content -NoNewline

Write-Host "[ok] Wrote $targetPath"

# Delegate the KV write to add-link.ps1 unless suppressed.
if (-not $NoKV) {
    $addLink = Join-Path $PSScriptRoot "add-link.ps1"
    if (-not (Test-Path $addLink)) {
        Write-Host "[warn] add-link.ps1 not found at $addLink — skipping KV write." -ForegroundColor Yellow
    } else {
        Write-Host "[..] Invoking add-link.ps1 for KV entry"
        $addLinkArgs = @(
            "-Site",     $Site,
            "-Slug",     $Slug,
            "-Url",      $AmazonUrl,
            "-Merchant", "amazon"
        )
        if ($Tag -and $Tag.Trim().Length -gt 0) {
            $addLinkArgs += @("-Tag", $Tag)
        }

        & $addLink @addLinkArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[warn] add-link.ps1 exited $LASTEXITCODE — markdown was still written." -ForegroundColor Yellow
            Write-Host "       Fix the KV entry by re-running scripts/add-link.ps1 directly." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[..] -NoKV set; skipped KV write."
}

Write-Host ""
Write-Host "Next:"
Write-Host "  - Open sites/$Site/src/content/buyers-guides/$Slug.md"
Write-Host "  - Fill in ``## Editor's Note`` (the build will block until you do)"
Write-Host "  - Buyer's guides are NOT personal reviews — frame as research synthesis"
Write-Host "  - Verify the cloaked link: <apex>/go/$Slug should 302 to $AmazonUrl (post-publish)"
Write-Host "  - Commit + push when ready: git add . && git commit -m `"feat: add $Slug buyer's guide`""
