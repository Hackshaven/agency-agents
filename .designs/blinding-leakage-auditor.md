# Design: Blinding & Leakage Auditor

Attribution: Eric Hackathorn, built for districting-bench, an independent project unconnected to the author's employment; branch `claude/districting-bench-team`. (Assumption to confirm: a personal contribution, not a U.S. Government work. See Assumptions.)

- **Track and home:** Upstream candidate, built on the fork first. File `testing/testing-blinding-leakage-auditor.md`; skill name `agency-blinding-leakage-auditor`. Nothing in the body names districting-bench, so it can go upstream unchanged once the blind runs pass.
  - **Testing**, beside the Reality Checker and the Evidence Collector, because its output is a verdict on whether a test (an evaluation, a baseline, a critic's judgment) means what it claims. Security was the other candidate. It was rejected because the adversary here is usually the author's own refactor, not an attacker, and Security's agents are built around threat actors and CWE mappings.
  - **The name** pairs the two words different fields use for the same failure: "blinding" (experimental science, blind analysis, blind review) and "leakage" (ML and statistics). Either alone would lose half the audience.
- **Who uses it:** Eric, on every districting-bench change that touches `src/generate/`, a data read, the null pool, or the critic loop (the runbook's routing table). Beyond Eric: ML and statistics teams with held-out evaluation, labs that run blind analysis, benchmark maintainers, and anyone running builder/critic agent loops. Broad.
- **Can Eric validate it himself:** Mostly. A breach is a path you can trace in the code, and the probe kit makes each guard claim reproducible. Ground truth for the planted scenarios is settled by running code: the firewall checker on each patch, the reach scan, and the overlap between null and reference seeds. Two things need more than Eric's check. Whether a crossing *biased* a published number is a statistical question (the Statistician, or a person). And whether a new field carries protected information in practice is a domain question.
- **Closest catalog agents and boundaries** (checked 2026-10-10 against `hackshaven`):
  - **Code Reviewer** reads diffs for correctness and lists "security" in its scope, but it has no notion of an information boundary. On districting-bench it is the agent most likely to recommend the shared module that breaches the firewall. Boundary: it keeps correctness; this agent keeps the wall.
  - **Model QA Specialist** mentions label leakage once, inside a credit-model audit (PSI, SHAP, Hosmer-Lemeshow). Its leakage check is one line of a model-lifecycle review. This agent's whole job is the boundary, across code, data, process, and people. Boundary: Model QA keeps model performance and calibration.
  - **Statistician** owns whether a leak could have moved a result and by how much; this agent finds the path.
  - **AI-Generated Code Security Auditor** hunts secrets, row-level security, and prompt-injection sinks. A leaked secret is its job; a leaked label is this one's.
  - **Reality Checker** certifies product readiness from screenshots. Not related, despite the testing division.
  - Nothing in the catalog walks a channel inventory against a stated boundary, probes the guard, or tests planted ground truth for separability.
- **Origins:** districting-bench's own record, read 2026-10-10 at `24c9d05`.
  - **Static guards miss whole channel classes.** `docs/FEASIBILITY.md` §1 found at least six ways partisan data reaches `src/generate/` untouched by `tools/check_firewall.py`: VEST and Dave's Redistricting column names, an allowlist that short-circuits on any token containing `precinct`, files at the top of `src/`, non-`.py` files, and reads that name no column. Reconfirmed while building this agent: a probe adding `src/common/io.py`, imported by both `generate` and `evaluate`, leaves the checker printing `clean`, because `owning_package()` skips modules outside the configured packages. That is Rule 4, channels 1, 4 and 13, and the reach scan.
  - **The answer was a positive allowlist, not a longer denylist** (`docs/ARCHITECTURE.md` §4). That's why Rule 2 judges against the boundary as written ("nothing else"), not against the motivation ("nothing partisan").
  - **Selection and overlap are leaks.** Surviving seeds aren't a random subset of attempted seeds (`ARCHITECTURE.md` §7, D-035). Null cases are drawn from their own seeds so none is scored against an ensemble it belongs to (`src/detect/bench.py`, module docstring). These are Rules 7 and 8.
  - **Ground truth that leaks its provenance.** Planted gerrymanders had about twice the cut edges of every neutral map, and a compactness screen separated them perfectly (D-010). After the fix, non-partisan AUC was still 0.746 on Colorado against a target of 0.5 (`docs/progress.md`, Phase 1 conclusion). That's Rule 9 and the separability script.
  - **People and agents are channels.** `prompt.md`: "Critics read `bench-results.json` and the rendered plots — never the builder's reasoning." Rule 10 and channel 11.
  - **Literature**, all verified 2026-10-10 by a research pass against Crossref, arXiv, Europe PMC, and publisher pages: Kapoor and Narayanan, *Patterns* 4(9):100804 (2023), with 294 papers, 17 fields, and eight leakage types; Kaufman, Rosset, Perlich and Stitelman, *ACM TKDD* 6(4) (2012); Geirhos et al., *Nature Machine Intelligence* 2:665–673 (2020); Klein and Roodman, *Annu. Rev. Nucl. Part. Sci.* 55:141–163 (2005); MacCoun and Perlmutter, *Nature* 526:187–189 (2015), whose full text was paywalled, so its content was checked through the Berkeley press release; Kim, Garg, Peng and Garg, ICML 2025, where the 60% is agreement *when both models err*, on one leaderboard dataset; and Oren et al., ICLR 2024, on test-set contamination.
- **Findings for Eric** (about districting-bench, not agent rules):
  1. **The shared-module route is still open** (FEASIBILITY §1's `src/shim.py` row, generalized). Any new directory under `src/` that isn't one of the four configured packages is unscanned, and imports of it are unchecked. The runbook's firewall checklist item 4 covers it by review. A mechanical fix would be a change to `check_firewall.py`, which is your decision.
  2. **A partisan statistic helps choose the neutral reference** (found by the agent in Round 1, unplanted, in three independent runs).
     - `tools/convergence_rectangle.py:65` puts `fairness_eg` in `COLUMNS`.
     - `best()` (`:100-112`) picks the chain × prefix rectangle by the worst split R-hat across all three columns.
     - That rectangle sets which draws make up the v2 reference (Iowa `rectangle: 4594` with 6 chains, `progress.md:2069`).
     - Recomputed from the committed `docs/experiment-2/{ia,co}-convergence-rectangles.json` with `fairness_eg` dropped, the choice is the same: IA 4594×6 (worst 1.023) and CO 2500×8 (worst 1.037). No published result moved.
     - The rule still reads it, so a rerun could let it decide. D-035 doesn't discuss it. Whether it stays is your call.
  3. **The old null pool wasn't plan-level disjoint from the reference either.**
     - Reported by the agent from the committed draws: 31 of 336 "independent" null cases match a reference draw by fingerprint.
     - Nothing checks that a null case's canonical id is outside `reference_ids`.
     - Not yet reproduced outside the agent's run.
  4. **The CI firewall-edit detector probably never fires** (UNCONFIRMED; settling it needs a CI run on a PR that touches `tools/firewall.yaml`). `.github/workflows/firewall.yml:23` runs `git diff origin/main...HEAD` with errors silenced, after a depth-1 checkout. A local run without `origin/main` is silent.
  5. **Two smaller guard gaps:**
     - `generate.units.load_adjacency` has no schema guard. An extra key is accepted; `check_inputs` catches it later.
     - The firewall-status hash the bench records in its results doesn't change when the allowlist is widened. Reported by the agent in the S3 run.
  6. **`check_firewall.py` misses dynamic imports** (reported with probes in three separate auditor runs: the Round 1 S5 rerun, Round 2 S10 and S7).
     - `importlib.import_module("evaluate.elections")` inside `src/generate` prints clean.
     - `"evaluate.partisan"` is caught only because its text contains the denied word "partisan".
     - The class isn't in FEASIBILITY §1's probe table. Whether to add it is your call.
- **Assumptions made without asking:**
  - Attribution as a personal contribution, because districting-bench says it's unconnected to the author's employment. If it should carry NOAA attribution like the fork's other agents, change the line above.
  - Tools: Read, Grep, Glob, Bash. Bash runs the reach scan, the separability script, and probes in a temporary copy. The tools line can't make Bash read-only, so Rule 1 carries that, and the test checks it.
  - Probes use `git archive` into a temp directory, never `git worktree add`, because a worktree writes into the owner's `.git`.
  - The separability script needs pandas. Its joint score needs scikit-learn, and without it the joint score is reported UNCONFIRMED rather than skipped silently.
  - The planted scenarios below are not described in the agent body, and the body's examples come from other domains (a scaler fitted before the split, a notebook checker). The channel *classes* are in the body, as the Federation Reviewer's were. The test measures whether the agent applies them, not whether it can guess them.
- **Checks run 2026-10-10:**
  - `scripts/lint-agents.sh` 0 errors, 0 warnings; `scripts/check-agent-originality.sh` passed.
  - **`reach.py`, as embedded in the body** (extracted and run): on districting-bench `src`, `generate` reaches only its own 5 modules, and the four reads in `units.py` are listed. In a probe copy with a shared `common.io` imported by `generate/ensemble.py` and `evaluate/plan.py`, it reports `OUTSIDE common.io … also imported by: evaluate.plan`, while `check_firewall.py` on the same copy prints `clean`.
  - **`separability.py`, as embedded:** on 200 synthetic cases with one shortcut feature, it reports cut edges at 0.965, a no-signal feature at about 0.56, and a constant at 0.500. Hand cases: perfect separation gives 1.0, all ties 0.5, reversed 0.0. The joint 5-fold logistic AUC is 0.971 with scikit-learn 1.9.1, pandas 3.0.6 and NumPy 2.5.3 in a scratch venv, and 0.963 with `--groups`. Without scikit-learn it prints the UNCONFIRMED line. A column with missing values, or a non-numeric one, is named, not dropped silently.
- **Test plan:**
  1. **Harness.** A copy of districting-bench at `24c9d05` per scenario, in a scratch directory outside both repositories, with the patch committed signed off and the PR text as its commit message. Record `git status --porcelain` and a listing of the scratch directory's parent before and after each run.
  2. **Sealed ground truth.** Write `GROUND_TRUTH.md` for the kit before any run, in a kit directory no scenario path mentions, and record its SHA-256 here before the first run. After each run, check the reviewer's transcript for any read of the kit directory. A read voids that run.
  3. **Blind runs.** A fresh subagent gets the agent file as its instructions, the scenario path, and this prompt, adapted from the runbook's activation prompt:
     > Audit this districting-bench change as the Blinding & Leakage Auditor. Read the diff (`git diff HEAD~1`) and whatever else you need in the checkout. You are not given the author's reasoning beyond the commit message. Report with file:line, most important first. Do not edit files in the checkout.
  4. **Scenarios** (districting-bench). Each carries planted breaches, traps that look like leaks and aren't, or a positive control:
     - **S1, a "tidy-up" refactor.** It plants a breach across the wall that the checker can't see. Traps: a duplicated loader added on the downstream side, which the boundary requires, and an allowlisted word in a log string.
     - **S2, a "performance" change to the bench.** It plants an evaluation-overlap breach. Trap: a new read of a neutral file.
     - **S3, a "small data improvement."** It widens what generation may see with a field that is neither partisan nor racial. Expected: a breach of the boundary as written, escalated to the owner, with the consequence stated honestly (Rule 2). Over-escalating it as a partisan leak counts against the agent.
     - **S4, a review-tooling script** that assembles a critic's packet. It plants a context breach (Rule 10).
     - **S5, positive control:** a convergence-diagnostic change inside `generate` with no data access. Expected: CLEAN AS FAR AS CHECKED.
     - **S6, generalization** outside districting: a 200-line synthetic scikit-learn project with two planted leaks (preprocessing before the split, and one subject's rows on both sides) and one trap (target encoding done correctly inside the folds). It shows whether the agent belongs in the catalog or only in this runbook.
  5. **Baseline.** The catalog Code Reviewer on S1–S5 with the same prompt. The specialist must beat it on at least two of S1, S2, and S4 to earn the roster slot. The Statistician also runs S2, the overlap case, since it's the other plausible owner.
  6. **Score**, per `GROUND_TRUTH.md`:
     - each plant found, with the right path and `file:line`, the right class (BREACH or GAP), and escalation where required
     - traps cleared with a reason
     - the positive control clean
     - all 13 inventory rows present
     - zero edits (identical `git status`), and probe copies removed
     - no recommendation to edit `tools/firewall.yaml` or `check_firewall.py` as a fix
     - the partial-measure line present

     **Pass bar:** every plant classed BREACH or GAP on the right path; S3 escalated as an owner decision; at most one trap flagged; S5 clean; zero edits.
  7. **Round 1.** Scorecard here, a numbered revision round, then a blind rerun of whatever failed.
  8. **Real run (after Round 1):** a full-tree audit of districting-bench `main`, with Eric scoring it. It should rediscover FEASIBILITY §1's gaps without being pointed at them, and report D-010's open confound with a separability number computed from committed artifacts. If that number can't be computed from committed files, that is itself the finding progress.md already records.
- **Proposed frontmatter:** color `#9A3412` (unused on `hackshaven`); emoji 🙈 (unused; see no evil); vibe "A guard that has never fired has never been tested. Show me the path, then show me the guard stopping it."; tools Read, Grep, Glob, Bash; description as in the agent file (643 characters).
- **Round 1 ground truth, sealed 2026-10-10 before any run:** `GT-auditor.md`, SHA-256 `697bd7af0757a39639275f9cfb1fe3e9537cc456527283fd891b20faaca4e86a`. It covers six scenarios (S1–S6) on copies of districting-bench at `24c9d05` plus one synthetic scikit-learn project. Kept encrypted outside every scenario tree until scoring; the plaintext is decrypted and rehashed at scoring time and must match.
- **Round 1, run and scored 2026-10-10.** The answer key decrypted to the hash above. The file manifests before and after are identical for all twelve runs (six specialist, six baseline). No transcript shows a read of the kit.
  - **Result: FAIL on the pass bar, on the positive control alone.**
    - **S1, A1:** BREACH, escalated.
      - The reach scan shows 0 modules outside `generate` at HEAD~1 and 1 at HEAD.
      - It quoted the "invalidates every result" rule and stated the consequence honestly.
      - The fix it gave is a revert, not a guard edit.
      - T1 and T2 cleared. It also found that the shared reader runs before the column guard, so row labels and order could carry values past it (UNCONFIRMED).
    - **S2, A2:** BREACH, evaluation overlap.
      - A probe with the repo's own functions on committed draws: top-of-metric null cases inside reference support go from 84 to 336 of 336.
      - It flagged the critic artifact's false provenance. T3 cleared.
    - **S3, A3:** BREACH (the guard widened), escalated as the owner's decision.
      - A probe showed the same file refused at HEAD~1 and accepted at HEAD.
      - Its consequence was honest ("vap cannot have moved any draw yet"), and not over-escalated.
      - The legal question went to the domain reviewer.
    - **S4, A4:** BREACH, context channel.
      - A canary probe proved the crossing. T4 cleared.
      - `CRITERIA.md` was marked UNCONFIRMED and routed to the owner, not called a leak.
    - **S5, positive control: FAIL.** It gave GAP for a pure function with no reads, no state, and no caller, on the theory that a future caller might pass it partisan data.
    - **S6, generalization:** 3 of 3 leaks found:
      - scaler and feature selection fitted before the split
      - one patient on both sides
      - `followup_calls` recorded after discharge
      All three traps cleared. It also found an unplanted one: `mutual_info_classif` is unseeded.
    - **Every run:** all traps held, 13 rows, probes outside the tree and removed, zero edits, and no recommendation to edit the guard as a fix.
  - **Revision 1 (2026-10-10).**
    - New Rule 13: judge the change by the paths it creates. A function that reads nothing, holds no state, and has no caller creates no path, and a future caller belongs to that caller's review.
    - The report gains a Pre-existing section that doesn't set the change's verdict.
    - Step 6 ties BREACH and GAP to the change in scope.
    - A new metric: changes that create no path reported as anything but CLEAN AS FAR AS CHECKED, target zero.
  - **Blind rerun after Revision 1,** each on a fresh copy, with the same prompt:
    - **S5: PASS.** CLEAN AS FAR AS CHECKED, with the future-caller note in one line and the pre-existing rectangle item in its own section.
    - **S1, as a regression check: PASS.**
      - BREACH on the same path, escalated, with an honest consequence and no guard edit proposed as the fix.
      - Both traps cleared. `chain_report` was cleared in Rule 13's words: "reads nothing, holds no state and has no caller, so it creates no path."
      - The rectangle item went under Pre-existing.
      - Its probe was stronger than Round 1's. A 9-line edit confined to `common/tables.py` made the generator receive vote counts as populations, with the firewall check and the schema guard both silent.
    - Both reruns: 13 rows, probes removed, zero edits, and a transcript audit showing no access outside the checkout, the agent file, and the run's own temp directory.
    - **With Revision 1, the auditor meets the Round 1 pass bar.**
    - **Deviation:** during the reruns, the decrypted answer keys sat in plaintext in the scratch area, because the session's tool policy blocked moving them. The transcript audit shows no read or listing of them. Earlier, the last seven Round 1 runs ran with these design records present in this repository (a stop hook required a clean tree), and their audit shows no access either.
  - **Baselines.**
    - The Code Reviewer found A1 (it probed the checker's blind spot itself), A2 (with a synthetic false-positive shift, 0.117 to 0.194), A3 and A4, all as blockers. Its S5 boundary call was clean.
    - The Statistician found A2 by two mechanisms.
    - **The pre-registered criterion is not met.** It required beating the Code Reviewer on at least two of A1, A2 and A4; all three are ties.
    - No baseline ran on S6, so generalization was measured for the specialist only.
  - **What only the specialist found:** real, unplanted issues in districting-bench itself (Findings for Eric 2–5), none of which any baseline reported. The rectangle selection was found independently in three runs.
  - **Reading.**
    - A careful Code Reviewer catches planted breaches when the repo states its boundary as plainly as districting-bench does. The auditor's value showed in channel coverage and in what nobody planted.
    - The full-tree real run (step 8) tests exactly that.
    - **Round 2:** a baseline on S6, and plants in channels the repo's documents don't name. Round 2 and the real run decide whether the agent replaces the Code Reviewer at this gate or stays beside it.
- **Round 2 plan and sealed ground truth, 2026-10-10, before any run.** `GT-auditor-r2.md`, SHA-256 `c6ad9e6f3344f494e7f5daeb2772102246b1086d853b76ccbd117e932ee39de0`, kept encrypted outside every scenario tree until scoring.
  - **Scenarios:**
    - **S7 and S8:** two districting-bench changes. Each plants a crossing in a channel the repo's documents don't name.
    - **S9:** a synthetic forecasting project with three planted leaks and four traps.
    - **S10:** a positive control.
    - **S6 again:** Round 1's project, this time reviewed by the Model QA Specialist as its baseline.
    - Every patch was run before sealing: its tests pass and `check_firewall.py` prints clean. S9's leaks were measured.
  - **Pass bar:** both districting plants found as BREACH or GAP, with the path into the blinded component and an honest consequence; S9 at least 2 of 3; S10 CLEAN AS FAR AS CHECKED; at most one trap flagged; zero edits.
  - **Baselines and the test for the slot.**
    - The Code Reviewer reviews S7, S8 and S10. The Model QA Specialist reviews S6 and S9 with the same prompt.
    - A plant counts only with its path. A reproducibility or style complaint doesn't count.
    - The auditor earns the gate slot if it finds both districting plants and the Code Reviewer misses at least one.
    - It earns a catalog place for ML leakage if, across S6 and S9, it finds at least as many of the six plants as the Model QA Specialist, with no more traps flagged.
- **Round 2, run and scored 2026-10-10.**
  - **Integrity.** The answer key decrypted to the hash above. All nine auditor-scenario runs left their checkouts byte-identical; several agents created and removed `__pycache__` along the way. No transcript reads the vault, the answer keys or this record.
    - Two runs listed the scratch root's directory names while deleting their own temp directories.
    - Agents' WebFetch calls auto-saved files into the session's tool-results directory, which is harness behavior.
  - **Result: PASS.**
    - **S7, A5:** BREACH with the full path from the election file's bytes to the chain seeds (`bench.py:530 → 3306 → 2271 → ensemble.py:365, 384`). A probe showed one added vote changes every chain seed.
      - Its consequence was honest: no partisan signal reaches the sampler, but the reroll lever now sits in the protected file.
      - It cleared the provenance-digest trap.
      - It also found that the enacted plan feeds the seed, and that any stray CSV moves it.
    - **S8, A7:** BREACH (selection). A spy probe saw `run_chains` receive 0.006 for Colorado.
      - A sweep showed the rule's tolerance alone can select every grid value.
      - It cleared both traps.
    - **S9:** 3 of 3, every trap cleared, with the measured fix (0.0913) matching the answer key's (0.0919).
    - **S10, positive control:** CLEAN AS FAR AS CHECKED. The pre-existing dynamic-import gap went under Pre-existing. Revision 1 holds.
  - **Two defects in my kits that reviewers found.**
    - S8's `tools/epsilon.json` contradicts its own rule: the recorded moves give 8e-3, not 6e-3. The auditor and the Code Reviewer both found it independently.
    - S10's `distinct_per_chain` docstring states its purpose backwards. The Code Reviewer found it.
    - Neither defect touches a scored plant.
  - **Baselines.**
    - The Code Reviewer found A5 and A7, each with the path into the generator and an honest consequence, and its S10 boundary call held.
    - **The gate criterion (both plants found while the Code Reviewer misses one) is not met.** Across two rounds the Code Reviewer has found all six districting plants the auditor found.
    - The Model QA Specialist found 3 of 3 on S9 with no trap flagged. Its S6 run was still in progress when this was committed; the result follows in the next commit, and the ML-leakage criterion is scored there.
  - **Reading.**
    - Districting-bench states its boundary plainly, and its own documents list the static checker's blind spots. With that context, a careful Code Reviewer traces information paths as well as the auditor does, including seeds and parameter selection.
    - The auditor's additions are probe evidence (spy probes, perturbation probes, a tolerance sweep), a 13-channel account on every run, and pre-existing findings kept out of the change's verdict.
    - In Round 1 it also found real problems nobody planted, and in Round 2 a new dynamic-import gap.
    - The evidence doesn't support a gate slot over the Code Reviewer. It supports periodic full-tree audits (step 8), which is where its unplanted findings came from.
