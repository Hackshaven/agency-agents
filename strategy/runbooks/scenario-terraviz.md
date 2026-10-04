# 🌍 Runbook: TerraViz Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 14 on the roster, 1–3 per code change

---

## Scenario

[TerraViz](https://github.com/zyra-project/terraviz) is a web 3D globe for NOAA's Science On a Sphere catalog: a TypeScript SPA on Cloudflare Pages, a Pages Functions catalog backend, and a Tauri desktop app with multi-monitor output for physical spheres and projector rigs. It has **one maintainer**, and `MAINTAINERS.md` names that as the project's largest risk.

Claude Code already does most of the building. What a one-person project lacks is a second reviewer: someone who checks the palette, the dataset description, the accessibility of a new panel, or the security of a publisher route before it merges. So this team is **review gates and specialists, activated by what each change touches**. It isn't a build team, and it has no orchestrator. The maintainer running the session is the orchestrator.

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on TerraViz |
|-------|------------------|
| Code Reviewer | The default for any code change no specialist covers: correctness, maintainability, security, performance. It runs on the same model family that writes most TerraViz commits, so it shares their blind spots. It doesn't replace a human or a different-model review |
| Scientific Visualization Reviewer | Palettes, colorbars, data-encoded color scales, legends, multi-globe comparisons, poster figures |
| Science Communicator | Dataset descriptions, tour narration, Orbit's prompt and replies, blog posts |
| Section 508 Accessibility Specialist | UI panels and styles. TerraViz is headed to a NOAA-GSL deployment, so Section 508 is the legal floor |

### Specialists (as needed)
| Agent | Role on TerraViz |
|-------|------------------|
| Video Streaming Engineer | HLS renditions, the transcode pipeline, output-window decoding |
| Web GIS Developer | The MapLibre globe, GIBS tiles, the custom WebGL tile layer |
| Internationalization Engineer | ICU plural rules, RTL layout, the Weblate pipeline |
| Application Security Engineer | Publisher API and roles, the LLM proxy, federation signing |
| Desktop App Engineer | The Tauri app: windows and messaging between the control and output windows, capabilities, code signing, auto-update, the kiosk launch |
| Privacy Engineer | Data flows outside telemetry: Orbit's cloud voice, chat sent to outside LLM providers, feedback submissions, publisher accounts |
| Technical Writer | Operator-facing docs only: self-hosting, the multi-monitor operations runbook, the macOS install and translator guides. Not the plan docs, which have their own house voice |

### Public & Federal (before something goes public or hosting changes)
| Agent | Role on TerraViz |
|-------|------------------|
| Communications Clearance Officer | AI-drafted blog posts, current-events pairings, and Orbit's system prompt: on a NOAA node, each one speaks for the agency |
| FedRAMP & RMF Compliance Engineer | Hosting on federal infrastructure that needs an authorization (ATO) |

### Maintainer Succession (quarterly)
| Agent | Role on TerraViz |
|-------|------------------|
| Codebase Onboarding Engineer | Code-grounded onboarding guides for the candidate maintainer areas in `MAINTAINERS.md` |

## Already in the Repo (not installed by this preset)

TerraViz ships its own reviewers in `.claude/agents/`. They encode rules no catalog agent can know, and they reread the repo's source-of-truth docs on every run. **Run them first.** Where a catalog agent and a repo doc disagree, the repo doc wins.

| Repo agent | Runs when a change touches |
|------------|----------------------------|
| `analytics-reviewer` | `src/analytics/**`, `functions/api/ingest.ts`, the `TelemetryEvent` union, any `emit()` call site, `grafana/dashboards/**` |
| `federation-protocol-reviewer` | `WireDataset` or any type it reaches, `functions/api/v1/catalog.ts`, `functions/.well-known/**`, `public/schema/**`, `docs/protocol/**`, federation code |

The repo's `terraviz-data-video` skill pairs with the Scientific Visualization Reviewer: the skill builds data-encoded workflows, and the reviewer checks what they put on the globe.

## Routing: Which Agent for Which Change

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `src/types/color-scale.ts`, `src/services/colorScaleDisplay.ts`, `src/ui/colorbarUI.ts`, `src/ui/analyzeCharts.ts`, a Zyra workflow palette | Scientific Visualization Reviewer | A wrong range or stop changes what every pixel claims |
| Dataset text (`src/ui/publisher/components/dataset-form.ts`), tours (`src/ui/tourAuthoring/`), Orbit's prompt (`src/services/docentContext.ts`), English strings (`locales/en.json`) | Science Communicator | The words visitors read beside the data |
| `src/ui/**`, `src/styles/**` | Section 508 Accessibility Specialist | Every new panel is a new barrier or not |
| `src/services/hlsService.ts`, `cli/transcode-from-dispatch.ts`, `src/output/datasetMirror.ts` | Video Streaming Engineer | Rendition choice and decode cost decide whether a sphere keeps up |
| `src/services/mapRenderer.ts`, `src/services/earthTileLayer.ts`, `src/services/tilePreloader.ts` | Web GIS Developer | Tile, projection, and layer bugs show up as the wrong place on Earth |
| `src/i18n/`, non-English `locales/`, CSS that could break RTL | Internationalization Engineer | Strings and layout for every shipped language |
| `functions/api/v1/publish/**`, `src/types/publisher-roles.ts`, `functions/api/chat/` | Application Security Engineer | Write paths, roles, and the LLM proxy |
| `src-tauri/**`, `src/services/multiOutput/**`, `src/services/windowChrome.ts` | Desktop App Engineer | Capabilities, messaging between windows, signing, and the updater are where a desktop app's security lives |
| `src/services/voiceCloudEngines.ts`, `src/services/voiceWsStreaming.ts`, `functions/api/voice/`, `src/services/llmProvider.ts`, `functions/api/feedback.ts`, `functions/api/general-feedback.ts`, `src/ui/publisher/pages/users.ts`, `docs/PRIVACY.md` | Privacy Engineer | Audio, chat, feedback, and accounts leave the browser here. Telemetry is the analytics reviewer's |
| `docs/SELF_HOSTING.md`, `docs/MULTI_MONITOR_OPERATIONS.md`, `docs/MACOS_INSTALL.md`, `CONTRIBUTING-TRANSLATIONS.md` | Technical Writer | Read by operators and translators, not the maintainer |
| Any other code under `src/`, `functions/`, `cli/`, or `src-tauri/` | Code Reviewer | No row above matches, and every code change gets a second reviewer |
| A blog post or event pairing about to go live, or a change to Orbit's system prompt | Communications Clearance Officer | A NOAA node, and the assistant on it, speak for the agency |
| A hosting move onto federal infrastructure | FedRAMP & RMF Compliance Engineer | Authorization paperwork, before the move, not after |
| Telemetry | `analytics-reviewer` (repo) | Privacy invariants |
| The wire contract or federation | `federation-protocol-reviewer` (repo) | Outside consumers read what ships |

Every code change gets one catalog reviewer: a specialist when a row matches, otherwise the Code Reviewer. Few need more than two. A plan-doc change needs none.

## Per-Change Sequence (NEXUS-Micro)

```
Step 1: Route
├── List what changed: git diff origin/main...HEAD --stat
└── Pick agents from the routing table. Code with no match goes to the Code Reviewer.

Step 2: Repo reviewers first
├── analytics-reviewer, if telemetry changed
└── federation-protocol-reviewer, if the wire contract changed
    Their blocking conditions are the project's own.

Step 3: Catalog reviewers, in parallel
├── Give each one the diff and what it needs to see
│   (the viz reviewer gets screenshots from
│    npm run screenshots:report -- --scene <name>)
└── Each reports findings with file:line. None edits files.

Step 4: Maintainer decides
├── Fix, accept, or record why not
└── CI gates still run: the type-check chain, the visual report, the smoke tests
```

### Activation prompt

```
Review this TerraViz change as the [Agent]. Read the diff
(git diff origin/main...HEAD -- [paths]) and [screenshots / dataset text / route file].
Report findings with file:line, most important first. Do not edit files.
Where the repo's own docs set a rule (CLAUDE.md, docs/ANALYTICS_CONTRIBUTING.md,
docs/protocol/), the repo doc wins.
```

## Maintainer Succession (quarterly)

Run the Codebase Onboarding Engineer once per candidate area that `MAINTAINERS.md` lists, today: **backend and catalog**, **globe and rendering**, and **workflows and operations**. Each run produces a guide a newcomer could start from, grounded in the code rather than the plan docs. Refresh a guide when its area has changed since the last run.

This is the only part of the team aimed at the project's largest risk, and no agent fixes that risk by itself. The guides lower the cost of saying yes for a second maintainer. `MAINTAINERS.md` prefers a non-federal one, so the guides should assume no NOAA context.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge | Maintainer |
| A breaking wire change or `schema_version` bump | Maintainer, after `federation-protocol-reviewer` escalates |
| Publishing a blog post or event pairing | Maintainer, after clearance |
| Adding a maintainer | Maintainer, per `GOVERNANCE.md` |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer. NEXUS handoffs cost more than they save at this size |
| Frontend Developer, Backend Architect | Builders, and Claude Code already builds. The Frontend Developer assumes a framework TerraViz doesn't use. The Backend Architect belongs in a Phase 4 build team |
| API Platform Engineer, API Tester | The `federation-protocol-reviewer` covers the contract, and the routes ship with their own tests. Revisit when the API opens to partners |
| Git Workflow Master | CLAUDE.md already sets the git rules: DCO sign-off, one logical change per commit |
| Rust Refactoring Specialist | The desktop shell is small, about 1,300 lines of Rust (October 2026) |
| USWDS Developer | As of October 2026, no federal website standard is required yet. The pending banner standard covers .gov and .mil sites and accepts any design system that meets it. If a NOAA node goes live on a .gov domain, the banner is a one-time task |
| WordPress Performance Engineer | TerraViz isn't WordPress. The plugin is a separate PHP repo |
| XR Immersive Developer, Voice AI Integration Engineer, Performance Benchmarker | Too thin, or built for a different job: transcription pipelines, generic load testing. The output HUD already measures frame pacing |
| Accessibility Auditor | Overlaps the 508 specialist. The visual report already runs axe (`VISUAL_AXE`) |
| Persona Walkthrough | Built for conversion-rate audits, the wrong lens for a museum operator |
| Marketing and growth | Not this team's job. Public text still goes through the Science Communicator and the Clearance Officer |

## Success Criteria

| Metric | Target |
|--------|--------|
| Routed changes reviewed | Every PR that touches a routed path names the reviewer that ran |
| Review cost | 1–2 catalog agents on a typical code change |
| Onboarding guides | One per candidate area, refreshed each quarter the area changed |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| Running every agent on every PR | Route by path. Most code changes need one reviewer |
| Treating the Code Reviewer's pass as independent | It shares the authoring model's blind spots. On risky changes, a human or different-model review still counts for more |
| A catalog reviewer contradicts a repo doc | The repo doc wins. Record the disagreement if it's worth a doc change |
| The viz reviewer gets code without pictures | Hand it screenshots from the visual report |
| Clearance after a post is live | Clear before publishing |
| Treating the team as the second maintainer | It reviews. It can't hold the project when the maintainer is away |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' terraviz > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt
```

The repo agents in `.claude/agents/` come with a TerraViz checkout and need no install.
