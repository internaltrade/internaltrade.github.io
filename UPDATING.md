# Updating the site — and keeping it pinned to one release

The site shows figures drawn from **one frozen corpus release**. The whole point
of the protocol below is that every page, and both data files, always name the
**same** release, and that no page is left showing numbers from an older one.

The single source of truth is the [`RELEASE`](RELEASE) file. Everything is
checked against it by [`scripts/verify_release.sh`](scripts/verify_release.sh).

---

## The rule

> **Never hand-edit a number or a release id on a page in isolation.**
> A release change is a batch: regenerate both data files, update the figures,
> bump `RELEASE`, then run the verifier. The site is only ever pinned to one
> release at a time.

Corrections do not edit a release in place — in the pipeline a correction is a
**new release** (see `schema/RELEASE_SPEC.md`). The site follows the same rule:
to change a number, move to the release that contains the change.

---

## When the corpus moves to a new release

Do these in order. `<ID>` is the new release, e.g. `2026_2.0`.

1. **Confirm the release is frozen and verified** in the pipeline
   (`verify_release()` passes; `data/releases/<ID>/` is read-only). The site must
   never be built from `data/processed/`, which keeps moving.

2. **Regenerate the two data inputs** from the analysis layer:
   ```bash
   # from the pipeline root
   Rscript R/export_site_data.R           # -> standards data (window.REFS / window.CODES)
   Rscript R/build_site_data.R <ID>       # -> data/analysis/<ID>/site/site_data.json
   ```
   `export_site_data.R` writes the two standards JSON files; concatenate them
   into `data.js` as `window.REFS` / `window.CODES` (the header comment must read
   `Release <ID>`). `build_site_data.R` writes `site_data.json` with
   `meta.release = <ID>` already set.

3. **Copy the rebuilt inputs into the site:**
   ```bash
   cp <standards data.js>                         website/standards/data.js
   cp data/analysis/<ID>/site/site_data.json      website/metrics/site_data.json
   cp data/analysis/<ID>/site/canada_prov.geojson website/metrics/canada_prov.geojson
   ```

4. **Bump the pin:** put `<ID>` in [`RELEASE`](RELEASE) (one line, nothing else).

5. **Update the release id shown in the pages.** The verifier will fail until
   every HTML release id equals `<ID>`. Occurrences today (9 total):
   - `index.html` — provenance line, stat band, "using this work" `<code>`, footer
   - `standards/index.html` — masthead provenance, method section, footer
   - `metrics/index.html` — eyebrow, industry-tab note
     (the metrics corpus line reads `meta.release` from the data file, so it
     updates itself; the eyebrow is the one hardcoded spot)

6. **Update the hardcoded corpus figures** — the numbers the verifier cannot
   check. Re-read them off the new release and replace every occurrence:

   | Figure | Meaning | Where it appears |
   |---|---|---|
   | `21,318` | regulations in the corpus | `index.html` (×2), `standards/index.html` (×3) |
   | `754,071` | provisions in the corpus | `index.html` (×2), `standards/index.html` (×3) |
   | `4,573` | standard references in force | `index.html` (×1), `standards/index.html` (×5) |
   | `13,703` | regulations in the metrics cut | `index.html` (×1); metrics reads it live from the data file |
   | `15 October 2026` / `2026-10-15` | freeze date | `index.html` (×2), `standards/index.html` (×3) |

   Standards headline findings (edition counts, equivalence counts, the 81%
   silent figure, etc.) also move with the data — re-check them against the new
   `STANDARDS_FINDINGS.md` before publishing.

7. **Verify:**
   ```bash
   cd website && bash scripts/verify_release.sh
   ```
   It must print `RESULT: consistent`. If it reports a stray id, you missed a
   spot in step 5 (or a genuine historical mention needs adding to
   [`scripts/release_allowlist.txt`](scripts/release_allowlist.txt)).

8. **Preview, commit, push.** Serve the site over HTTP (`python3 -m http.server`)
   and click through all three pages — the metrics map needs a server, not
   `file://`. Commit here (this is the site's own repo, separate from the
   private pipeline) with the release id in the message, then push. The push
   runs `verify_release.sh` again in CI and, with Pages set to deploy from the
   branch, publishes the new version automatically.

---

## When you only edit prose (no release change)

Edit the HTML text freely — headings, descriptions, framing. Do **not** touch
release ids or the corpus figures. Run `verify_release.sh` anyway before
committing; it is fast and confirms you did not disturb the pin.

---

## What the verifier does and does not catch

- **Catches:** a release id anywhere in the HTML that disagrees with `RELEASE`;
  a `data.js` header or `site_data.json` `meta.release` that disagrees. This is
  the drift that silently shows new data under an old release label.
- **Does not catch:** wrong corpus *figures* (counts, dates). Those have no
  machine-readable source in the site, so step 6's checklist is the control.
  A future improvement is to emit those figures into `site_data.json` too and
  have the pages read them live, the way the metrics corpus line already does.
