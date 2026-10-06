# 🛰️ Runbook: Zyra Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 20 on the roster, 1–2 per change

---

## Scenario

[Zyra](https://github.com/NOAA-GSL/zyra) is NOAA-GSL's Python framework for staged, reproducible data workflows: acquire, process, visualize, narrate, export. It ships as a PyPI package with optional extras, two GHCR images (`zyra` and `zyra-scheduler`), a FastAPI service with an MCP endpoint, and LLM features (the wizard, the swarm planner, narration). TerraViz runs Zyra pipelines in a pinned container to put data-encoded video on the globe, so a Zyra change can change what every TerraViz node shows.

The canonical repo is `NOAA-GSL/zyra`. Day-to-day work happens in the downstream mirror `zyra-project/zyra`: a PR there targets `mirror/staging`, and a relay workflow rebases it onto upstream `staging` and opens `relay/hh-pr-<n>` in NOAA-GSL. One maintainer writes and merges nearly all of it, with Claude and Codex as co-authors. There is no MAINTAINERS file and no CODEOWNERS.

So, like the TerraViz team, this one is **review gates and specialists, activated by what each change touches**. It isn't a build team and has no orchestrator. Two things set it apart from TerraViz: the science path runs in Python against gridded data, and a large share of the code (API, MCP, wizard, swarm) puts an LLM or a remote caller next to a command runner.

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on Zyra |
|-------|--------------|
| Code Reviewer | The default for any code change no specialist covers. It runs on the same model family that writes many Zyra commits, so it shares their blind spots |
| Scientific Visualization Reviewer | Colormaps, heatmap and contour frames, SOS frames, legends, and the data-encoded luma output TerraViz decodes |
| Application Security Engineer | The API service, connectors and credentials, plugin loading, Docker images, dependencies, and every file CodeQL is told to skip |
| Science Communicator | Narration prompts and presets, the narrate critic rubric, and the poster text |

### Specialists (as needed)
| Agent | Role on Zyra |
|-------|--------------|
| Meteorologist | GRIB and NetCDF processing, init versus valid time, units, and missing data shown as missing. A domain check on the data, not a numerical-methods review |
| Developer Tooling Engineer | The CLI as a contract: flags, exit codes, the pipeline schema, and the capabilities manifest. TerraViz and every saved pipeline depend on them |
| API Platform Engineer | The HTTP API as a contract: any change to the OpenAPI snapshot, the manifest routes, WebSocket job streams |
| MCP Builder | The hand-written JSON-RPC MCP server and its tools |
| Multi-Agent Systems Architect | The swarm planner, its guardrails, memory, and value engine |
| Prompt Engineer | Wizard and planner prompts and the LLM client: prompts that produce commands someone will run |
| Privacy Engineer | The Limitless audio preset, wizard history, swarm memory, and anything sent to an outside LLM provider |
| Video Streaming Engineer | Narrow: ffmpeg pixel format, color range, and CRF as they change luma values. It has no adaptive-bitrate role here |
| Zyra Workflow Author | Proves pipelines run, with Zyra's own parser and a smoke run: the samples in `samples/pipelines/`, and, before TerraViz moves its runner pin to a new Zyra release, TerraViz's curated templates against that release. An author, not a reviewer |
| Scientific Data Steward | CF and ACDD metadata, units, and fill values in the netCDF files Zyra writes; the SOS dataset metadata asset; and the citation a release carries (`CITATION.cff` and its Zenodo DOI). It never invents metadata or changes data |
| Technical Writer | `docs/source/**`, module READMEs, `samples/README.md`, and the Docker READMEs. Not the wiki copy, which syncs from the GitHub Wiki |

### Public & Federal (before something goes public or hosting changes)
| Agent | Role on Zyra |
|-------|--------------|
| Communications Clearance Officer | The README, the poster and its NOAA and GSL logos, the Zyra Assistant GPT instructions, narration presets such as `policy_brief`, and release notes |
| Section 508 Specialist | The poster HTML, the Sphinx site, the API landing page, and interactive folium and plotly outputs |
| FedRAMP & RMF Compliance Engineer | `ingress/**` and any move to or within NOAA hosting |

### Quarterly
| Agent | Role on Zyra |
|-------|--------------|
| Codebase Onboarding Engineer | One guide per area: the science path, the API and MCP, the LLM features, and release and relay |
| Codebase Archaeologist | Drift across Claude, Codex, Copilot, and Cursor sessions: `AGENTS.md` against `.github/copilot-instructions.md`, docs against code, `datavizhub` leftovers, duplicated capabilities JSON |

## Already in the Repo (not installed by this preset)

Zyra has **no repo-local review agents or skills**. What it has instead:

| Repo tool | What it does |
|-----------|--------------|
| Pre-commit (`.pre-commit-config.yaml`) | Ruff, DCO sign-off, SPDX headers, `zyra generate-manifest`, the OpenAPI snapshot. **This is the real lint gate:** CI's Ruff job runs with `continue-on-error: true` |
| `AGENTS.md` | The contributor checklist. `.github/copilot-instructions.md` is a near-copy that has already drifted |
| `.claude/hooks/session-start.sh` | Installs the DCO hook |
| `./scripts/update_openapi_snapshot.sh` | Regenerates `tests/snapshots/openapi_*`. A snapshot diff is an API change |
| CodeQL (`.github/codeql/codeql-config.yml`) | Skips `src/zyra/api/routers/api_generic.py` and `src/zyra/connectors/backends/api.py`, and suppresses path-injection findings in `jobs.py`, `executor.py`, `search.py`, and `utils/assets.py`. Changes there get no automated security review |

Where a repo doc sets a rule, it wins over a catalog agent. Where a doc describes the code, the code wins: the mirror's `CLAUDE.md` still says version 0.1.43, says commands register with Click (the CLI is argparse), and says `zyra[llm]` installs the OpenAI provider.

TerraViz's `terraviz-data-video` skill is the best written record of the data-encoded contract, and it lives in the TerraViz repo.

## Routing: Which Agent for Which Change

Paths are under `src/zyra/` unless they start at the repo root.

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `visualization/{colormap_manager,luma_writer,cli_heatmap,cli_contour,cli_sos,cli_utils,basemap}.py`, `assets/images/**`, `poster/scripts/generate_visuals.py` | Scientific Visualization Reviewer | A wrong stop, range, or orientation changes what every pixel claims, on every node that runs the pipeline |
| `api/**`, `connectors/backends/**`, `connectors/credentials.py`, `utils/credential_manager.py`, `plugins.py`, `wizard/__init__.py` (command execution), root `Dockerfile`, `docker/**`, `ingress/**`, `pyproject.toml`, `poetry.lock`, `.github/codeql/**` | Application Security Engineer | `/cli/run` runs any stage, auth is off when `ZYRA_API_KEY` is unset, `plugins.py` imports code from the working directory, and the wizard runs LLM-suggested commands after one prompt (`--yes` skips it) |
| `assets/llm/prompts/narrate/**`, narration presets, `assets/llm/rubrics/critic.yaml`, `poster/sections/**` | Science Communicator | The words a reader takes as Zyra's, or NOAA's, account of the data |
| `processing/{grib_utils,grib_data_processor,netcdf_data_processor,pad_missing}.py`, `utils/{date_manager,iso8601}.py`, `connectors/backends/thredds.py` | Meteorologist | Init versus valid time, units, and fill values are where correct data becomes a wrong frame |
| `cli.py`, `*/cli_register.py`, `pipeline_runner.py`, `workflow/**`, `utils/cli_helpers.py`, `wizard/zyra_capabilities*` | Developer Tooling Engineer, then the Zyra Workflow Author before the next release | A renamed flag or a changed exit code breaks TerraViz's runner, the editor, and every saved `pipeline.yaml`. The Workflow Author re-proves TerraViz's curated templates against the release |
| `tests/snapshots/openapi_*`, `api/routers/{manifest,ws,jobs}.py` | API Platform Engineer | Outside callers read these: the ChatGPT Action, Open WebUI tools, the editor |
| `api/routers/mcp.py`, `api/mcp_tools/**`, `api/services/manifest.py`, `llm/clients/**` | MCP Builder | A hand-written protocol server. Its tool list is what an LLM is allowed to call |
| `swarm/**`, `narrate/swarm.py`, `samples/swarm/**` | Multi-Agent Systems Architect | Guardrails, memory, and planning for agents that act |
| `assets/llm/prompts/**` (outside narrate), `wizard/{prompts,llm_client}.py`, root `llm/**` | Prompt Engineer | Prompts that produce commands, and where API keys are sent |
| The Limitless preset in `api/routers/api_generic.py`, `api/mcp_tools/audio.py`, wizard history, `swarm/memory.py`, `api/utils/obs.py` | Privacy Engineer | Personal audio, saved prompts, and data sent to outside providers |
| `processing/{video_processor,video_transcode}.py`, `visualization/{cli_compose_video,animate_manager}.py` | Video Streaming Engineer | Color range and compression decide whether a decoded luma value is still the data value |
| Root `samples/pipelines/**`, `samples/swarm/**` pipeline files | Zyra Workflow Author | Users copy samples first. As of October 2026, `samples/pipelines/rtvideo_drought.yaml` doesn't parse as YAML |
| The netCDF-writing paths in `processing/{netcdf_data_processor,grib_utils}.py`, `assets/metadata/**`, root `CITATION.cff` | Scientific Data Steward | Outputs and records other people cite: metadata a reader can't recover later, and a DOI that has to resolve |
| `docs/source/**`, module `README.md` files, `samples/README.md`, `docker/**/README.md` | Technical Writer | Read by users who install from PyPI |
| `processing/raster_reproject.py`, `utils/geo_utils.py`, extent and orientation code | Code Reviewer, with an orientation checklist | No catalog agent reviews raster georeferencing well. Ask for a known-point check: north row first, longitude range, extent order. July 2026 brought a cluster of orientation bugs |
| Any other code under `src/zyra/`, `scripts/`, or `tests/` | Code Reviewer | No row above matches, and every code change gets a second reviewer |
| README, poster, `llm/prompts/zyra_helper_bot_system.md`, release notes, about to go public | Communications Clearance Officer | Zyra carries NOAA and GSL branding |
| Poster HTML, the Sphinx site, the API landing page (`api/server.py`) | Section 508 Specialist | Federal web content |
| `ingress/**`, a hosting move | FedRAMP & RMF Compliance Engineer | Authorization paperwork, before the move |

Every code change gets one catalog reviewer: a specialist when a row matches, otherwise the Code Reviewer. A change to `visualization/luma_writer.py` gets two (the viz reviewer and the Video Streaming Engineer if compression is involved), plus a TerraViz check. A docs-only change to the mirror's own workflows gets none.

## Per-Change Sequence (NEXUS-Micro)

```
Step 0: Check the mirror is current
├── Compare the last commit date on mirror/staging with NOAA-GSL/zyra staging
│   (SHAs differ: the sync strips workflows with git filter-repo)
└── If the mirror is behind, review against upstream staging, not the mirror

Step 1: Route
├── List what changed: git diff origin/mirror/staging...HEAD --stat
└── Pick agents from the routing table. Code with no match goes to the Code Reviewer.

Step 2: Repo checks first
├── pre-commit run --all-files (Ruff, DCO, SPDX, manifest, OpenAPI snapshot)
└── poetry run pytest with the extras the change needs. CI installs only
    dev + api, so tests that importorskip matplotlib, xarray, rasterio,
    or cartopy may never run there

Step 3: Catalog reviewers, in parallel
├── Give each one the diff and what it needs to see
│   (the viz reviewer gets rendered frames and the sidecar JSON)
└── Each reports findings with file:line. None edits files.

Step 4: Maintainer decides, then the relay
├── Fix, accept, or record why not
└── If the relay resolved conflicts in favor of upstream, reread the relayed diff
```

### Activation prompt

```
Review this Zyra change as the [Agent]. Read the diff
(git diff origin/mirror/staging...HEAD -- [paths]) and [rendered frames / sidecar JSON /
OpenAPI snapshot diff / prompt file]. Report findings with file:line, most important first.
Do not edit files. Where AGENTS.md or a module README sets a rule, it wins; where a doc
describes the code differently from the code, the code wins.
```

## Cross-Repo Contracts

| Contract | Zyra side | Consumer side |
|----------|-----------|---------------|
| Runner version | GHCR image `ghcr.io/noaa-gsl/zyra`, and the release that builds it | TerraViz pins the image by digest in `.github/workflows/zyra-run.yml` |
| Stage allowlist and flags | `cli.py`, the stage registrars, `--datetime-format`, `--output-names` | TerraViz `src/types/zyra-workflow-constants.ts` (`ZYRA_STAGE_ALLOWLIST`) and `src/types/zyra-pipeline-args.ts` |
| Data-encoded frames | `visualization/luma_writer.py` (NaN encodes as 0, 256 sidecar stops), `cli_heatmap.py` | TerraViz `src/types/color-scale.ts`, `docs/DATA_ENCODED_VIDEO_PLAN.md`, the `terraviz-data-video` skill |
| Palettes | `--cmap-file`, `--legend-file`, `colormap_manager.py` | TerraViz passes palettes only as files or `cmap_inline`. A named `--cmap` is ignored on the data-encoded path |
| HTTP API and capabilities | `api/**`, `wizard/zyra_capabilities*.json` | zyra-editor (below), MCP clients, the ChatGPT Action, Open WebUI tools |

A change to any Zyra-side row needs a TerraViz check before the next image is pinned. See the [TerraViz runbook](scenario-terraviz.md).

## Companion Repo: zyra-editor (dormant)

[zyra-editor](https://github.com/zyra-project/zyra-editor) is a node-graph editor for Zyra pipelines: a TypeScript core, a React editor, and a FastAPI server that wraps `zyra.api.server.create_app`. Its last commit was 2026-03-15. TerraViz chose not to embed it (`docs/ZYRA_INTEGRATION_PLAN.md`), and pasting `pipeline.yaml` is the whole interop story. It needs **no standing team**.

**One action while it's dormant.** Its Docker setup binds the server to `0.0.0.0:8765`. None of the editor's own routes require a key, and the server substitutes any `${VAR}` argument from its own environment, including the LLM provider key. Anyone who follows the poster's "Get started" block runs that exposed. Have the Application Security Engineer review `server/main.py`, `server/Dockerfile`, and `docker-compose.yml`, or at least add a warning to the README. Archiving the repo is the maintainer's call.

**If it wakes up,** route it like this:

| If the change touches… | Run |
|------------------------|-----|
| Any code | Code Reviewer |
| `server/**`, Docker files, the secret path in `packages/editor/src/{useExecution.ts,App.tsx}` | Application Security Engineer |
| Feedback (`/v1/feedback`) or run history | Privacy Engineer |
| `poster/**` | Communications Clearance Officer |

Also fix its CLI fallback first: it calls `zyra commands --json`, and `manifest.schema.json` describes `zyra manifest --json`. Neither command exists in Zyra; the real one is `zyra generate-manifest`.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge downstream, and merge the relayed PR upstream | Maintainer |
| A breaking CLI flag, exit code, or pipeline-schema change | Maintainer, after the Developer Tooling Engineer, with a deprecation period |
| A change to the data-encoded format | Maintainer, together with the matching TerraViz change |
| Excluding a file from CodeQL | Maintainer, after the Application Security Engineer |
| A release (PyPI and GHCR) | Maintainer, after the Scientific Data Steward checks the citation |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer |
| Data Engineer, Spatial Data Engineer, Geoprocessing Specialist | Builders for warehouses, vector ETL, and ArcPy. Zyra moves gridded files through a CLI |
| GIS QA Engineer | Its checks are vector and ArcGIS-oriented. Raster orientation stays with the Code Reviewer and a known-point check |
| Climatologist | Zyra has no climate statistics code. Call it ad hoc for climate claims in narration output |
| AI Engineer, LLM Post-Training Engineer, Model QA, RAG Pipeline Engineer | Zyra trains no models and has no vector store |
| Statistician | `verify/` is a stub. Revisit when it computes skill scores |
| API Tester | About 60 API test files and the OpenAPI snapshot already exist |
| DevOps Automator, SRE | Generic builders, and CI lives upstream |
| Secrets & Credential Engineer | AppSec covers it. Call it for a leak, or to move PyPI publishing from a long-lived token to Trusted Publishing |
| AI-Generated Code Security Auditor, Senior SecOps | Built around Next.js, Supabase, JWT, and cookie patterns Zyra doesn't have |
| Git Workflow Master, Minimal Change Engineer | `AGENTS.md`, the DCO hook, and the relay already set the git rules |
| Accessibility Auditor, USWDS Developer | Overlaps the 508 specialist; Zyra has no USWDS site |
| Pre-Submission Peer Reviewer | No manuscript in the repo |

## Success Criteria

| Metric | Target |
|--------|--------|
| Routed changes reviewed | Every relayed PR that touches a routed path names the reviewer that ran |
| CodeQL-excluded files | Every change to one gets an AppSec pass |
| Cross-repo breaks | No Zyra release breaks the TerraViz runner pin silently |
| Review cost | 1–2 catalog agents on a typical change |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| Reviewing against a stale mirror | Step 0. As of October 2026, the mirror stops in late July and upstream moved on 2026-09-28 with security fixes |
| Trusting CI's green Ruff check | It never fails. Run pre-commit |
| Science tests skipped in CI | Run pytest locally with the extras the change touches |
| A catalog reviewer follows the stale `CLAUDE.md` | The code wins over a doc's description of it. Fix the doc |
| Treating the Code Reviewer's pass as independent | It shares the authoring model's blind spots |
| A flag renamed without a TerraViz check | The Developer Tooling Engineer and the cross-repo table above |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' zyra > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt
```
