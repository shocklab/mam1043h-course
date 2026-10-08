# MAM1043H — Mathematica to GitHub Pages Conversion

## Project Goal

Convert 40 Mathematica notebooks for the **MAM1043H** course at UCT (first-year,
2nd semester — *Introduction to Nonlinear Dynamics*, the precursor to MAM2046W)
into a clean GitHub Pages site. Animations become GIFs, all Mathematica code
is hidden, text cells become prose, math cells become KaTeX LaTeX.

## Current Status

- **Live site**: https://shocklab.github.io/mam1043h-course/
- **Repo**: `shocklab/mam1043h-course`
- **Notebooks**: `/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H/` (40 .nb files)
- **Site root**: `/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/`
- **Stats**: 40/40 notebooks parsing cleanly, ~240 PNGs, **16 animation GIFs**
  across 11 notebooks, 45 Hugo pages building clean.

### What's done
- Hugo project with KaTeX + goldmark passthrough, GitHub Actions CI/CD to Pages.
- Python .nb parser (`parse_nb.py` + `boxes_to_latex.py`).
- `build_all.sh` — batch-parses all 40 notebooks (per-notebook title/flags).
- Static graphics export via `export_all_graphics.wl` (WolframScript + Rasterize).
- Animation GIF extraction via `export_animations_v9.wl` — the current working
  version; handles the tricky `Table[…]; ListAnimate[%]` pattern.
- TOC bulletizer in `parse_nb.py` — runs per-cell AND once at document end to
  catch stranded ToC entries between separate Text cells (e.g. the overview
  page's course-contents block).
- Cell-metadata leak filter (CellChangeTimes, ExpressionUUID, FontSize, etc.)
  via `_OPT_NAMES` in the `extract_text` fallback.
- Orphan-list / orphan-prose unindenting (for tab-pretty-printed content in
  Text cells that would otherwise render as Markdown code blocks).
- Render-image hook to prefix `baseURL` for subdirectory deployment.
- Weight-based prev/next nav via `.Scratch` in `single.html` (not
  `.PrevInSection`, which doesn't respect weight reliably).
- 8 pages wired with animation GIFs (see "Animation GIF status" below).

### What's NOT done — next session priorities

1. **More animations probably extractable** — the v9 extractor captures most
   but silently skips some. Diagnose each notebook with an empty `anim_*.gif`
   directory to see if there's a recoverable Table/ListAnimate pattern. Most
   likely remaining: notebooks where the animation body has front-end-only
   dependencies (e.g. `DynamicModule`) that `UsingFrontEnd` can't fake.

2. **Some Output cells still render as Mathematica code syntax** (like
   `Sqrt[3]`). These would need manual LaTeX replacement in the .md.

3. **Part1c (sec1-2b history — Poincaré and chaos)** — check that the Kepler
   ellipse and three-body imagery came through (user flagged sec1-2a earlier;
   sec1-2b may have similar issues since part1c is a sibling notebook).

4. **Phase 4: Interactive JS widgets** (stretch, not started). JSXGraph is
   loaded in head.html but not used yet.

## Source Material

40 notebooks organised by chapter. See `scripts/build_all.sh` for the full
mapping (nb_file | md_file | weight | img_dir | title | extra_flags).

| Chapter | Parts | Sections |
|---------|-------|----------|
| **1: Introduction** | part1a, 1b, 1c, 1d, 1e, 1f, 1exercises | 1.1–1.6 |
| **2: Flows on the Line** | part2a–2h, 2exercises, 2answers | 2.1–2.8 |
| **3: Bifurcations** | part3a, 3b, 3c, 3d, 3e, 3f, 3fii, 3exercises, 3exercises1a–1d, 4b–4e, 5b | 3.1–3.8 |
| **4: Linear Systems in 2D** | part4a, 4b, 4c, 4d, 4exercises, 4answers | 4.1–4.5 |

### Animation GIF status (16 total, 11 notebooks)

| Notebook | Page | GIFs | Notes |
|----------|------|------|-------|
| part1a | sec1-1-overview | 1 | Pendulum (101 frames) — wired as `![Pendulum animation]` replacing the Figure 1 placeholder |
| part1b | sec1-2a-history-beginnings | 1 | Kepler ellipse (21 frames) — via `Table[…]; ListAnimate[%]` pattern |
| part1d | sec1-3-systems-of-differential-equations | 1 | 41 frames |
| part1exercises | sec1-6-exercises | 1 | 41 frames (double pendulum) |
| part2g | sec2-7a-solving-on-computer | 1 | 33 frames |
| part3a | sec3-1-saddle-node-bifurcation | 1 | 157 frames |
| part3b | sec3-3-transcritical-bifurcation | 3 | 18 frames each |
| part3d | sec3-5-combinations-of-bifurcations | 1 | 35 frames |
| part4a | sec4-1-intro-2d-linear | 2 | 21 frames (ListAnimate) + 4 frames (Animate) |
| part4b | sec4-2-classification-part-1 | 1 | 21 frames |
| part4c | sec4-3-classification-part-2 | 3 | 21 frames each |

## Technology Stack

| Component | Choice |
|-----------|--------|
| Static site | **Hugo** (v0.159.1, homebrew) |
| Math rendering | **KaTeX** (via goldmark passthrough) |
| Animations | **GIF** via WolframScript |
| Interactive plots | JSXGraph loaded in head.html, not yet used |
| CI/CD | GitHub Actions → GitHub Pages |

## Scripts

### `scripts/parse_nb.py` — Python .nb parser
- Tokenises `.nb` files, parses Wolfram expression tree, emits Hugo Markdown.
- Key flags: `--weight N`, `--title "…"`, `--images-dir /images/partXX`,
  `--show-input` (include Input cells as code blocks).
- `box_to_latex()` in `boxes_to_latex.py` converts math boxes to KaTeX LaTeX.
- `clean_text_whitespace()` does per-cell text normalization:
  - Preserves leading whitespace per-line (for list nesting).
  - Strips leaked Mathematica option keys.
  - Converts `N)`, `a)` enumeration to Markdown bullets/sub-items.
  - Converts `•`, `∘`, `◦` bullet chars.
  - `_unindent_orphan_lists()` / `_unindent_orphan_prose()` strip 4+ space
    indent from blocks that would otherwise render as code blocks.
  - `_bulletize_toc_lines()` converts runs of ToC entries to bullets.
- **Document-level final pass**: `_bulletize_toc_lines(md)` runs once after
  assembly to catch stranded ToC entries between cells.
- Filters: author sections (with `@` + `Cape Town`), navigation ButtonBoxes,
  Title cells suppressed.

### `scripts/boxes_to_latex.py` — Box-to-LaTeX converter
- Uses Python 3.10+ `match/case` — **must run with Python 3.10+**.
- `/opt/homebrew/bin/python3` is 3.12 (works); `/usr/bin/python3` is older.
- Always prefix `PATH="/opt/homebrew/bin:$PATH"` when calling `build_all.sh`.
- 90+ Wolfram character mappings (Greek, operators, arrows, invisible chars).
- `merge_text_runs()` consolidates fragmented `\text{}` blocks.
- Auto-scaling delimiters, `->` → `\to`, dot-detection for `\dot{x}`.

### `scripts/export_animations_v9.wl` — Animation GIF extractor
**Current working version. Do not use v2–v8.**

Strategy:
1. Open each notebook headless (`UsingFrontEnd[NotebookOpen[…, Visible->False]]`).
2. Unprotect+override `System\`ListAnimate` and `System\`Animate` to
   intercept frames and export as GIF.
3. Walk each Input cell's held expression, **unfolding one level of
   `CompoundExpression`**, substituting `Out[]` / `%` → `lastList` before
   each `ReleaseHold`.
4. Track `lastList` across sub-expressions so `Table[…]; ListAnimate[%]`
   patterns resolve correctly (see Gotcha #1).

Thresholds:
- `ListAnimate` fires if `Length[lst] >= 5` (filters autoload-trigger noise).
- `Animate` fires if generated `Length[frames] >= 3` (preserves part4a's
  4-frame animation).

Usage: `wolframscript -file scripts/export_animations_v9.wl`
(no args — iterates over all 11 animated notebooks; see `notebooks` list
at top of file).

### `scripts/export_all_graphics.wl` — Static PNG exporter
- `UsingFrontEnd` + `NotebookOpen` + `Rasterize` at 150 DPI.
- Filters non-graphics Output cells.
- Usage: `wolframscript -file scripts/export_all_graphics.wl <abs_nb_path> <abs_output_dir>`
- **Requires absolute paths.**

### `scripts/build_all.sh` — Batch parser
- Maps all 40 notebooks to content pages.
- Format: `nb_file|md_file|weight|img_dir|title_override|extra_flags`
- **Overwrites content/*.md on every run** — any manual edits (including
  GIF re-wiring) are wiped. See "Workflow" below.

## Workflow: adding/updating content

Because `build_all.sh` overwrites all `content/*.md`, a parse → GIF-wire
cycle looks like:

```bash
cd "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site"

# 1. Re-parse all 40 notebooks (PATH needed for Python 3.10+).
PATH="/opt/homebrew/bin:$PATH" bash scripts/build_all.sh

# 2. Re-extract animations (only needed if the extractor or a source .nb
#    changed). Close the Wolfram GUI first — single-seat license.
/usr/local/bin/wolframscript -file scripts/export_animations_v9.wl

# 3. Re-wire GIFs into their pages (overwritten in step 1). Use the Python
#    snippet that appends "## Animated versions" sections — the mapping is:
#      part1a  → sec1-1-overview.md            (replaces Figure 1 placeholder)
#      part1b  → sec1-2a-history-beginnings.md
#      part1d  → sec1-3-systems-of-differential-equations.md
#      part1exercises → sec1-6-exercises.md
#      part2g  → sec2-7a-solving-on-computer.md
#      part3a  → sec3-1-saddle-node-bifurcation.md
#      part3b  → sec3-3-transcritical-bifurcation.md
#      part3d  → sec3-5-combinations-of-bifurcations.md
#      part4a  → sec4-1-intro-2d-linear.md
#      part4b  → sec4-2-classification-part-1.md
#      part4c  → sec4-3-classification-part-2.md

# 4. Local preview.
/opt/homebrew/bin/hugo server --port 1313

# 5. Commit + push — GitHub Actions deploys automatically.
git -C "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site" add -u
git -C "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site" add static/images
git -C "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site" commit -m "…"
git -C "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site" push
```

## Known Issues & Gotchas

### 1. `Table[…]; ListAnimate[%]` parse behaviour *(FIXED in v9)*
`ToExpression[cellExpr[[1]], StandardForm, Hold]` returns `Hold[s1, s2, …]`
for multi-statement cells, where each `sk` is one top-level expression.
A line ending with `;` parses into that top-level arg as
`CompoundExpression[expr, Null]`, so evaluating it returns `Null` and never
populates `lastList` — meaning `ListAnimate[%]` in the next top-level arg
sees an empty `Out[]`. **Fix**: unfold one level of `CompoundExpression`
when assembling `heldArgs`, evaluate each sub-arg separately, and track
`lastList` at that finer granularity. See the inner `Do` loop in
`export_animations_v9.wl` around line 109.

### 2. Python 3.10+ required
`boxes_to_latex.py` uses `match/case`. On this machine `python3` resolves
to 3.9 by default; Homebrew's 3.12 is at `/opt/homebrew/bin/python3`.
Always run: `PATH="/opt/homebrew/bin:$PATH" bash scripts/build_all.sh`.

### 3. `build_all.sh` overwrites everything
Manual edits to content/*.md (GIF rewiring, typo fixes, hand-crafted LaTeX)
get wiped on every run. Either script the edits as a post-parse step, or
patch the parser to produce the desired output directly.

### 4. Per-cell cleanup can't see document-level context
`clean_text_whitespace()` runs on each Text cell independently, so it can't
bulletize a ToC entry that sits alone between Section headers in *another*
cell. The extra `_bulletize_toc_lines(md)` call at the end of `main()` runs
once on the full assembled document to catch these.

### 5. Hugo weight 0 = "no weight"
Hugo sorts `weight: 0` pages last. Use `weight: 1` or higher. The weight
scheme here: chapter×10 + section, roughly.

### 6. WolframScript vs Wolfram GUI
Single-seat license — close the Wolfram GUI app before running
`wolframscript`, otherwise you get "license not activated".

### 7. WolframScript absolute paths only
`NotebookOpen` silently fails on relative paths under `UsingFrontEnd`.

### 8. Inline `<script>` in markdown is broken
goldmark converts `'` → typographic quotes inside `<script>` tags and breaks
JS. Put widget JS in `static/js/widgets/*.js` and load via layout.

### 9. Cell-metadata leak via fallback `extract_text`
The generic fallback used to join `content[1:]` tokens including option keys
like `FontSize → 14`, producing output like "Title FontSize 14". Fixed by
the explicit `Cell` handling + `_OPT_NAMES` filter around line 380 of
parse_nb.py. If new leaks appear, add the option name to `_OPT_NAMES`.

### 10. Older extractor versions (`v2`–`v8`) are kept as history
Don't use them. They lack the CompoundExpression unfolding and various
threshold fixes. `v9` is the single source of truth.

## Environment

- Hugo: `/opt/homebrew/bin/hugo` (v0.159.1)
- WolframScript: `/usr/local/bin/wolframscript` (v1.10.0) — **license active**
- Python 3.12: `/opt/homebrew/bin/python3`
- gifsicle: `/opt/homebrew/bin/gifsicle` (for adjusting GIF timing post-render)
- Notebooks: `/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H/`
- Site: `/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/`
- GitHub repo: `shocklab/mam1043h-course`

## Useful one-liners

```bash
# Re-parse a single notebook.
PATH="/opt/homebrew/bin:$PATH" python3 scripts/parse_nb.py \
  "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H/MAM1043part1a.nb" \
  content/sec1-1-overview.md --images-dir "/images/part1a" \
  --weight 11 --title "1.1 Overview of the Course"

# Export static graphics from one notebook.
wolframscript -file scripts/export_all_graphics.wl \
  "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H/MAM1043part3a.nb" \
  "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images/part3a"

# Re-extract all animations.
wolframscript -file scripts/export_animations_v9.wl

# Adjust a GIF's timing without re-render (delay in centiseconds).
/opt/homebrew/bin/gifsicle --batch --delay=12 static/images/part3a/anim_001.gif

# Audit which GIFs are on disk but not wired in pages.
PATH="/opt/homebrew/bin:$PATH" python3 -c "
import glob, os
for d in sorted(glob.glob('static/images/part*')):
    name = os.path.basename(d)
    gifs = sorted(glob.glob(f'{d}/anim_*.gif'))
    if gifs: print(f'{name}: {len(gifs)} gif(s): {[os.path.basename(g) for g in gifs]}')"

# Count pages, GIFs, PNGs.
find content -name '*.md' | wc -l
find static/images -name 'anim_*.gif' | wc -l
find static/images -name '*.png' | wc -l
```

## Site Structure

```
MAM1043H-site/
  hugo.toml                        # baseURL, goldmark passthrough
  .github/workflows/               # GitHub Actions → Pages
  content/
    _index.md                      # Home / table of contents
    sec{N}-{M}-{slug}.md           # 40 section pages
  layouts/
    _default/
      baseof.html                  # Base template
      single.html                  # Weight-based prev/next via .Scratch
      _markup/render-image.html    # Prefixes .Site.BaseURL
    partials/
      head.html                    # KaTeX + JSXGraph CDN
      nav.html                     # Sticky nav
    index.html                     # Chapter-organised ToC
  static/
    css/main.css                   # Responsive + code block styles
    js/widgets/                    # External JS (never inline)
    images/part*/                  # 240 PNGs + 16 GIFs
  scripts/
    parse_nb.py                    # Main parser
    boxes_to_latex.py              # Math box → KaTeX
    export_all_graphics.wl         # PNG exporter
    export_animations_v9.wl        # GIF extractor (current)
    build_all.sh                   # Batch parse all 40
    export_animations_v2..v8.wl    # Historical, don't use
```
