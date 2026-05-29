<#
.SYNOPSIS
  Shared site-config accessor — resolves fields from EITHER config shape.

.DESCRIPTION
  The repo has two divergent site-config.json shapes (CE finding V3 / plan §2.3):
    - FLAT (mywildlifecam): siteName, niche (string), primarySegments[],
      secondarySegments[], excludedSegments[], featureAxes (string[]), brandTone.
    - NESTED (detailerpicks): site.{slug,name,...}, niche.{vertical,subcategory},
      readerSegments.{primary,secondary,excluded}, featureAxes.default[{name,weight,description}],
      voice.{register,tone,...}, categoryPillars[].

  `Get-SiteConfigField` is the single accessor both the Magic Go readiness gate
  AND the scaffolders (new-review.ps1 / buyers-guide.ps1) use, so scaffold
  context stops silently degrading to "(none specified)" on DTP's nested shape.

  Dot-source this file:  . "$PSScriptRoot/lib/site-config.ps1"

.NOTES
  Returns $null when a field genuinely can't be resolved (caller decides the
  fallback string). Never throws on a missing key.
#>

function Get-SiteConfigObject {
  param([Parameter(Mandatory)][string]$ConfigPath)
  if (-not (Test-Path -LiteralPath $ConfigPath)) { return $null }
  try {
    return Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Get-SiteConfigField {
  <#
    Resolves a logical field across both shapes. Supported logical fields:
      siteName | slug | niche | segments | featureAxes | brandTone | amazonTag | categoryPillars
    Returns a string (niche/siteName/slug/brandTone/amazonTag),
    an array (segments/featureAxes/categoryPillars), or $null if unresolvable.
  #>
  param(
    [Parameter(Mandatory)] $Config,   # parsed JSON object (from Get-SiteConfigObject)
    [Parameter(Mandatory)][string]$Field
  )
  if ($null -eq $Config) { return $null }

  switch ($Field) {
    'siteName' {
      if ($Config.siteName) { return [string]$Config.siteName }
      if ($Config.site -and $Config.site.name) { return [string]$Config.site.name }
      return $null
    }
    'slug' {
      if ($Config.site -and $Config.site.slug) { return [string]$Config.site.slug }
      if ($Config.slug) { return [string]$Config.slug }
      return $null
    }
    'niche' {
      # flat: niche is a string. nested: niche.{vertical,subcategory}.
      if ($Config.niche -is [string]) { return $Config.niche }
      if ($Config.niche -and $Config.niche.vertical) {
        $n = [string]$Config.niche.vertical
        if ($Config.niche.subcategory) { $n += " (" + $Config.niche.subcategory + ")" }
        return $n
      }
      return $null
    }
    'segments' {
      # flat: primary/secondary/excludedSegments top-level arrays.
      # nested: readerSegments.{primary,secondary,excluded}.
      $primary = $null; $secondary = $null; $excluded = $null
      if ($null -ne $Config.primarySegments)   { $primary = $Config.primarySegments }
      elseif ($Config.readerSegments -and $null -ne $Config.readerSegments.primary) { $primary = $Config.readerSegments.primary }
      if ($null -ne $Config.secondarySegments) { $secondary = $Config.secondarySegments }
      elseif ($Config.readerSegments -and $null -ne $Config.readerSegments.secondary) { $secondary = $Config.readerSegments.secondary }
      if ($null -ne $Config.excludedSegments)  { $excluded = $Config.excludedSegments }
      elseif ($Config.readerSegments -and $null -ne $Config.readerSegments.excluded) { $excluded = $Config.readerSegments.excluded }
      $all = @()
      if ($primary)   { $all += @($primary) }
      if ($secondary) { $all += @($secondary) }
      # excluded is intentionally NOT merged into the body-targeting set
      # (voice doctrine: excluded is scoping metadata, never body copy).
      if ($all.Count -eq 0) { return $null }
      return $all
    }
    'excludedSegments' {
      if ($null -ne $Config.excludedSegments) { return @($Config.excludedSegments) }
      if ($Config.readerSegments -and $null -ne $Config.readerSegments.excluded) { return @($Config.readerSegments.excluded) }
      return $null
    }
    'featureAxes' {
      # flat: string[]. nested: featureAxes.default = [{name,weight,description}].
      if ($Config.featureAxes -is [array]) {
        # could be array of strings OR array of objects
        return @($Config.featureAxes | ForEach-Object {
          if ($_ -is [string]) { $_ } elseif ($_.name) { $_.name } else { [string]$_ }
        })
      }
      if ($Config.featureAxes -and $Config.featureAxes.default) {
        return @($Config.featureAxes.default | ForEach-Object {
          if ($_.name) { $_.name } elseif ($_ -is [string]) { $_ } else { [string]$_ }
        })
      }
      return $null
    }
    'brandTone' {
      if ($Config.brandTone) { return [string]$Config.brandTone }
      if ($Config.voice -and $Config.voice.tone) { return [string]$Config.voice.tone }
      if ($Config.voice -and $Config.voice.register) { return [string]$Config.voice.register }
      return $null
    }
    'amazonTag' {
      if ($Config.affiliate -and $null -ne $Config.affiliate.amazonTag) { return [string]$Config.affiliate.amazonTag }
      return $null
    }
    'categoryPillars' {
      if ($null -ne $Config.categoryPillars) { return @($Config.categoryPillars) }
      return $null
    }
    default { return $null }
  }
}
