<#
.SYNOPSIS
  One-off: create the 2026-05-29 batch run manifest (Tier 1 = 9 pieces) and
  close out the superseded N=2 proof run. Idempotent-ish: safe to read, but
  creating twice makes two runs — only run once.
#>
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/lib/magic-go-manifest.ps1"

# Close out the superseded N=2 proof run (piece 1 shipped; piece 2 folded into this batch).
$old = "2026-05-29-0606"
$om = Read-MagicGoManifest -RunId $old
if ($om -and $om.status -ne "complete") {
  Set-MagicGoRunStatus -RunId $old -Status "complete"
  Write-Host "Closed superseded run $old (status=complete)." -ForegroundColor DarkYellow
}

$alloc = @{ mywildlifecam = 3; detailerpicks = 3; fussybean = 3 }
$runId = New-MagicGoManifest -RequestedN 9 -Allocation $alloc
Write-Host "Created batch run: $runId" -ForegroundColor Green

# Tier 1 pieces. status starts 'scouted' for fresh scaffolds; the espresso fix
# is a repair (status 'researched' — product set already exists, just broken).
$pieces = @(
  @{ slug="best-cellular-trail-cameras";              site="mywildlifecam"; type="buyers-guide"; title="Best Cellular Trail Cameras (2026)"; product="(6-pick guide)" }
  @{ slug="browning-strike-force-pro-xd-review";       site="mywildlifecam"; type="review";       title="Browning Strike Force Pro XD Review"; product="Browning Strike Force Pro XD" }
  @{ slug="bushnell-cellucore-20-review";              site="mywildlifecam"; type="review";       title="Bushnell CelluCORE 20 Review"; product="Bushnell CelluCORE 20" }

  @{ slug="best-ceramic-coating-for-home-detailers";   site="detailerpicks"; type="buyers-guide"; title="Best Ceramic Coatings for Home Detailers"; product="(6-pick guide)" }
  @{ slug="best-drying-towel-for-home-detailers";      site="detailerpicks"; type="buyers-guide"; title="Best Drying Towels for Cars"; product="(6-pick guide)" }
  @{ slug="adams-graphene-ceramic-spray-review";       site="detailerpicks"; type="review";       title="Adam's Graphene Ceramic Spray Coating Review"; product="Adam's Graphene Ceramic Spray Coating" }

  @{ slug="best-espresso-machine-for-beginners";       site="fussybean";     type="buyers-guide"; title="Best Espresso Machines for Beginners (REPAIR)"; product="(6-pick guide — fix images+ASINs)"; status="researched" }
  @{ slug="best-coffee-grinder-for-beginners";         site="fussybean";     type="buyers-guide"; title="Best Coffee Grinders for Beginners"; product="(6-pick guide)" }
  @{ slug="fellow-stagg-ekg-electric-kettle-review";   site="fussybean";     type="review";       title="Fellow Stagg EKG Electric Kettle Review"; product="Fellow Stagg EKG" }
)

foreach ($p in $pieces) {
  $h = @{ slug=$p.slug; site=$p.site; type=$p.type; title=$p.title; product=$p.product }
  if ($p.ContainsKey("status")) { $h.status = $p.status }
  Add-MagicGoPiece -RunId $runId -Piece $h
}
Write-Host "Registered $($pieces.Count) Tier-1 pieces." -ForegroundColor Green
Write-Host "RUNID=$runId"
