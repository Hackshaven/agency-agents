# 🌍 Runbook: TerraViz Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 22 on the roster, 1–3 per code change | **Covers**: TerraViz and its WordPress plugin

---

## Scenario

[TerraViz](https://github.com/zyra-project/terraviz) is a web 3D globe for NOAA's Science On a Sphere catalog: a TypeScript SPA on Cloudflare Pages, a Pages Functions catalog backend on D1, and a Tauri desktop app with multi-monitor output for physical spheres and projector rigs. Nodes federate over a published wire contract. The [TerraViz WordPress plugin](https://github.com/zyra-project/terraviz-wordpress-plugin) embeds the globe in WordPress sites and drives a node's publisher API from wp-admin. TerraViz has **one maintainer**, and `MAINTAINERS.md` names that as the project's largest risk.

Claude Code already does most of the building. What a one-person project lacks is a second reviewer. `GOVERNANCE.md` (§Review of AI-assisted changes) puts it plainly: the person who prompts a change is the person who approves it, and AI-assisted review is a partial measure. This team is that partial measure: **review gates and specialists, activated by what each change touches**. It isn't a build team, and it has no orchestrator. The maintainer running the session is the orchestrator.

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on TerraViz |
|-------|------------------|
| Code Reviewer | The default for any code change no specialist covers: correctness, maintainability, security, performance. It runs on the same model family that writes most TerraViz commits, so it shares their blind spots. It doesn't replace a human or a different-model review |
| TerraViz Federation Reviewer | The published contracts `GOVERNANCE.md` names: the v1 wire schemas and the `WireDataset`, catalog, and well-known shapes behind them, node identity and signing, and the embed URL grammar. A fork-only agent built for this project |
| Scientific Visualization Reviewer | Palettes, colorbars, data-encoded color scales, legends, multi-globe comparisons, the poster's figures |
| Science Communicator | Dataset descriptions, tour narration, Orbit's prompt and replies, blog posts, the poster's text |
| Section 508 Accessibility Specialist | UI panels, styles, and design tokens. TerraViz is headed to a NOAA-GSL deployment (`CANONICAL_TRANSITION.md` §9), so Section 508 is the legal floor |

### Specialists (as needed)
| Agent | Role on TerraViz |
|-------|------------------|
| Video Streaming Engineer | HLS renditions, the transcode pipeline, output-window decoding. It knows delivery, not what lossy encoding does to data-encoded luma, so pair it with the `terraviz-data-video` skill and `npm run check:luma-range` |
| Web GIS Developer | The MapLibre globe, GIBS tiles, the custom WebGL tile layer, photoreal Earth. An app builder: it knows tiles and projections, less so WebGL2 custom layers |
| Internationalization Engineer | ICU plural rules, RTL layout, the Weblate pipeline |
| Application Security Engineer | The publisher API and roles, Access and preview tokens, response headers, workflow secrets. It says nothing about LLMs, so those go to the next row |
| AI-Generated Code Security Auditor | Every LLM touchpoint (the chat proxy, Workers AI calls, AI blog and event drafting, Orbit's tools) and secrets behind a `VITE_` prefix. Its examples are Next.js and Supabase; its prompt-injection and client-bundle checks apply as written |
| Desktop App Engineer | The Tauri app: windows and messaging between the control and output windows, capabilities, code signing, auto-update, the kiosk launch |
| Privacy Engineer | Data flows outside telemetry: Orbit's cloud voice, chat sent to outside LLM providers, feedback and its exports, analytics exports, publisher accounts |
| API Platform Engineer | Contracts other software reads that the Federation Reviewer doesn't own: the publish API the WordPress plugin calls, the Orbit postMessage bridge, the STAC surface |
| Zyra Workflow Author | Writes Zyra pipelines for a node's workflow dashboard and proves they run: every flag checked against the runner's Zyra version, limits sampled from real data, a smoke run, a disabled draft for a person to enable. On this team it also re-proves the curated templates whenever the runner's Zyra image changes. An author, not a reviewer: its drafts go to the Scientific Visualization Reviewer and the Science Communicator |
| Scientific Data Steward | Dataset metadata and citation: the metadata policy and readiness checks, STAC lineage and reports, and the citation a release carries (`CITATION.cff` and its Zenodo concept DOI). It never invents metadata or changes data |
| Technical Writer | Operator-facing docs only: self-hosting, the multi-monitor operations runbook, the macOS install and translator guides, the plugin's `readme.txt`. Not the plan docs, which have their own house voice |

### WordPress Plugin (plugin changes)
| Agent | Role on the plugin |
|-------|--------------------|
| WordPress Performance Engineer | Narrow: the server-side render path, transient caching, and asset loading. Its rule against lazy-loading the largest image applies to the embed's poster image. It's written for site operators, so ignore its hosting advice |

The plugin's other routes reuse agents above. See [Companion Repo: the WordPress plugin](#companion-repo-the-wordpress-plugin).

### Public & Federal (before something goes public or hosting changes)
| Agent | Role on TerraViz |
|-------|------------------|
| Communications Clearance Officer | AI-drafted blog posts (including posts synced in from WordPress), current-events pairings, and Orbit's system prompt: on a NOAA node, each one speaks for the agency |
| Meteorologist | A post or event pairing about an active weather hazard. It defers to official forecasts and warnings, and checks times, units, and uncertainty |
| FedRAMP & RMF Compliance Engineer | Hosting on federal infrastructure that needs an authorization (ATO) |

### Quarterly
| Agent | Role on TerraViz |
|-------|------------------|
| Codebase Onboarding Engineer | Code-grounded onboarding guides for the candidate maintainer areas in `MAINTAINERS.md` |
| Codebase Archaeologist | Drift between plan docs, skills, and code. As of October 2026 several plan docs and one skill reference describe code that has since shipped or moved |

## Already in the Repo (not installed by this preset)

TerraViz ships its own reviewers, skills, and hooks in `.claude/`. They encode rules no catalog agent can know, and they reread the repo's source-of-truth docs on every run. **Run them first.**

| Repo tool | Runs when |
|-----------|-----------|
| `analytics-reviewer` (agent) | A change touches `src/analytics/**`, `functions/api/ingest.ts`, the `TelemetryEvent` union, any `emit()` call site, or `grafana/dashboards/**` |
| `add-analytics-event` (skill) | Adding a telemetry event. Pairs with `analytics-reviewer` |
| `terraviz-data-video` (skill) | Building a data-encoded workflow. Pairs with the Scientific Visualization Reviewer, which checks what the workflow puts on the globe |
| `graphify` (vendored skill) | Building code maps across tiers. Hand its output to the Codebase Onboarding Engineer |
| `guard-protected-files` (hook) | Always. It blocks edits to generated files (`tokens.css`, `messages*.ts`, `schema/v1/*.json`, and others) and hand edits to lockfiles |

**Which source wins.** Where a repo doc sets a rule (`CLAUDE.md`, `CONTRIBUTING.md` §LLM Integrations, `GOVERNANCE.md`, `docs/ANALYTICS_CONTRIBUTING.md`, `docs/protocol/`), it wins over a catalog agent. Where a doc *describes* the code and the code disagrees, the code wins and the doc gets fixed. As of October 2026, `.claude/skills/terraviz-data-video/references/data-encoded-contract.md` §6 says the colorbar files sit on an unmerged branch (they're on `main`), `docs/ZYRA_INTEGRATION_PLAN.md` still says "No code, no migrations", and `AGENTS.md` still names the GitLab remote.

## Routing: Which Agent for Which Change

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `functions/api/v1/_lib/dataset-serializer.ts` (`WireDataset`) and any type it reaches (`src/types/color-scale.ts`), the SPA's inbound copy in `src/services/dataService.ts`, `functions/api/v1/catalog.ts`, `functions/api/v1/_lib/catalog-store.ts`, `functions/.well-known/**`, `public/schema/v1/**`, `docs/protocol/**`, `docs/CATALOG_FEDERATION_PROTOCOL.md`, `scripts/build-protocol-schemas.ts`, node identity (`scripts/gen-node-key.ts`, `functions/api/v1/publish/node-identity.ts`, `cli/init-node.ts`), `docs/EMBED_URL_GRAMMAR.md` and its readers (`src/utils/{embedMode,catalogMode,posterDeepLinks}.ts`, `src/services/deepLinkService.ts`) | TerraViz Federation Reviewer | Other nodes, the plugin, and embedding pages read what ships. `check:protocol-schemas` passes on a rename once the schema is regenerated, and never sees a change of meaning |
| `src/types/color-scale.ts`, `src/services/colorScaleDisplay.ts`, `src/ui/colorbarUI.ts`, `src/ui/analyzeCharts.ts`, palette handling in `cli/zyra-publish-from-dispatch.ts` and `src/ui/publisher/workflow-templates.ts`, `poster/**` figures | Scientific Visualization Reviewer | A wrong range or stop changes what every pixel claims |
| Dataset text (`src/ui/publisher/components/dataset-form.ts`), tours (`src/ui/tourAuthoring/`), Orbit's prompt (`src/services/docentContext.ts`), English strings (`locales/en.json`), `poster/**` text | Science Communicator | The words visitors read beside the data |
| `src/ui/**`, `src/styles/**`, `tokens/**`, `STYLE_GUIDE.md` | Section 508 Accessibility Specialist | Every new panel is a new barrier or not, and contrast starts in the tokens |
| `src/services/hlsService.ts`, `cli/transcode-from-dispatch.ts`, `src/output/datasetMirror.ts`, `.github/workflows/transcode-hls.yml` | Video Streaming Engineer | Rendition choice and decode cost decide whether a sphere keeps up |
| `src/services/mapRenderer.ts`, `src/services/earthTileLayer.ts`, `src/services/tilePreloader.ts`, `src/services/photorealEarth.ts` | Web GIS Developer | Tile, projection, and layer bugs show up as the wrong place on Earth |
| `src/i18n/`, non-English `locales/`, CSS that could break RTL | Internationalization Engineer | Strings and layout for every shipped language |
| `functions/api/v1/publish/**`, `src/types/publisher-roles.ts`, `functions/api/v1/_lib/{access-auth,preview-token}.ts`, `wrangler.toml`, `public/_headers`, `.github/workflows/**` not routed elsewhere | Application Security Engineer | Write paths, roles, tokens, and CI secrets. Third-party actions are pinned by tag, not SHA |
| `functions/api/chat/**`, `functions/api/models.ts`, `functions/api/_lib/workers-ai-*.ts`, `functions/api/v1/_lib/{blog-generate,events-enrich,event-tour}.ts`, `src/services/{llmProvider,docentService,docentEngine,docentAnalysisTools,appleIntelligenceProvider}.ts`, any new `import.meta.env.VITE_*` | AI-Generated Code Security Auditor | Where outside text meets a model. `CONTRIBUTING.md` §LLM Integrations rule 4: external content is data, never instructions |
| `src-tauri/**`, `src/services/multiOutput/**`, `src/services/windowChrome.ts`, `.github/workflows/{release,desktop}.yml` | Desktop App Engineer | Capabilities, messaging between windows, signing, and the updater are where a desktop app's security lives |
| `src/output/projectorWarp.ts`, `src/services/multiOutput/{warpImport,storedZip,warpStorage}.ts`, `src/ui/outputWarpUI.ts` | Code Reviewer, and check sphere-sim | The warp math reads sphere-sim's bundle (`sphere-sim/projector-layout@1`). No catalog agent reviews projector optics |
| `src/services/voiceCloudEngines.ts`, `src/services/voiceWsStreaming.ts`, `functions/api/voice/`, `src/services/llmProvider.ts`, `functions/api/feedback*.ts`, `functions/api/general-feedback*.ts`, `functions/api/_feedback-helpers.ts`, `functions/api/_standalone-feedback.ts`, `functions/api/v1/publish/{feedback,analytics,analytics-export}.ts`, `src/ui/publisher/pages/users.ts`, `docs/PRIVACY.md` | Privacy Engineer | Audio, chat, feedback, exports, and accounts leave the browser here. Telemetry ingest is the analytics reviewer's |
| `functions/api/v1/publish/**` request or response shapes, `src/ui/orbitPostMessageBridge.ts`, `functions/api/v1/stac/**`, `functions/schema/stac/**` | API Platform Engineer, and check the plugin | The plugin calls the publish API, which `docs/WORDPRESS_EVENTS_FEEDS_SYNC.md` §6 calls "internal / unversioned in practice". The STAC extension schema is served immutable, so a new `ColorScale` field can invalidate it |
| `migrations/**`, `schema/catalog-schema.sql` | Code Reviewer, migration first | CI applies migrations to the remote D1 on every push to `main`. `check:migrations` only checks that they're additive |
| `.github/workflows/zyra-run.yml` (the Zyra image digest), `src/types/zyra-workflow-constants.ts`, `src/types/zyra-pipeline-args.ts`, `functions/api/v1/_lib/workflow-validators.ts`, the curated templates (`src/ui/publisher/workflow-templates.ts`, `docs/DATASET_SOURCE_PRESETS_DRAFT.md`, `.claude/skills/terraviz-data-video/assets/**`) | Zyra Workflow Author, then the Code Reviewer for code | The pinned image decides which flags and stages exist, and `/validate` doesn't check argument names, so a template can pass every TerraViz test and fail Zyra's parser on the runner. Re-prove every template against the new version before the pin moves. See the [Zyra runbook](scenario-zyra.md) |
| `docs/metadata/**`, `functions/api/v1/_lib/metadata-{policy,readiness}.ts`, `functions/api/v1/publish/stac-{lineage,report}.ts`, `cli/metadata-audit.ts`, `scripts/audit-stac.ts`, `CITATION.cff` | Scientific Data Steward | What a dataset record says about its source, license, version, and lineage, and whether its citation resolves |
| `docs/SELF_HOSTING.md`, `docs/MULTI_MONITOR_OPERATIONS.md`, `docs/MACOS_INSTALL.md`, `CONTRIBUTING-TRANSLATIONS.md` | Technical Writer | Read by operators and translators, not the maintainer |
| Any other code or config under `src/`, `functions/`, `cli/`, `src-tauri/`, `scripts/`, `public/`, `tokens/`, or `schema/` | Code Reviewer | No row above matches, and every code change gets a second reviewer |
| A blog post or event pairing about to go live, or a change to Orbit's system prompt | Communications Clearance Officer | A NOAA node, and the assistant on it, speak for the agency |
| A post or pairing about an active hurricane, flood, fire-weather, or other hazard | Meteorologist, then the Clearance Officer | Official warnings come first; a globe post must not contradict them |
| A hosting move onto federal infrastructure | FedRAMP & RMF Compliance Engineer | Authorization paperwork, before the move, not after |
| Telemetry | `analytics-reviewer` (repo) | Privacy invariants |

Every code change gets one catalog reviewer: a specialist when a row matches, otherwise the Code Reviewer. Few need more than two. A plan-doc change needs none.

**High-scrutiny paths get two.** `GOVERNANCE.md` names five areas: `functions/api/v1/publish/**`, the analytics ingest path, authentication and Access configuration, D1 migrations, and federation identity and signing. A change there gets its specialist plus the Code Reviewer, and the PR says that no human outside the original loop has reviewed it yet.

## Companion Repo: the WordPress Plugin

The plugin is a separate PHP repo (WordPress 6.1+, PHP 7.4+). About 83% of its shipped code is the publisher half: about 35 REST routes that proxy a node's publish API with one shared Access service token. It isn't on WordPress.org yet. It rides in this runbook rather than its own because it is about an eighth of TerraViz's size, changes in bursts, has the same maintainer and rules, and needs no agent TerraViz doesn't already have except one. Split it out if it gets a WordPress.org listing, outside contributors, or a second maintainer.

The plugin has no `.claude/` directory. Its CI already enforces the WordPress-specific rules: PHPCS with the WordPress ruleset and PHPCompatibilityWP, PHPUnit on PHP 7.4 and 8.2, and a blocking Semgrep scan. **Its `CLAUDE.md` is stale:** it says the plugin has no publish path, but the publisher half shipped. Its rules (no phone-home, one render path, never hand-edit `src/Contract/*`) still hold.

Paths below are in the plugin repo.

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `src/Rest/**`, `src/Api/PublishClient.php`, `src/Support/{Capabilities,Credential,Crypto,Options}.php`, `src/Settings.php`, `src/{Blog,Events}/Sync.php`, `src/Oembed.php`, the origin logic in `src/Embed/Renderer.php`, `blocks/admin/{api,safeUrl,upload}.js`, `.github/workflows/**` | Application Security Engineer | Capabilities, the shared service token, which origins an author can embed, and a workflow that holds a write token |
| `src/{Blog,Events}/Sync.php`, `blocks/admin/{Analytics,Feedback}.js` and their folders, the load modes in `assets/js/frontend.js`, the "External services" section of `readme.txt` | Privacy Engineer | WordPress posts, visitor feedback, and analytics cross to the node, and third-party thumbnails load in the visitor's browser |
| Markup in `src/Embed/Renderer.php`, `assets/**`, `blocks/**`, markup in `src/Settings.php` | Section 508 Accessibility Specialist | NOAA-GSL's WordPress site is federal web content |
| `src/Api/{Client,Catalog}.php`, image markup in `src/Embed/Renderer.php`, asset registration in `src/Plugin.php`, `assets/**` | WordPress Performance Engineer | On a cold cache, page render waits on a fetch with a five-second timeout, and the poster image is lazy-loaded even when it's the largest image on the page |
| `src/Contract/**`, `bin/generate-contracts.php`, `src/Embed/UrlBuilder.php` | TerraViz Federation Reviewer | The consumer side of the wire schemas and the embed grammar. Regenerate, never hand-edit. As of October 2026 the generated contract lags three fields |
| The endpoint list in `src/Api/PublishClient.php` | API Platform Engineer | The consumer side of the publish API |
| `readme.txt`, `README.md`, `docs/RELEASING.md` | Technical Writer | `readme.txt`'s feature list and changelog are behind the code |
| Any other code in `src/`, `blocks/`, `assets/`, `bin/`, `terraviz.php`, `uninstall.php` | Code Reviewer | No row above matches |

**Changes in TerraViz that need a plugin check.** The plugin's smoke test covers only `/api/v1/catalog` and `/api/v1/datasets/:id`. So when a TerraViz change touches `functions/api/v1/publish/**` shapes, `docs/EMBED_URL_GRAMMAR.md`, or `public/schema/v1/**`, check the plugin's `src/Api/PublishClient.php`, `src/Embed/UrlBuilder.php`, and regenerate `src/Contract/*` in the same week.

## Per-Change Sequence (NEXUS-Micro)

```
Step 1: Route
├── List what changed: git diff origin/main...HEAD --stat
└── Pick agents from the routing table. Code with no match goes to the Code Reviewer.
    High-scrutiny paths get two.

Step 2: Repo reviewers first
└── analytics-reviewer, if telemetry changed. Its blocking conditions are the project's own.

Step 3: Catalog reviewers, in parallel
├── Give each one the diff and what it needs to see
│   (the viz reviewer gets screenshots from
│    npm run screenshots:report -- --scene <name>)
└── Each reports findings with file:line. None edits files.

Step 4: Maintainer decides
├── Fix, accept, or record why not
└── CI gates still run: the type-check chain (including check:protocol-schemas
    and check:migrations) and the smoke job (screenshots:smoke). The visual
    report and its axe pass are advisory, not gates
```

### Activation prompt

```
Review this TerraViz change as the [Agent]. Read the diff
(git diff origin/main...HEAD -- [paths]) and [screenshots / dataset text / route file].
Report findings with file:line, most important first. Do not edit files.
Where the repo's own docs set a rule (CLAUDE.md, CONTRIBUTING.md, GOVERNANCE.md,
docs/ANALYTICS_CONTRIBUTING.md, docs/protocol/), the repo doc wins. Where a doc
describes the code and the code disagrees, report the mismatch.
```

## Cross-Repo Contracts

| Contract | TerraViz side | Other side |
|----------|---------------|------------|
| Zyra runner and data-encoded video | `.github/workflows/zyra-run.yml` (image digest), `src/types/zyra-workflow-constants.ts`, `src/types/zyra-pipeline-args.ts`, `src/types/color-scale.ts`, `migrations/catalog/0042_render_encoding.sql` | Zyra's CLI and `visualization/luma_writer.py`. See the [Zyra runbook](scenario-zyra.md) |
| Projector warp bundle | `src/services/multiOutput/{warpImport,storedZip,warpStorage}.ts`, `src/output/projectorWarp.ts`, fixtures in `src/output/fixtures/projectorWarp/` | sphere-sim's `packages/web/src/bundle.ts` (`sphere-sim/projector-layout@1`). See the [sphere-sim runbook](scenario-sphere-sim.md) |
| Federation wire, embed grammar, publish API | `public/schema/v1/**`, `docs/EMBED_URL_GRAMMAR.md`, `functions/api/v1/publish/**` | Other nodes, embedding pages, and the WordPress plugin (above) |

## Maintainer Succession (quarterly)

Run the Codebase Onboarding Engineer once per candidate area that `MAINTAINERS.md` lists: **backend and catalog** (now including the STAC and metadata-history work), **globe and rendering**, and **workflows and operations**. Each run produces a guide a newcomer could start from, grounded in the code rather than the plan docs. Give it a `graphify` map of the area. Refresh a guide when its area has changed since the last run.

This is the only part of the team aimed at the project's largest risk, and no agent fixes that risk by itself. The guides lower the cost of saying yes for a second maintainer. `MAINTAINERS.md` prefers a non-federal one, so the guides should assume no NOAA context.

Run the Codebase Archaeologist in the same quarter. Its drift registry is the list of docs a newcomer shouldn't trust yet.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge | Maintainer |
| A breaking wire change or `schema_version` bump | Maintainer, after the TerraViz Federation Reviewer escalates |
| A change to the publish API's shape | Maintainer, together with the matching plugin change |
| Publishing a blog post or event pairing | Maintainer, after clearance |
| Adding a maintainer | Maintainer. `GOVERNANCE.md` is still a draft, not yet adopted |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer. NEXUS handoffs cost more than they save at this size |
| Frontend Developer, Backend Architect | Builders, and Claude Code already builds. The Frontend Developer assumes a framework TerraViz doesn't use. The Backend Architect belongs in a Phase 4 build team |
| API Tester | The routes ship with their own tests |
| Git Workflow Master | CLAUDE.md already sets the git rules: DCO sign-off, one logical change per commit |
| Rust Refactoring Specialist | The desktop shell is small: about 1,400 lines of Rust and 230 of Swift (October 2026) |
| Database Reliability Engineer, Database Optimizer | Built for Postgres and MySQL replication and tuning. D1 is SQLite at the edge; the migration row goes to the Code Reviewer |
| USWDS Developer | No federal design system is in use. If a NOAA node goes live on a `.gov` domain, check the federal website standards that apply then; the banner is a one-time task |
| CMS Developer, WordPress Shopping Cart Engineer | A theme and site builder (with a PHP 8.1 floor the plugin doesn't share), and WooCommerce. The plugin's CI enforces the WordPress coding rules |
| Secrets & Credential Engineer | AppSec covers the Access service tokens and the plugin's shared token. Call it for a leak or a rotation |
| XR Immersive Developer, Voice AI Integration Engineer, Performance Benchmarker | Too thin, or built for a different job: transcription pipelines, generic load testing. The output HUD already measures frame pacing. The VR subsystem (about 10,000 lines) stays with the Code Reviewer |
| Accessibility Auditor | Overlaps the 508 specialist |
| Persona Walkthrough | Built for conversion-rate audits, the wrong lens for a museum operator |
| Marketing and growth | Not this team's job. Public text still goes through the Science Communicator and the Clearance Officer |

## Success Criteria

| Metric | Target |
|--------|--------|
| Routed changes reviewed | Every PR that touches a routed path names the reviewer that ran |
| High-scrutiny changes | Every one names two reviewers |
| Review cost | 1–2 catalog agents on a typical code change |
| Onboarding guides | One per candidate area, refreshed each quarter the area changed |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| Running every agent on every PR | Route by path. Most code changes need one reviewer |
| Treating the Code Reviewer's pass as independent | It shares the authoring model's blind spots. On risky changes, a human or different-model review still counts for more |
| A catalog reviewer contradicts a repo doc | A rule in a repo doc wins. A description in a repo doc loses to the code. Record the disagreement if it's worth a doc change |
| The viz reviewer gets code without pictures | Hand it screenshots from the visual report |
| Clearance after a post is live | Clear before publishing |
| A publish-API change breaks the plugin silently | The plugin's smoke test doesn't cover the publish routes. Check the plugin in the same week |
| Treating the team as the second maintainer | It reviews. It can't hold the project when the maintainer is away |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' terraviz > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt
```

The repo agents in `.claude/agents/` come with a TerraViz checkout and need no install.
