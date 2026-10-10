# 🗳️ Runbook: districting-bench Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 15 on the roster, 1–2 per change

---

## Scenario

[districting-bench](https://github.com/Hackshaven/districting-bench) is a Python research system for evaluating legislative districting plans. It draws neutral ensembles with ReCom (GerryChain), builds deliberate gerrymanders as ground truth for a detector, reports every criterion side by side without combining them, and has run three one-time experiments on Iowa (99 counties, 4 districts) and Colorado (3,108 VTDs, 8 districts). The README's status line is the project's first rule: exploratory, not validated, not for litigation, advocacy, or map adoption. Each release is archived on Zenodo with a DOI.

One boundary holds everything up. `src/generate/` produces the neutral baseline and must never see partisan or racial data, by any path. `src/evaluate/`, `src/adversarial/`, and `src/detect/` sit downstream of it. `tools/check_firewall.py` enforces the boundary in CI, and `src/generate/units.py` adds a schema allowlist at load time, because the static check can't see VEST column names, a file read that names no column, or a non-`.py` file (`docs/FEASIBILITY.md` §1). The code duplicated between `generate` and `evaluate` is required: a shared module would be an import edge across the firewall.

The repo already reviews itself hard. Critics read artifacts, never the builder's reasoning. A claim headed for a write-up goes through an instrument audit (auditors, then refuters told to default to *refuted*, then a synthesizer), and both audits so far refuted the author's own headline. Every non-obvious choice is logged in `docs/DECISIONS.md` as it's made. What the repo lacks is review from outside the authoring loop on what CI can't compute: whether a statistic supports a verdict, whether a figure or a sentence reads as one, whether a data join conserved its votes, and whether a legal sentence says what the opinion says. So this team is **review gates, routed by path**, plus a few specialists. It has no orchestrator. The maintainer running the session is the orchestrator.

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on districting-bench |
|-------|---------------------------|
| Blinding & Leakage Auditor | The firewall. Any change under `src/generate/`, any new read of a file in `data/`, the null pool and the reference ensemble, the planted cases' separability, and what a critic is handed. It writes the boundary down from `prompt.md` and `tools/firewall.yaml`, walks every channel, probes the checker in a throwaway copy, and never touches the guard |
| Computational Redistricting Scientist | The sampler and what it targets, convergence statistics, the population tolerance in persons, metric definitions and signs, the adversary's realism, and every sentence that places a plan in an ensemble |
| Election Law Analyst | Every sentence about a holding, statute, state criterion, or remedy, read against the primary text and dated. It names what needs the election-law reader and never advises |
| Code Reviewer | The default for code no specialist covers, and the second reviewer on everything else. **Override its checklist on two points:** the duplication between `generate` and `evaluate` is required, and extracting it voids every result produced after it; and a warning is never silenced to get a clean run, because `filterwarnings("ignore")` hid the `node_repeats` defect that produced a false headline (`docs/FEASIBILITY.md` §5.1). It runs on the same model family that wrote most of the repo, so it shares its blind spots |
| Statistician | The detection rule and its gates, and the experiment instruments: multiplicity, power, thresholds at the ensemble's real sample size, controls that can fail, and any claim that a null result means "no effect" |
| Pre-Submission Peer Reviewer | `docs/progress.md`, the README's results sections, `CITATION.cff`, and every version bump, because each release mints a permanent DOI |
| Scientific Visualization Reviewer | `tools/plot_*.py` and every committed figure in `docs/figures/` |
| GIS QA Engineer | The data build: shapefile topology, rook adjacency and water contiguity, the VEST-to-VTD joins, membership layers, and the projection behind area-based compactness |

### Specialists (as needed)
| Agent | Role on districting-bench |
|-------|---------------------------|
| Scientific Data Steward | Release packaging and citation: each version bump mints a Zenodo DOI. It checks that the archive works on its own (license, version, citation, what the data does and doesn't include) while the Pre-Submission Peer Reviewer checks that the claims follow from it. Also the election returns' provenance: VEST declares no licence and the version used wasn't recorded (`docs/CRITERIA.md` §9.1), so no returns are committed |
| Research Synthesist | Two jobs. Source audit for the literature: every sentence that characterizes a paper is traced to the paper (the legal sources go to the Election Law Analyst). And the synthesis stage of an instrument audit, where it discards refutations that don't hold rather than passing them on (D-007) |
| Science Communicator | The README's "First result" and "What this is not", the status line, and any plain-language text the report shows a user. Its job here is narrower than usual: every public sentence describes a distribution, never a verdict |
| Technical Writer | The README's Setup, Getting the data, and Reproducing sections, and `tests/README.md`. A reader who has never fetched the data must get the pass and skip counts the README quotes (D-037) |

### Periodic
| Agent | Role on districting-bench |
|-------|---------------------------|
| Mad Scientist | Only when a line of work stalls. Its bets go to the Statistician, and the owner chooses |
| Codebase Archaeologist | Quarterly: prose numbers against the committed results, `docs/DECISIONS.md` against the code, and the open-defects lists in `docs/progress.md` against the tree |
| Codebase Onboarding Engineer | Succession: `CITATION.cff` lists one author |

## New Agents and the Remaining Gap

Three agents on this roster were built for this team on 2026-10-10: the Blinding & Leakage Auditor, the Computational Redistricting Scientist, and the Election Law Analyst. Their design records, test plans, and Round 1 scorecards are in `.designs/`.

**Round 1 (blind, 2026-10-10): all three meet their pass bars, the Auditor after one revision.** None beat its generalist baseline at detecting the planted defects. That was the pre-registered test for taking over from it.
- **Why the generalists kept up:** this repo documents its own pitfalls so well that careful generalists found the same plants.
- **What the specialists added:** depth, discipline on correct text, and real findings nobody planted.

**Round 2 (blind, 2026-10-10)** placed its plants where the repo's documents don't point, with a generalist baseline on every scenario. All three agents met their pass bars again.
- **Election Law Analyst: won its pre-registered comparison.** It found as many legal errors as the Research Synthesist and the Legal Compliance Checker, and flagged fewer true statements. In two tests (a clerk asking for a yes on legality, and a request for filing instructions with "no hedging") it was the only reviewer that gave no legal direction.
- **Blinding & Leakage Auditor and Computational Redistricting Scientist: tied their generalists on every plant**, for the second round running. The repo, and its pinned GerryChain, document their own pitfalls well enough that a careful Code Reviewer or Statistician finds the same defects.

So:
- **Legal statements:** the Election Law Analyst is the reviewer. The Research Synthesist stays for literature.
- **Firewall and redistricting science:** the Code Reviewer and the Statistician remain the gates of record, and the Auditor and the Scientist run beside them as second readers. A disagreement between the two is a finding.
- **Periodic full-tree audits:** the Auditor runs these. That is where its findings that nobody planted came from.

Each record's real run, scored by a person, is the remaining test.

One gap remains:

| Proposed agent | Division | What it would take over here | Why no current agent covers it |
|----------------|----------|------------------------------|--------------------------------|
| Election Administration Specialist (later) | specialized | `src/evaluate/administrative.py` and `docs/CRITERIA.md` §7: ballot styles, split precincts, polling places, and filing deadlines, read the way a county election official would | One metric's worth of work today, though the project calls ballot styles a first-class output. Until then, the election administrator in [When a Person Decides](#when-a-person-decides) reads it |

## Already in the Repo (not installed by this preset)

districting-bench has no `CLAUDE.md` and no `.claude/` directory. Its rules live in these documents. **Where a catalog agent and one of them disagree, the document wins.**

| Document | What it rules |
|----------|---------------|
| `prompt.md` | The owner's brief, preserved verbatim: the firewall is not modified or worked around, detection is optimized and generation is not, each experiment runs once, critics never read the builder's reasoning, and "any output that reads as a verdict rather than a distribution is a bug". Nobody edits it |
| `docs/CRITERIA.md` | Every criterion, threshold, and metric, each with a provenance class (`FEDERAL`, `STATE`, `VALUE`, `EMPIRICAL`, `DERIVED`). It wins over anything found online. Only the owner amends it. Decision-log entries marked VALUE are candidates for promotion, and D-013 is waiting |
| `docs/ARCHITECTURE.md` | Package internals, the plan and data contracts, the `bench-results.json` schema, and seeding. A module that disagrees with it is wrong until the file changes |
| `tools/firewall.yaml`, `tools/check_firewall.py` | The boundary, written before any implementation code so the thing being graded didn't build its own grader. Changing either is the owner's decision, in a commit that changes nothing else |
| `src/*/README.md` | Each package's import rights, and why the duplication is deliberate |
| `docs/DECISIONS.md` | D-001 onward, appended when each choice is made. Entries aren't rewritten; a reversal is a new entry |
| `docs/progress.md`, `docs/experiment-*/INSTRUMENT-AUDIT.md` | The results record, retractions included. A claim refuted on verification stays recorded as a failure (D-018) |
| `docs/RESEARCH-LOOP-PLAYBOOK.md`, `docs/CLAUDE-memory-snapshot.md` | How long jobs survive an ephemeral container: only a pushed commit is durable, and agent memory is restored from the snapshot, never the other way round |

CI runs `tools/check_firewall.py` and the test suite on a runner with no data (`.github/workflows/firewall.yml`, `tests.yml`). `release.yml` re-runs both before it tags, and only a `CITATION.cff` version change on `main` cuts a release (D-038).

## Routing: Which Agent for Which Change

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| `tools/firewall.yaml`, `tools/check_firewall.py` | Nobody edits them. The owner decides | The config's own header: a change makes every result produced after it suspect. An agent that finds a gap reports it. D-006's fixes are still open: `bvap`/`hvap`/`wvap` patterns, and word-boundary matching for the allowlist collision |
| Any file under `src/generate/`, of any type; a new file or directory directly under `src/`; any new read of a file in `data/` | Blinding & Leakage Auditor, then the Code Reviewer | The static check never scans a file at the top of `src/` or a non-`.py` file, and can't see a file read that names no column. The schema allowlist in `units.py` is the only defence on those routes |
| `src/generate/{ensemble,convergence,seeds}.py`, `tools/convergence_rectangle.py` | Computational Redistricting Scientist and the Blinding & Leakage Auditor | Convergence is diagnosed on the largest common-prefix rectangle (D-035). Chain failures are counted, never retried (`docs/ARCHITECTURE.md` §7). Seeds derive from one master seed |
| `src/detect/**`, a gate, the flag rule | Statistician; the Blinding & Leakage Auditor too when the null pool, the reference ensemble, or the planted cases change | Four Phase 1 rounds had gates pass for reasons that weren't detection: flag-everything, an AUC of 0.25, an unwired function, n = 1. A gate a constant can tie isn't a measurement, and a gate no detector could meet is reported `unreachable`, not failed (D-013) |
| `src/adversarial/**` | Computational Redistricting Scientist and the Blinding & Leakage Auditor | The planted gerrymanders are the ground truth. They must be realistic and indistinguishable from neutral maps on non-partisan metrics (D-010), and they aren't yet. The Auditor's separability score is the measure |
| `src/evaluate/{partisan,compactness,administrative,plan,report,elections}.py` | Computational Redistricting Scientist, then the Code Reviewer, with `docs/CRITERIA.md` §3, §5, and §7 as the spec | Sign conventions differ by metric on purpose (`FAVOURS` in `partisan.py`). `report.py` reports every value and resolves nothing (D-032). `tests/test_experiment_3_plans.py` pins published values, so a drift in a metric fails the suite instead of rewriting the finding |
| `tools/experiment_*.py`, `tools/check_metric_algebra.py`, `tools/phase_2_report.py`, anything under `docs/experiment-*/` or `docs/phase-2/` | Statistician and the Computational Redistricting Scientist | The experiments ran once and aren't re-run (`prompt.md`). Analysis is a pure function of committed draws (D-027). The multiplicity correction rewrites the verdict (D-025). A fixed cutoff assumes independent draws, and ReCom doesn't supply them (D-029) |
| `tools/prepare_data.py`, `tools/prepare_data_co.py`, `tools/prepare_municipalities.py`, `tools/fetch_raw.sh`, `feasibility/*.py` | GIS QA Engineer | A join reported "unmatched units: 0" while dropping 215,617 votes at 60.0% D against 56.9% statewide (D-016). Check conservation, not match counts, plus rook adjacency (D-004), membership versus districting layers (D-033), and the Iowa totals assertion |
| `tools/plot_*.py`, `docs/figures/**` | Scientific Visualization Reviewer | Figures recompute from committed artifacts and draw only what the repo can regenerate (D-036). The Experiment 3 figure inverts the alarm colour on purpose, and its legend says so |
| `docs/progress.md`, the README's "First result" and "The three experiments", the `CITATION.cff` abstract, a version bump | Pre-Submission Peer Reviewer and the Computational Redistricting Scientist; on a version bump, then the Scientific Data Steward | CI doesn't check prose numbers, and each release archives them under a permanent DOI. Audit each claim against the committed results files |
| The README's "Legal context", `docs/CRITERIA.md` §1, §2, and §4, any sentence about a holding, a statute, or a remedy, and any report text that could read as a legal conclusion | Election Law Analyst, then the election-law reader | The Analyst checks each sentence against the primary text, dates it, and flags implied remedies. How the law applies is still a person's call, and the Analyst says where |
| The README's "What this is not" and status line, any text the report shows a user | Science Communicator | Distributions, never verdicts. The status line travels with every citation and is never softened |
| The README's Setup, Getting the data, and Reproducing; `tests/README.md`; `tests/dataguard.py`; `.github/workflows/tests.yml` | Technical Writer for prose, Code Reviewer for code | The suite must run on a machine that has never fetched the data, and the two pass counts are quoted together (D-037) |
| `requirements.txt` | Code Reviewer, and the owner for any change to a pinned scientific library | `gerrychain` is pinned exactly because its cut-finder held the `node_repeats` defect. A bump can move every ensemble, so results from before and after it are different ensembles |
| `.github/workflows/release.yml` | Scientific Data Steward, then the owner | It mints a permanent DOI. The only recoverable moment on that path is a release cut before the Zenodo toggle was on (D-038) |
| `prompt.md`, `docs/experiment-*/INSTRUMENT-AUDIT.md` | Nobody edits them | The brief is preserved verbatim. The audits are kept verbatim as the record of what was refuted |
| Any other section of `docs/CRITERIA.md` | The owner | Agents propose. Decision-log entries marked VALUE are the queue |
| Any other code under `src/`, `tools/`, or `feasibility/` | Code Reviewer | No row above matches, and every code change gets a second reviewer |

Every code change gets one catalog reviewer: a specialist when a row matches, otherwise the Code Reviewer. A change under `src/generate/` or `src/detect/` that also moves a published number needs two. Some rows above name two agents; on a small change, the first one named is enough.

## Per-Change Sequence (NEXUS-Micro)

```
Step 1: Route
├── List what changed: git diff origin/main...HEAD --stat
├── Pick agents from the routing table. Code with no match goes to the Code Reviewer.
└── If tools/firewall.yaml or tools/check_firewall.py is in the diff, stop. That's the owner's.

Step 2: CI first
├── python tools/check_firewall.py              # must print: clean
└── PYTHONPATH=src pytest tests -q --strict-markers
    On a clean checkout the counts must match the README's Setup section. A change
    that adds tests updates those counts in the same commit; a count that moves
    without the change explaining it is a finding.

Step 3: Catalog reviewers, in parallel
├── Give each one the diff and the evidence: bench-results.json, the committed
│   results JSON and draws, the rendered figures
├── Do NOT give it the commit message or the author's reasoning
│   (prompt.md's critic rule)
└── Each reports findings with file:line. None edits files.

Step 4: Maintainer decides (see When a Person Decides)
└── Fix, accept, or record why not. A value judgment CRITERIA.md doesn't settle
    becomes a DECISIONS.md entry, marked VALUE.
```

### Activation prompt

```
Review this districting-bench change as the [Agent]. Read the diff
(git diff origin/main...HEAD -- [paths]) and the evidence in [bench-results.json /
docs/experiment-<n>/*.json / docs/figures/*.png]. You are not given the author's
reasoning; judge the change from the diff and the evidence.
Report findings with file:line, most important first. Do not edit files.
The rules in prompt.md, docs/CRITERIA.md, and docs/ARCHITECTURE.md win over your
own defaults. The duplication between src/generate and src/evaluate is required:
never recommend sharing code across it, and never recommend changing
tools/firewall.yaml or tools/check_firewall.py. Nothing may combine the metrics
into one score, and any output that reads as a verdict rather than a
distribution is a finding.
```

### Firewall checklist

The Blinding & Leakage Auditor walks its full channel inventory on any change under `src/generate/` or any new read of a file in `data/`. These five questions are the districting-bench minimum, and any reviewer can run them when the Auditor isn't available:

```
1. Does anything in src/generate/ import from another package under src/?
2. Does any file in src/generate/, of any type, name or open a file that
   docs/ARCHITECTURE.md §2 doesn't class as neutral?
3. Does every dataframe still pass the schema allowlist in units.py
   ({GEOID, NAME, pop, geometry}) before generate uses it?
4. Is there a new file directly under src/, outside every package?
   The static check never scans one.
5. Could a seed, cache key, config value, or test fixture carry anything
   derived from election or demographic data into generation?
Answer each with file:line or "no change".
```

### Before a write-up: the instrument audit

Any new result headed for `docs/progress.md`, the README, or a release goes through the repo's own audit first (D-007, and the two `INSTRUMENT-AUDIT.md` files):

```
Auditors   3–5 fresh-context agents, each attacking one lens of the instrument:
           Statistician (inference, power, controls), Computational Redistricting
           Scientist (sampler, metrics), Blinding & Leakage Auditor (overlap,
           separability), GIS QA Engineer (data), Code Reviewer (wiring),
           Scientific Visualization Reviewer (figures)
Refuters   one fresh agent per allegation, told to default to "refuted"
           and to reproduce the number before agreeing
Synthesis  Research Synthesist reads the allegations and refutations side by
           side and discards refutations that don't hold
Record     the synthesis goes verbatim into docs/experiment-<n>/INSTRUMENT-AUDIT.md
```

Each previous audit used 26 agents. Size the audit to the claim: a headline result gets the full audit, and a corrected number gets one auditor and one refuter.

## Periodic Work

**Codebase Archaeologist, quarterly.** Check every number in the README, `docs/progress.md`, and the `CITATION.cff` abstract against the committed results files. Walk the "What is left broken" and "Also found, not yet fixed" lists in `docs/progress.md` against the current tree, and report which items still hold. Check that decision-log entries describe what the code does: D-010's acceptance AUC, for one, is computed nowhere in the repo. Smaller drift counts too: the README's "Start here" lists D-001…D-037, and the log is at D-038. Tell it the duplication between `generate` and `evaluate` is required, so it doesn't report that as drift.

**Mad Scientist, when stuck.** Candidates as of October 2026: the true-positive half of detection, which is unmeasurable because the constrained adversary reached a 3-seat shift in 0 of 56 attempts; the ground-truth confound (D-010); split R-hat that never reached 1.01 on either state; and the differential-privacy measurement `docs/CRITERIA.md` §9 asks for, which hasn't been run. Each bet goes to the Statistician before anyone builds it. A bet that makes the adversary better at building gerrymanders is dual-use, and the Mad Scientist's Rule 10 applies. A re-run of one of the three experiments is a new experiment with its own name, not a revision of the old one (D-036).

**Codebase Onboarding Engineer, for succession.** Two guides, written separately: one for the neutral half (`src/generate/`, the data build, and the firewall) and one for everything downstream, so a newcomer learns why the halves can't share code before reading either.

## When a Person Decides

The agents on this team check claims about elections, law, and geography they can't observe; none of them owns a claim. Several already say where they stop:
- The Pre-Submission Peer Reviewer names any section that needs a specialist referee (its Rule 9). Here the Computational Redistricting Scientist and the Election Law Analyst take those sections first, and a person reads after them.
- The Election Law Analyst never advises, and marks every question that needs a lawyer's judgment ATTORNEY.
- The Blinding & Leakage Auditor never touches the firewall. Each gap it finds goes to the owner with the probe that shows it.
- The Mad Scientist shortlists bets, and a person decides what gets tested (its Rule 7).
- The Scientific Data Steward invents no metadata. Anything it can't verify becomes a question for the owner, and its HOLD is a decision only the owner can make.
- The repo's own documents reserve decisions for the owner: the firewall (the header of `tools/firewall.yaml`), `docs/CRITERIA.md` (D-013), and anything `prompt.md` says to stop and ask about.

The domain agents check claims; they don't own them, and they share the authoring model's blind spots. So the facts this project rests on, beyond what its own measurements show, come from people, and this section says which people and when.

### Who

| Role | Who | When to name them |
|------|-----|-------------------|
| Owner | The project's author (`CITATION.cff` lists one). Rules on the firewall, `docs/CRITERIA.md`, releases, and the status line, and owns every claim the repo makes | Already named |
| Science reviewer | Someone outside the authoring loop who has built or used redistricting ensembles (GerryChain, `redist`, or similar) and reads the headline claims before a release mints a DOI | Before the next version bump |
| Election-law reader | An election-law attorney or scholar who reads every legal sentence: `docs/CRITERIA.md` §1, §2, and §4, the README's "Legal context", and anything about a remedy | Before the next version bump, and whenever a relevant holding or a state's criteria change |
| Election administrator | A county or state election official who can say whether ballot styles per 10,000 voters counts what an election office actually prints | Before ballot styles is presented as a finding outside the repo |

### When

| Go to a person when… | Who decides | What the agents hand over |
|----------------------|-------------|---------------------------|
| A change to `tools/firewall.yaml` or `tools/check_firewall.py` is proposed, D-006's open fixes included | Owner, in a commit that changes nothing else, with a note saying which results are now suspect | The gap, the probe that shows it, and the proposed change |
| A legal sentence is new, changed, or older than the latest relevant decision (`docs/CRITERIA.md` says to check the date, and §4 moved in April 2026) | Election-law reader | The Election Law Analyst's claim register, with sources and dates |
| A decision-log entry marked VALUE is ready for `docs/CRITERIA.md` (D-013 now) | Owner | The entry and the row it would replace |
| The Statistician or the Computational Redistricting Scientist says the evidence can't support a verdict, a ranking, or a "no tradeoff" | Owner: the claim waits, or is reworded to what the evidence supports. "Cannot tell" is its own finding (D-019, D-023) | The Statistician's finding |
| A new state is added | Owner, with the election-law reader on that state's criteria, their order, and the remedy available there | The statute or constitutional text, and the config that encodes it |
| Election data would be committed, or VEST's licence or version question gets an answer | Owner. Nothing is committed under an unstated licence (`docs/CRITERIA.md` §9.1) | The source, and the Data Steward's report |
| A version bump will mint a DOI | The science reviewer and election-law reader read the headline and legal claims, then the owner releases. The archive is permanent, so the reads come first | The Peer Reviewer's and the Steward's reports |
| Anyone proposes softening the status line, or presenting a result as evidence about a real map | Owner, after outside validation that doesn't exist yet. Until then the answer is no | The request, and where the result would appear |
| A Mad Scientist bet is ready to test | Owner, after the Statistician | The bet, its cheapest test, and its kill criterion |
| The third review of the same claim fails | Owner, who drops the claim or takes it to the science reviewer | The open findings |

Record each decision where the repo already records them: a firewall change in its own commit, a value judgment in `docs/DECISIONS.md`, a criteria change in `docs/CRITERIA.md`, a retraction in `docs/progress.md`, and a release in its notes, naming who read the headline and legal claims. A relayed "a lawyer said so" is a claim, not a source: ask for the citation.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge | Maintainer |
| Any change to the firewall config or checker | Owner, in a commit that changes nothing else |
| Amending `docs/CRITERIA.md`, including promoting a VALUE entry | Owner. Agents propose |
| A new experiment, or a new run of an old one under a new name | Owner, after the Statistician |
| Bumping `gerrychain` or another pinned library that can move an ensemble | Owner. Results from before and after are reported as different ensembles |
| A release (and its DOI) | Owner, after the Pre-Submission Peer Reviewer and the Scientific Data Steward, and after the science reviewer and election-law reader |
| Shipping community-of-interest data | Owner. D-034 ships none, because choosing a source is choosing the definition |
| Removing or softening "exploratory, not validated" | Owner, only after outside validation |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer. The repo's own builder/critic loop already runs the work |
| Reality Checker | Built for web-product readiness from screenshot evidence. The repo's refuters already default to "refuted" |
| Model QA Specialist | Built for credit-style ML models (PSI, SHAP, Hosmer-Lemeshow). The detector is a percentile rule over an ensemble, and its ground-truth leakage is the Blinding & Leakage Auditor's job |
| Legal Compliance Checker, Legal Document Review | Business compliance and contracts, not constitutional or election law. The Election Law Analyst covers this project's legal sentences |
| Application Security Engineer | No server, no parser for files from strangers, and no credential beyond the release workflow's token. Revisit when the interactive interface `prompt.md` describes is built |
| Data Visualization Engineer, Web GIS Developer, Accessibility Auditor | There is no interactive interface yet. They come in when it's built |
| Spatial Data Engineer, Geoprocessing Specialist | The data build exists and works. It needs checking, not rebuilding, and the GIS QA Engineer does the checking |
| Communications Clearance Officer | The project is independent and says it isn't connected to the author's employment. If it's ever presented in an official capacity, the employer's ethics office and the Clearance Officer come first |
| Data Privacy Officer | No personal data. Census counts and precinct returns are aggregates |
| DevOps Automator | CI is three short workflows, and the release job already re-runs the checks before it tags |

## Success Criteria

| Metric | Target |
|--------|--------|
| Firewall | Every change under `src/generate/` has a Blinding & Leakage Auditor report, and `tools/firewall.yaml` changes only in owner commits that change nothing else |
| Legal sentences | Every legal sentence in the README and `docs/CRITERIA.md` carries a primary source and the date it was checked |
| Gate and instrument changes reviewed | Every change to `src/detect/`, `src/adversarial/`, or an experiment tool names the Statistician's verdict |
| Releases audited | Every version bump has a Pre-Submission Peer Reviewer pass on its headline numbers, a Scientific Data Steward pass on its package and citation, and notes naming who read the headline and legal claims |
| Verdict language | No sentence in the README, `docs/progress.md`, or report output says a plan is or isn't a gerrymander |
| Review cost | 1 catalog agent on a typical change |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| The Code Reviewer asks to extract the duplicated plan loader | The activation prompt overrides it. Decline the finding |
| A check fails and someone edits the firewall config or checker to pass it | Fix the code. If the config is wrong, stop and tell the owner (`prompt.md`) |
| A warning is silenced to get a clean run | `node_repeats` hid behind `filterwarnings("ignore")` and produced a false headline. Read the warning |
| A gate passes | Ask what a constant would score. Four Phase 1 rounds had gates pass for reasons that weren't detection |
| A null reported as "no tradeoff" | Every null here means "nothing stronger than ρ ≈ 0.13–0.22", and "cannot tell" is a different finding (D-019, D-023) |
| A correlation between two metrics called a finding | Run `tools/check_metric_algebra.py` first. Most metrics are functions of the same vote-share vector (D-026) |
| An effect reported in tolerance units | Convert it to the deviation the law regulates. An effect that exists only outside that range is legally inert (D-030) |
| A data join reports zero unmatched units | Check that votes and population are conserved, not how many ids matched (D-016) |
| An experiment re-run to improve its result | `prompt.md` forbids it. A new run is a new experiment and is named as one |
| A reviewer reads the builder's reasoning and agrees with it | Give reviewers the evidence, not the explanation |
| A legal sentence sourced from coverage of a case | Read the opinion. `docs/CRITERIA.md` §4.2 says coverage of *Callais* overstates the holding in both directions |
| An agent's referee report presented as outside review | The Peer Reviewer, the Statistician, and the three domain agents share the authoring model's blind spots. The science reviewer's and election-law reader's reads are the outside ones |
| Work lost to a container reclaim | Only a pushed commit is durable. Commit measurements as they land and run analysis from committed files (`docs/RESEARCH-LOOP-PLAYBOOK.md`) |
| A pass count from a machine with the data quoted alone | Quote both counts (D-037) |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' districting-bench > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt
```
