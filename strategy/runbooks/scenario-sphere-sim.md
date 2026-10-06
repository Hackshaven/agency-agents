# 🔮 Runbook: sphere-sim Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 11 on the roster, 1–2 per change

---

## Scenario

[sphere-sim](https://github.com/zyra-project/sphere-sim) simulates a four-projector Science On a Sphere install and solves for projector alignment from structured-light photos. It is TypeScript run directly by Node, with WebGL2 in the browser and no runtime dependencies. Its two halves share no code on purpose: the forward model (`packages/sim`) and the solver (`packages/solver`) pass only a calibration object (`packages/calibration`), so the solver never scores against the simulator's own arithmetic. Each release is archived on Zenodo with a DOI, and its exported bundle is what a real sphere's projectors load.

The project already has the strictest review machinery in the Zyra family. CI checks the simulator/solver boundary, determinism, digest baselines, and the gates in `docs/PARAMETERS.md` §7. Gate waivers expire and must cite an open amendment. Critics never see the builder's reasoning. What it lacks is review of the things CI can't compute: whether a statistic supports a ranking, whether a prose claim matches the results files, whether a figure tells the truth. So this team is **scientific-integrity gates, routed by path**, plus a few specialists. It has no orchestrator. The maintainer running the session is the orchestrator.

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on sphere-sim |
|-------|--------------------|
| Code Reviewer | The default for code no specialist covers. **Override its checklist on one point:** duplication between `packages/sim` and `packages/solver` is required, and extracting it into a shared module breaks the project. It runs on the same model family that writes most commits, so it shares their blind spots |
| Statistician | The gate machinery, waivers, round ranking, and any claim that a seed sweep shows an improvement |
| Pre-Submission Peer Reviewer | Experiment write-ups, headline numbers, `CITATION.cff`, and every version bump, because each release mints a DOI |
| Scientific Visualization Reviewer | Colormaps, plots, the progress page, and every committed figure |

### Specialists (as needed)
| Agent | Role on sphere-sim |
|-------|--------------------|
| Application Security Engineer | The `.glb` parser (untrusted input), the two local dev servers, and workflow permissions |
| Technical Writer | Operator documents only: `docs/CALIBRATE.md`, `docs/VISIT.md`, and the limitations text that ships inside the bundle. Not the spec or the register, which have their own rules |
| Scientific Data Steward | Release packaging and citation: each version bump mints a Zenodo DOI. It checks that the archive works on its own (license, version, citation, results files described) while the Pre-Submission Peer Reviewer checks that the claims follow from it. Also the provenance of validation photos |
| Science Communicator | Public copy: the README's "Try it" section, `packages/web/index.html`, and the plain-language metric explanations in `packages/web/src/readout.ts` |

### Periodic
| Agent | Role on sphere-sim |
|-------|--------------------|
| Mad Scientist | Only when a line of work stalls. Its bets go to the Statistician, and the maintainer chooses |
| Codebase Archaeologist | Quarterly: prose numbers against the results files, and `AMENDMENTS.md` statuses against the code |
| Codebase Onboarding Engineer | Succession: `CITATION.cff` lists one author |

## Already in the Repo (not installed by this preset)

sphere-sim has no `CLAUDE.md` and no `.claude/` directory. Its rules live in these documents. **Where a catalog agent and one of them disagree, the document wins.**

| Document | What it rules |
|----------|---------------|
| `docs/prompt.md` | The owner's brief: the simulator/solver independence, the phase gate (optimize geometry, build but never tune photometry), experiments run once, critics never read the builder's reasoning |
| `docs/PARAMETERS.md` | The spec. Implementers never edit it. It wins over anything found online, and its conflicts are deliberate |
| `docs/AMENDMENTS.md` | The register of proposed spec changes. Code reads its status lines, and a waiver must cite an OPEN entry |
| `docs/ARCHITECTURE.md` | The decomposition and the loop's stopping rule |
| `packages/*/README.md` | Each package's own boundary rules, including why the duplication is deliberate |

The CI chain in `.github/workflows/ci.yml` runs before any catalog agent. Its `gate` step is the only one allowed to fail on a number. `skills/usage-report/` is a product the repo ships, not maintenance tooling.

## Routing: Which Agent for Which Change

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `packages/bench/src/{gate,waivers,score,attribute,loop,run,scenarios}.ts`, `gate-waivers.json`, `bench-baseline.json`, `tools/assert-*.ts`, `experiments/paired/**`, the design of anything in `packages/experiments/src/` | Statistician | A wrong change here gives a false green. Raising a ceiling, widening a scenario list, or extending an expiry is the easiest way to hide a regression |
| `docs/EXPERIMENT-*.md`, `docs/ARBITRARY-SHAPES.md`, `docs/PHASE-1.md`, `docs/OPERATOR-PATH.md`, `docs/USAGE-ACCOUNTING.md`, README numbers, `CITATION.cff`, a `package.json` version bump | Pre-Submission Peer Reviewer; on a version bump, then the Scientific Data Steward | Prose numbers aren't checked by CI, and each release archives them under a DOI. Audit each claim against `experiments/*.json` and `progress/` |
| `packages/sim/src/png.ts`, `packages/experiments/src/**/plot.ts`, `packages/bench/src/{progress,views,validation}.ts`, any committed `*.svg` or figure | Scientific Visualization Reviewer | The progress page is the project's diagnostic instrument. A misleading map hides where the error is |
| `packages/meshio/src/glb.ts`, `packages/harness/serve.ts`, `packages/web/serve.ts`, `.github/workflows/{pages,release}.yml` | Application Security Engineer | A parser for files people download, servers that expose `/repo/` when bound to `0.0.0.0`, and workflows that publish |
| `docs/CALIBRATE.md`, `docs/VISIT.md`, the limitations text in `packages/web/src/bundle.ts` | Technical Writer | Read by an operator standing at a sphere |
| `validation/sources.json`, any file added under `validation/` | Scientific Data Steward | Photos are never scraped, and their provenance is unknown until the owner confirms it (`validation/README.md`) |
| README "Try it", `packages/web/index.html`, `packages/web/src/readout.ts` | Science Communicator | The words a museum visitor or operator reads next to a metric |
| `packages/sim/src/{warp,sos,sosconfig}.ts`, `packages/web/src/{bundle,restore,adopt,zip,emit,patternfilm}.ts` | Code Reviewer, and check the TerraViz importer | These files reach a real sphere. `sosconfig.ts` has a trap (A-39): each setting's description holds the factory default, and only `value` is the site's |
| `packages/web/src/glsl.ts`, `packages/harness/src/{glsl,reference,parity}.ts` | Code Reviewer, with `packages/sim` as the reference | CI's `smoke:app` checks that the shader compiles. The GPU parity chain (`packages/harness/src/parity.ts`) needs a real GPU, so CI never runs it. Run it by hand before merging |
| Any other code under `packages/` or `tools/` | Code Reviewer | No row above matches, and every code change gets a second reviewer |
| `docs/PARAMETERS.md` | Nobody edits it | Propose an amendment in `docs/AMENDMENTS.md` instead |

Every code change gets one catalog reviewer: a specialist when a row matches, otherwise the Code Reviewer. A change to the gate machinery that also moves a headline number needs two.

## Per-Change Sequence (NEXUS-Micro)

```
Step 1: Route
├── List what changed: git diff origin/main...HEAD --stat
└── Pick agents from the routing table. Code with no match goes to the Code Reviewer.

Step 2: CI first
└── npm run ci. A red boundary lint, determinism check, or baseline check
    is the project's own verdict. Fix it before any agent reads the change.

Step 3: Catalog reviewers, in parallel
├── Give each one the diff and the evidence:
│   bench-results.json, the rendered PNGs, the experiment results files
├── Do NOT give it the commit message or the author's reasoning
│   (the repo's own critic rule)
└── Each reports findings with file:line. None edits files.

Step 4: Maintainer decides
└── Fix, accept, or record why not. A waiver change records the amendment it cites.
```

### Activation prompt

```
Review this sphere-sim change as the [Agent]. Read the diff
(git diff origin/main...HEAD -- [paths]) and the evidence in [bench-results.json /
experiments/<n>/*.json / the rendered PNGs]. You are not given the author's
reasoning; judge the change from the diff and the evidence.
Report findings with file:line, most important first. Do not edit files.
The rules in docs/prompt.md, docs/PARAMETERS.md, and docs/AMENDMENTS.md win over
your own defaults. The duplication between packages/sim and packages/solver is
required; never recommend sharing code across that boundary.
```

## Periodic Work

**Codebase Archaeologist, quarterly.** Check every number in the experiment write-ups, README, and `CITATION.cff` abstract against the results files. Check each `AMENDMENTS.md` status against what the code assumes. Tell it the parallel implementations are required, so it doesn't report them as drift.

**Mad Scientist, when stuck.** Candidates as of October 2026: the mesh solve in `docs/ARBITRARY-SHAPES.md` (Phase 5), the A-18 pose floor, and the across-seed dispersion that the loop's stopping rule needs and nobody has measured (`docs/ARCHITECTURE.md`). Each bet goes to the Statistician before anyone builds it.

**Codebase Onboarding Engineer, for succession.** One guide for the forward model and one for the solver, written separately, so a newcomer learns why they can't share code.

## Cross-Repo Contract

sphere-sim's bundle (`packages/web/src/bundle.ts`, `LAYOUT_FORMAT = 'sphere-sim/projector-layout@1'`) is read by TerraViz's warp importer (`src/services/multiOutput/warpImport.ts`, `storedZip.ts`, `warpStorage.ts`, and `src/ui/outputWarpUI.ts`). TerraViz treats any other format string as unknown. A change to the bundle layout, the warp mesh format, or the SOS alignment files needs a matching TerraViz change and its fixtures (`src/output/fixtures/projectorWarp/`, regenerated by `scripts/generate-warp-parity-fixtures.ts`). See the [TerraViz runbook](scenario-terraviz.md). sphere-sim has no contract with Zyra.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge | Maintainer |
| An amendment's status (OPEN, ACCEPTED, REJECTED) | Maintainer. Agents propose; only the owner edits `PARAMETERS.md` |
| Adding, extending, or re-justifying a waiver | Maintainer, after the Statistician. Two A-18 waivers (`grid_displacement`, `h_center_recovery`) expire on **2026-11-01** |
| Rebaselining `bench-baseline.json` | Maintainer, with one sentence in the commit message saying why the number moved |
| A release (and its DOI) | Maintainer, after the Pre-Submission Peer Reviewer and the Scientific Data Steward |
| A new bundle format version | Maintainer, together with the matching TerraViz change |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer. The repo's own builder/critic loop already runs the optimization |
| Model QA Specialist | Built for the ML model lifecycle (feature stability, SHAP, label leakage). The bench plus a fresh-context critic is already independent QA |
| Performance Benchmarker | Load testing and Core Web Vitals. The bench measures accuracy, not speed |
| Technical Artist, shader agents | They trade accuracy for frame budget. This shader must match `packages/sim` |
| XR agents | No WebXR code anywhere |
| GIS agents | No CRS, tiles, or map library. The projection math is projector optics |
| Section 508 Specialist, Accessibility Auditor | `NOTICE` says it is not a NOAA product, and the main surface is a canvas. Revisit if a NOAA site links the app |
| Communications Clearance Officer | Same reason. Revisit for an agency venue |
| Research Synthesist | A handoff for the Mad Scientist, not a standing member |
| DevOps Automator, Reality Checker | CI already checks itself (`check:ci-parity`), and the gate already refuses fantasy approvals |

## Success Criteria

| Metric | Target |
|--------|--------|
| Gate-machinery changes reviewed | Every change to `packages/bench/src/` or `gate-waivers.json` names the Statistician's verdict |
| Releases audited | Every version bump has a Pre-Submission Peer Reviewer pass on its headline numbers and a Scientific Data Steward pass on its package and citation |
| Review cost | 1 catalog agent on a typical change |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| The Code Reviewer asks to extract the duplicated geometry | The activation prompt overrides it. Decline the finding |
| Extending a waiver's expiry to turn CI green | It goes to the Statistician and the maintainer. A waiver hides a failure; it doesn't fix one |
| A reviewer reads the builder's reasoning and agrees with it | Give reviewers the evidence, not the explanation |
| A few seeds' improvement presented as real | The loop's stopping rule needs an across-seed dispersion that nobody has measured yet (`docs/ARCHITECTURE.md`). Ask the Statistician before ranking |
| A photometric number treated as measured | Every photometric metric is PROVISIONAL until its constants are measured on a real sphere |
| A bundle change ships without the TerraViz side | Check the importer and its fixtures in the same week |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' sphere-sim > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt
```
