# Issue drafts from the Zyra Workflow Author work (2026-10-05)

Not filed as of 2026-10-06. Each draft is ready to paste; review and edit before filing. The findings behind them, with evidence, are in [`zyra-workflow-author.md`](zyra-workflow-author.md) (Findings for Eric).

- **Targets.** TerraViz drafts go to `zyra-project/terraviz`. Zyra drafts are written for `NOAA-GSL/zyra`, the repository TerraViz's docs call canonical and the one its gap-issue plan (A2) files against. If you track Zyra issues on `zyra-project/zyra` instead, the text works as is.
- **Duplicates.** Neither repository is attached to this session, so I couldn't search existing issues. Search before filing.
- **Versions.** Checked against TerraViz `main` at `3e3aae5` and Zyra `mirror/main` (0.1.54, `f036478`). Some items were also checked on Zyra 0.1.52.
- **Evidence labels.** RAN means I reproduced it by running code. READ means it comes from reading the code.
- **Order.** Each repository's drafts are listed by priority.

---

## TerraViz (`zyra-project/terraviz`)

### T1. The default runner image can't render data-encoded video
**Labels:** bug, workflows · **Evidence:** RAN

The committed runner image, `ZYRA_IMAGE_DEFAULT` in `.github/workflows/zyra-run.yml:63` (`ghcr.io/noaa-gsl/zyra@sha256:0f335b9d…`), is Zyra 0.1.52. Data-encoded output (`visualize heatmap --data-encoded --color-scale-file`) arrived in Zyra 0.1.53. As a result, a node that hasn't set `ZYRA_SCHEDULER_IMAGE` fails every data-encoded workflow at the heatmap stage. That includes the `terraviz-data-video` skill's own template.

**Reproduce:** render `.claude/skills/terraviz-data-video/assets/model-cycle-data-encoded.template.yaml` and parse each stage's argv with Zyra 0.1.52's CLI parser:
```
stage[2] visualize heatmap: FAIL zyra: error: unrecognized arguments: --data-encoded --color-scale-file /work/color-scale.json
```
On 0.1.54 all five stages parse. Zyra 0.1.52's `zyra_capabilities.json` has no `--data-encoded`, and neither does its source; `luma_writer.py` first appears in 0.1.53.

**Expected:** a fresh node can run the documented data-encoded path.

**Suggested fix:**
- Bump `ZYRA_IMAGE_DEFAULT` to a 0.1.53+ `zyra` image digest, and move the allowlist with it as the file's comment requires.
- Update `docs/DATA_ENCODED_VIDEO_PLAN.md:10`, which still lists "the zyra release + `ZYRA_SCHEDULER_IMAGE` bump" as not done.

---

### T2. The curated `http-frames-sos` template saves, then fails on the runner
**Labels:** bug, workflows · **Evidence:** RAN

`src/ui/publisher/workflow-templates.ts:121` (`http-frames-sos`) passes `sync-dir: /work/images/frames` to `acquire http` (line 128). `acquire http` has no `--sync-dir` in Zyra 0.1.52 or 0.1.54. The template passes `/validate` and `cli/lib/workflow-templates.test.ts`, then fails in the container:
```
stage[0] acquire http: FAIL zyra: error: unrecognized arguments: --sync-dir /work/images/frames
```
(Each stage's argv was built with `pipeline_runner._build_argv_for_stage`, then parsed by Zyra's CLI on 0.1.52 and 0.1.54.) The other two templates, `ftp-frames-sos` and `gefs-cycle-sos`, parse cleanly on both versions. The `acquire http` stage snippet is fine.

**Why there's no one-line fix:** in 0.1.54, `acquire http` can list a directory (`--list --pattern --since-period`, which prints URLs) or download explicit URLs (`--inputs --output-dir`). It can't list and download in one stage, so there's no HTTP equivalent of the FTP sync.

**Suggested fix:**
- Remove or hide the template until Zyra's HTTP backend gains a directory sync (Z7).
- Make `workflow-templates.test.ts` parse each template's argv against the pinned Zyra manifest (T3), so this class of break fails CI.

---

### T3. `/validate` accepts invented argument names
**Labels:** enhancement, workflows, security-adjacent · **Evidence:** RAN, READ

`validatePipeline` (`functions/api/v1/_lib/workflow-validators.ts:57`) checks stage/command pairs against `ZYRA_STAGE_ALLOWLIST`, along with value shapes, placeholders and the output path. It never checks argument names (the loop at `:133` checks values only). So a misspelled or invented flag saves cleanly and dies in the container with `unrecognized arguments`. T2 is one case. Another: adding `colormap: viridis` to a heatmap stage passes `/validate` and fails Zyra's parser.

This matters more once an LLM drafts workflows (A4): invented flags are the most common failure when models generate commands for rarely seen tools (Béchard & Ayala, NAACL Industry 2024; Jain et al., ICSE-SEIP 2025).

**Suggested fix:**
- Ship the option names for each allowlisted command from the pinned version's `zyra_capabilities.json` (a few KB) with the app.
- In `validatePipeline`, map each arg key to its flag (`snake_case` → `--kebab-case`, plus the runner's positional list) and reject unknown names with an `unknown_arg` error that names the valid ones.

This is deterministic, needs no Zyra at the edge, and moves with the image pin, just like the allowlist. It passes the plan's flowchart test.

---

### T4. A metadata template's `categories` field passes `/validate` but fails the dataset update
**Labels:** bug, workflows · **Evidence:** READ (not run end to end)

`validateMetadataTemplate` accepts template values only as strings or string arrays (`workflow-validators.ts:238`). The dataset PATCH requires `categories` to be an object of facet → values (`functions/api/v1/_lib/validators.ts:695`, "Categories must be an object of facet→values."). The sidecar renderer passes `categories` through unchanged. So `"categories": ["Water"]`, as in `docs/DATASET_SOURCE_PRESETS_DRAFT.md:443` and `:505`, saves fine and should fail the PATCH at run time.

**Suggested fix:** pick one of these:
- remove `categories` from `METADATA_TEMPLATE_FIELDS`, so it's set on the dataset form;
- accept the facet object in templates.

Also fix the two preset examples.

---

### T5. Docs drift: the `terraviz-data-video` skill and the plan-doc status headers
**Labels:** documentation · **Evidence:** READ

The skill:
- `SKILL.md:140` says "There is **no auto gradient legend on `main`**." But `src/main.ts:1945-1966` now draws a colorbar from `color_scale` for data-encoded datasets ("the rendered colorbar supersedes the uploaded legend image"). The same advice appears in `references/data-encoded-contract.md`. It tells authors to upload a `legend_ref` PNG they no longer need.
- The skill's template ends on `compose-video`, while its own text (step 4) prefers ending on frames.
- After T1, the skill should say a node needs Zyra 0.1.53+ for the data-encoded path.

Status headers that say less is built than is:
- `docs/ZYRA_INTEGRATION_PLAN.md:18` ("No code, no migrations")
- `docs/DATA_ENCODED_VIDEO_PLAN.md:3` ("on branches, not yet merged")
- `docs/INCREMENTAL_FRAME_UPLOAD_PLAN.md:3`
- `docs/INCREMENTAL_HLS_PLAN.md:3`

---

### T6. Preset attribution for the geostationary composite disagrees with SOS
**Labels:** documentation, presets · **Evidence:** READ (fetched)

`docs/DATASET_SOURCE_PRESETS_DRAFT.md` (`geostationary-composite`, `rt/sat/linear/medium`) credits "SSEC / CIMSS, University of Wisconsin–Madison". The SOS catalog page for this feed (https://sos.noaa.gov/catalog/datasets/clouds-real-time/, fetched 2026-10-05) credits:
- data: NOAA's Aviation Weather Center (AWC), compositing GOES, Himawari, Meteosat, JPSS and Suomi-NPP;
- visualization: NOAA Office of Education / CIRES.

Confirm with the SOS team before `dataset-source-presets.ts` copies it.

---

### T7. Show temperature color scales in °F and °C
**Labels:** enhancement, i18n/units · **Evidence:** READ

Data-encoded temperature datasets, such as GFS 2 m air temperature in K, hover in kelvin. `toDisplayUnits` (`src/types/unit-scale.ts:261`) rescales only by SI prefix (powers of ten), and it runs once, at `src/services/dataService.ts:443`; hover, the colorbar, Analyze and the CSV all read its output. Zyra can't convert units in the pipeline, because it has no arithmetic on fields. In any case, the source's units should stay the record.

**Proposal:**
- Teach `toDisplayUnits` one affine restatement: K → °C (−273.15) and K → °F ((K − 273.15) × 9/5 + 32).
- Keep `sourceUnits: K` as provenance.
- Decide who picks the display unit: the node, a viewer toggle, or the locale.

This is exact, because each pixel's value is a linear function of vmin and vmax. **Test:** a 200–312 K sidecar shows −99.7 to 101.9 °F, and a hovered value matches.

---

### T8. Orbit authoring mode (A4) can't calibrate: consider a `sample_range` tool
**Labels:** plan, enhancement · **Evidence:** design note

With A4's four tools (probe, validate, create draft, save), Orbit can't sample a field's values. Every data-encoded draft's `vmin`/`vmax` would be borrowed or guessed, and a vmax ten times too high is the most common "black globe" failure.

**Proposal:** a `sample_range` job on the same GitHub Actions path as `probe_source`. It would:
- range-GET one `.idx` record, or one subset;
- return percentiles as bounded text, with no secrets in scope.

That closes the calibration gap without a new trust surface. A draft of the A4 system prompt is at `.designs/zyra-workflow-author-orbit-prompt.md` in `hackshaven/agency-agents`.

---

### T9. Question: should Run now work on a disabled workflow?
**Labels:** question, workflows · **Evidence:** READ

`functions/api/v1/publish/workflows/[id]/run.ts` doesn't check `enabled`, so a disabled workflow can be run by hand. That's useful for one-off fixed periods ("September's SST anomalies"): save it disabled with a long schedule, and run it once. Is that intended? If so, saying it in the UI would help. If not, it's a gap in the "disabled means inert" guarantee.

---

## Zyra (`NOAA-GSL/zyra`)

### Z1. `compose-video` exits 0 and writes no video when ffmpeg is missing
**Labels:** bug · **Evidence:** RAN (0.1.54)

With no `ffmpeg` on `PATH`, `zyra visualize compose-video --frames frames --output out.mp4 --fps 2` logs:
```
ERROR: An error occurred while checking FFmpeg installation: [Errno 2] No such file or directory: 'ffmpeg'
WARNING: ffmpeg/ffprobe not available; skipping video composition
```
It then **exits 0, and `out.mp4` doesn't exist** (`src/zyra/visualization/cli_compose_video.py:126`). A pipeline reports success with no output. Downstream consumers have to add their own existence checks; TerraViz's runner has an output gate for this.

**Expected:** a non-zero exit when the requested output can't be produced.

---

### Z2. `process reproject` ignores CF `scale_factor`/`add_offset` on NetCDF inputs
**Labels:** bug · **Evidence:** RAN (0.1.54)

Reprojecting a packed NetCDF variable writes the raw integers. NOAA OISST v2.1 stores `anom` as int16 with `scale_factor` 0.01 (units Celsius):
```
zyra process reproject --input 'NETCDF:oisst-avhrr-v02r01.20260915.nc:anom' --s-srs EPSG:4326 \
  --dst-bounds -180 -90 180 90 --output rp.tif
```
- The output's p0.1/p99.9 are −262.6/625.0. The decoded values (xarray) are −2.68/6.25 °C.
- The median ratio is exactly 100.
- Orientation is correct: correlation 0.991 with the decoded grid.

The file is from `noaa-cdr-sea-surface-temp-optimum-interpolation-pds` on S3. Anything colored or encoded from the output is off by the scale factor.

**Expected:** apply `scale_factor`/`add_offset` (and `_FillValue`) when reading a NetCDF subdataset, or carry them into the GeoTIFF's band scale/offset and honor them downstream.

---

### Z3. `heatmap --data-encoded` rejects variables with singleton time or level dimensions
**Labels:** enhancement · **Evidence:** RAN (0.1.54)

`zyra visualize heatmap --input oisst.nc --var anom --data-encoded --vmin -8 --vmax 8 --color-scale-file cs.json --output hm.png` fails:
```
ERROR: Data must be a 2-D grid for luma output (got 4-D)
```
The error comes from `luma_writer.py:71`; OISST's `anom` is `(time=1, zlev=1, lat, lon)`. Most daily NetCDF products carry singleton time and level dimensions.

**Suggested fix:** squeeze singleton dimensions, or add `--time-index`/`--level-index`, before the 2-D check.

---

### Z4. `process convert-format` can't turn NetCDF into GeoTIFF, and the error points elsewhere
**Labels:** enhancement · **Evidence:** RAN (0.1.54)

`zyra process convert-format oisst.nc geotiff --var anom --output anom.tif` fails with the same message whether or not `--backend cfgrib` is given:
```
RuntimeError: GeoTIFF conversion requires the cfgrib backend (xarray dataset); decoded backend 'pygrib' has no GeoTIFF path.
```
The input is NetCDF, not GRIB2. Either support NetCDF → GeoTIFF here (xarray/rioxarray are already in the processing extra, and it should honor CF scaling; see Z2), or say plainly that NetCDF input isn't supported.

---

### Z5. The pipeline runner passes `period:` through as an unknown `--period` flag
**Labels:** bug · **Evidence:** RAN (0.1.54)

`_build_argv_for_stage` (`src/zyra/pipeline_runner.py:212`) computes `--since` from a non-ISO `period:` arg, but it leaves `period` in `args`, so it's also emitted as `--period`. `acquire ftp` rejects it:
```
stage[0] acquire ftp: FAIL zyra: error: unrecognized arguments: --period 1Y
```
This is stage 0 of `samples/pipelines/rtvideo_drought.yaml`, parsed with Zyra's CLI. `since_period:` doesn't have the problem.

**Suggested fix:** pop `period` once it has been converted, as the `file_pattern` → `pattern` rewrite already does.

---

### Z6. Two sample pipelines don't run
**Labels:** bug, samples · **Evidence:** RAN (0.1.54)

**`samples/pipelines/rtvideo_drought.yaml`**
- Line 2, `name: rtvideo parity: drought weekly`, is invalid YAML: the second `: ` (YAML error at line 2, column 21). `zyra run` then falls back to `json.loads` and fails with a JSON error that hides the YAML one. Quote the name.
- After that, stage 0 hits Z5's `--period` problem.

**`samples/pipelines/thredds_to_local.yaml`**
- Stage 0 fails: `unrecognized arguments: --catalog-url`. `acquire thredds` takes the catalog URL as a positional, and the runner's positional list doesn't include it (`pipeline_runner.py:233-247`), so `acquire thredds` can't be a pipeline stage today.
- Either add it to the positional map or drop the sample. (Zyra's own `docs/source/wiki/Pipeline-Schema.md` lists `acquire vimeo` among the commands with the same limit.)

---

### Z7. `acquire http`: directory sync for autoindex listings
**Labels:** enhancement · **Evidence:** READ

`acquire ftp` can keep a local directory in step with a remote one (`--sync-dir`, `--pattern`, `--since-period`, `--date-format`). `acquire http` can list a directory or download explicit URLs, but not both in one stage. So real-time image feeds served over HTTPS (autoindex pages) can't be mirrored the way FTP feeds are. TerraViz's curated HTTP template assumed the flag exists (T2).

**Request:** `--sync-dir` for `acquire http`, with the FTP backend's semantics (download matches not present locally, and optionally remove locals no longer listed).

---

### Z8. `zyra wizard` drops every `zyra` command after the user edits them
**Labels:** bug, wizard · **Evidence:** READ

In the edit path (`src/zyra/wizard/__init__.py:1304-1314`), the "strict safety filter" keeps only lines starting with `datavizhub `. Any `zyra …` command is dropped, and the wizard prints "No commands to run after edit. Cancelled." The non-edit paths (`:837`, `:912`) accept both prefixes.

**Fix:** accept `zyra ` there too.
