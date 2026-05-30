#!/usr/bin/env bash
# Git pre-commit hook for affiliate-kit.
#
# Source of truth lives in this file at scripts/pre-commit-hook.sh and is
# copied into .git/hooks/pre-commit by scripts/install-hooks.ps1.
# Re-run install-hooks.ps1 after edits so the live hook picks them up.
#
# Runs the safeguard lints when relevant files are staged:
#   - lint-product-images.ps1      if any content markdown is staged
#   - lint-content-frontmatter.ps1 if any content markdown is staged
#       (pillar: presence/validity on hub sites + description <=160)
#   - lint-affiliate-tags.ps1      if any .md or .astro under sites/ is staged
# Exits non-zero on any failure, blocking the commit.

set -e

# Skip when no commit would happen (e.g., merge in progress with conflicts)
if [ -f .git/MERGE_MSG ] || [ -f .git/CHERRY_PICK_HEAD ]; then
  exit 0
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

NEEDS_IMAGE_LINT=0
NEEDS_TAG_LINT=0
NEEDS_FM_LINT=0

while IFS= read -r f; do
  case "$f" in
    sites/*/src/content/*.md)
      NEEDS_IMAGE_LINT=1
      NEEDS_TAG_LINT=1
      NEEDS_FM_LINT=1
      ;;
    sites/*/src/*.astro|sites/*/src/**/*.astro)
      NEEDS_TAG_LINT=1
      ;;
    sites/*/src/data/site-config.json)
      NEEDS_TAG_LINT=1
      ;;
  esac
done <<< "$STAGED_FILES"

EXIT=0

if [ "$NEEDS_IMAGE_LINT" = "1" ]; then
  echo ""
  echo ">> Running product-image lint on staged content..."
  if ! pwsh -NoProfile -File scripts/lint-product-images.ps1; then
    EXIT=1
  fi
fi

if [ "$NEEDS_FM_LINT" = "1" ]; then
  echo ""
  echo ">> Running content-frontmatter lint (pillar + description)..."
  if ! pwsh -NoProfile -File scripts/lint-content-frontmatter.ps1; then
    EXIT=1
  fi
fi

if [ "$NEEDS_TAG_LINT" = "1" ]; then
  echo ""
  echo ">> Running affiliate-tag lint on staged content..."
  if ! pwsh -NoProfile -File scripts/lint-affiliate-tags.ps1; then
    EXIT=1
  fi
fi

if [ "$EXIT" != "0" ]; then
  echo ""
  echo "Pre-commit lint failed. Fix the findings above (or use 'git commit --no-verify' to bypass, sparingly)."
fi

exit $EXIT
