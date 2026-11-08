# Interprovincial Trade Project — website

A public, static site that reads the full text of every consolidated regulation
in Canada and shows where provincial rules diverge in ways that get in the way
of trade. Faculty of Law, University of Ottawa — led by Prof. Wolfgang Alschner.

**Live site:** _add the GitHub Pages URL here once published_
**Pinned corpus release:** `2026_1.1` (see [`RELEASE`](RELEASE))

The site has a landing page and two interactive explorers:

- **Standards in Canadian Regulation** — which technical standards regulators
  write into law, which editions they pin, and where one government accepts a
  foreign standard its neighbour will not.
- **Metrics in Canadian Regulation** — how binding, flexible, complex and dated
  each jurisdiction's regulations are (RegData restriction counts and four
  semantic dimensions), mapped across the country and ranked by regulation.

## Structure

```
.
├── index.html                  landing page
├── standards/
│   ├── index.html              Standards explorer (7 tabs + reference search)
│   └── data.js                 4,573 references + model-code provisions
├── metrics/
│   ├── index.html              Metrics explorer (d3 choropleth + rankings)
│   ├── site_data.json          province aggregates + per-metric rankings
│   └── canada_prov.geojson     province/territory boundaries
├── RELEASE                     the one corpus release the whole site is pinned to
├── UPDATING.md                 how to update data and keep the release pin honest
├── scripts/verify_release.sh   fails if any page/data file drifts off RELEASE
├── LICENSE                     MIT — the code
└── LICENSE-DATA                CC BY 4.0 — the data files
```

Navigation is nested: **home → explorer → the explorer's own tabs**. All links
are relative, so the site works at a repo-root or a project sub-path unchanged.

## Viewing it locally

Serve over HTTP (not `file://`) and open <http://localhost:8000/>:

```bash
python3 -m http.server 8000
```

> The Metrics map loads `site_data.json` and `canada_prov.geojson` with
> `fetch()`, which browsers block on `file://`. The landing page and the
> Standards explorer work from `file://` too; only the map needs a server.
> GitHub Pages serves over HTTPS, so this is a local-preview caveat only.

## Publishing (GitHub Pages)

This repo is a static site at its root, so the simplest deployment is
**Settings → Pages → Build and deployment → Deploy from a branch → `main` / `(root)`**.
The `.nojekyll` file tells Pages to serve the files as-is without Jekyll
processing. No build step runs.

Every push and pull request runs
[`scripts/verify_release.sh`](scripts/verify_release.sh) in CI
(`.github/workflows/verify.yml`) to enforce the release pin described below.

## Keeping the site pinned to one release

The site shows figures from **one frozen corpus release**. The guarantee that
every page and both data files always name the *same* release — so new data can
never ship under an old release label — is enforced by `RELEASE` plus the
verifier:

```bash
bash scripts/verify_release.sh      # 0 = consistent, 1 = drift
```

To move the site to a new corpus release, follow the 8-step runbook in
[`UPDATING.md`](UPDATING.md). For prose-only edits (headings, descriptions),
edit the HTML freely and run the verifier before committing.

## How the data is produced

The site is the published output of a separate, private research pipeline (the
corpus build and analysis layer). That pipeline regenerates the two data inputs
from a frozen, verified release; the built, vetted files are copied here. The
raw corpus and source documents are not part of this repository.

- Standards data: `R/export_site_data.R` → concatenated into `data.js`.
- Metrics data: `R/build_site_data.R <release>` → `site_data.json`.

## Methods and credit

- Restriction counts follow **RegData** (Mercatus Center / QuantGov):
  <https://www.quantgov.org/canada-regdata>
- The four semantic dimensions follow **Alschner, Zachar & Pontello (2018)**:
  <https://github.com/WAlschner/Semantic-Analysis-Regulations>

Each explorer carries its own method-and-limits section. Read it before citing:
the figures are a research release in progress, levels are provisional and
rankings are stable.

## Citation

> Interprovincial Trade Project (W. Alschner), Faculty of Law, University of
> Ottawa. *Standards and Metrics in Canadian Regulation*, corpus release
> 2026_1.1, 2026.

## License

- **Code** (HTML, CSS, JavaScript, scripts): MIT — see [`LICENSE`](LICENSE).
- **Data** (`standards/data.js`, `metrics/site_data.json`,
  `metrics/canada_prov.geojson`): CC BY 4.0 — see [`LICENSE-DATA`](LICENSE-DATA).

The underlying legislation is the work of its respective Crown and governmental
publishers and carries its own terms; the CC BY licence covers the project's
derived compilation and values, not the primary law.
