#!/usr/bin/env bash
# verify_release.sh — fail if the published site is not consistently pinned to
# the one release named in website/RELEASE.
#
# Checks, in order:
#   1. standards/data.js header comment says "Release <RELEASE>"
#   2. metrics/site_data.json  meta.release == <RELEASE>
#   3. no HTML page contains a release id (YYYY_x.y) other than <RELEASE>,
#      except ids explicitly listed in scripts/release_allowlist.txt
#
# It does NOT check the hardcoded corpus figures (regulation/provision counts,
# reference totals, freeze date) — those change per release and cannot be
# verified without the analysis layer. UPDATING.md lists them for a manual pass.
#
# Usage:  bash scripts/verify_release.sh          (run from the website/ root)
# Exit:   0 = consistent, 1 = drift found.
set -euo pipefail
cd "$(dirname "$0")/.."                      # -> website/ root

REL="$(tr -d ' \t\r\n' < RELEASE)"
if [ -z "$REL" ]; then echo "✗ RELEASE is empty"; exit 1; fi
echo "Pinned release (RELEASE): $REL"

fail=0
pass(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad(){  printf '  \033[31m✗\033[0m %s\n' "$1"; fail=1; }

# --- 1. standards data file header -----------------------------------------
if grep -q "Release ${REL}" standards/data.js; then
  pass "standards/data.js header names $REL"
else
  found="$(grep -oE 'Release 20[0-9]{2}_[0-9]+\.[0-9]+' standards/data.js | head -1 || true)"
  bad "standards/data.js header is '${found:-<none>}', expected 'Release $REL'"
fi

# --- 2. metrics data file meta.release -------------------------------------
j="$(python3 -c "import json,sys; print(json.load(open('metrics/site_data.json'))['meta']['release'])" 2>/dev/null || echo "<unreadable>")"
if [ "$j" = "$REL" ]; then
  pass "metrics/site_data.json meta.release == $REL"
else
  bad "metrics/site_data.json meta.release == '$j', expected '$REL'"
fi

# --- 3. HTML release tokens -------------------------------------------------
# Build the set of permitted ids: the current release + the allowlist.
allow="$REL"
if [ -f scripts/release_allowlist.txt ]; then
  while IFS= read -r line; do
    line="${line%%#*}"; line="$(printf '%s' "$line" | tr -d ' \t\r')"
    [ -n "$line" ] && allow="$allow $line"
  done < scripts/release_allowlist.txt
fi
html_bad=0
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  tok="${hit##*:}"
  ok=0; for a in $allow; do [ "$tok" = "$a" ] && ok=1; done
  if [ "$ok" -eq 0 ]; then bad "stray release id in ${hit%:*} → $tok"; html_bad=1; fi
done < <(grep -rnoE "20[0-9]{2}_[0-9]+\.[0-9]+" --include="*.html" . | sed -E 's#^\./##')
[ "$html_bad" -eq 0 ] && pass "all HTML release ids are $REL (or allowlisted)"

echo
if [ "$fail" -eq 0 ]; then
  echo "RESULT: consistent — site is pinned to $REL."
else
  echo "RESULT: DRIFT — fix the items above, or update RELEASE / the allowlist."
fi
exit "$fail"
