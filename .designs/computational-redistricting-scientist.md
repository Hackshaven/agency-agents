# Design: Computational Redistricting Scientist

Attribution: Eric Hackathorn, built for districting-bench, an independent project unconnected to the author's employment; branch `claude/districting-bench-team`. (Assumption to confirm: a personal contribution, not a U.S. Government work.)

- **Track and home:** Upstream candidate, built on the fork first. File `research/research-computational-redistricting-scientist.md`; skill name `agency-computational-redistricting-scientist`. The body never names districting-bench.
  - **Research**, beside the Statistician's academic neighbors and the Pre-Submission Peer Reviewer, because its job is the science behind a claim, not building software. The GIS division was considered and rejected: the core of the work is sampling and metrics, and the geometry is one rule of fourteen.
- **Who uses it:** Eric, on districting-bench's sampler, metrics, detection, and write-ups (the runbook's routing table). Beyond Eric: academic redistricting groups, the technical staff of independent commissions, newsroom data teams that publish ensemble analyses, civic-tech tools that score maps, and students learning the methods. Narrow field, broad audience within it.
- **Can Eric validate it himself:** Partly. Metric definitions and undefined cases are settled by running code: the embedded script is checked against districting-bench's own implementation. The claims about samplers rest on the literature, which was verified for this build. Whether an ensemble is the *right* comparison for a given legal question, and whether a write-up would survive an expert referee, needs a redistricting scientist outside the authoring loop. The runbook names that person as the science reviewer.
- **Closest catalog agents and boundaries** (checked 2026-10-10 against `hackshaven`):
  - **Statistician** (`academic/academic-statistician.md`) covers design, multiplicity, power, and causal inference, with RCTs and A/B tests as its examples. It has no knowledge of ensemble samplers, label switching, the gameability results, or what a redistricting metric's sign means. Boundary: it keeps general inference and multiplicity, and this agent keeps the ensemble and the metrics.
  - **Spatial Data Scientist** (`gis/gis-spatial-data-scientist.md`) does spatial econometrics and clustering. Not districting.
  - **Geographer** (`academic/academic-geographer.md`) builds coherent fictional worlds. Not related.
  - **GIS QA Engineer** keeps topology, adjacency, and CRS in the data build; this agent keeps what a compactness number means once computed.
  - **Pre-Submission Peer Reviewer** checks that claims follow from evidence in general, and names sections that need a specialist referee (its Rule 9). This agent is that specialist for redistricting.
  - Nothing in the catalog knows ReCom, SMC, or the redistricting metrics.
- **Origins:**
  - **districting-bench's own record**, read 2026-10-10 at `24c9d05`. The `node_repeats` misuse that a suppressed warning hid (`FEASIBILITY.md` §5.1). Convergence that never reached 1.01 (`progress.md`). The diagnostic rectangle (D-035). Thresholds that assumed independent draws (D-029). The legally inert tolerance effect (D-030). The arithmetic check for correlated metrics (D-026). The projection guard's finding that an equal-area CRS is the wrong requirement for shape measures: EPSG:6933 moved Reock 22.6% on Iowa (`src/evaluate/compactness.py`). The undefined cases of declination (`src/evaluate/partisan.py`). Each became a rule or a row in the metric table. The project is more careful than most published work, which is why its failure record is a good syllabus.
  - **Literature**, verified 2026-10-10 by a research pass (Crossref, arXiv, publisher pages, PDFs read where open):
    - DeFord, Duchin and Solomon, *HDSR* 3(1) (2021), on ReCom as "decidedly nonuniform", preferential to compact plans, and not reversible.
    - Cannon, Duchin, Randall and Rule, *SIAM Review* 68(2):349–381 (2026), on reversible ReCom, where stationary probability is proportional to the product of spanning-tree counts, and plain ReCom has no known closed form for three or more districts.
    - Carter, Herschlag, Hunter and Mattingly, arXiv:1911.01503. Ravier is **not** an author.
    - McCartan and Imai, *Ann. Appl. Stat.* 17(4) (2023).
    - McCartan et al., *Scientific Data* 9:689 (2022): the 50-State Simulations.
    - Chikina, Frieze and Pegden, *PNAS* 114(11) (2017): a local-outlier test, valid without mixing.
    - Najt, DeFord and Solomon, arXiv:1908.08881, a preprint only.
    - Vehtari et al., *Bayesian Analysis* 16(2) (2021): R-hat below 1.01, at least 4 chains, bulk and tail ESS above 400.
    - Stephanopoulos and McGhee, 82 *U. Chi. L. Rev.* 831 (2015).
    - Warrington, *ELJ* 17(1) (2018): declination undefined when one party wins every seat.
    - Campisi, Ratliff, Somersille and Veomett, *ELJ* 21(3) (2022): GEO.
    - DeFord et al., *Political Analysis* 31(3) (2023): symmetry metrics allow extreme outcomes.
    - Ratliff, Somersille and Veomett, *La Matematica* 4(3) (2025), arXiv:2409.17186.
    - Barnes and Solomon, *Political Analysis* 29(4) (2021): nine implementation choices that move compactness scores.
    - Chen and Rodden, *QJPS* 8(3) (2013).
    - Kenny et al., *Science Advances* 7(41) (2021).
    - GerryChain `node_repeats`: in 1.0.0 it defaults to 0 and counts *extra* roots per tree, and positive values aren't beneficial with the default memoized cut-finder. In 0.3.x it defaulted to 1, with a different meaning. That is why Rule 12 says to record sampler versions.
- **Findings for Eric** (about districting-bench, from this build):
  1. **The Stephanopoulos citation has the wrong first page.** "Redistricting Without Tradeoffs" is **126 Colum. L. Rev. 671 (2026)** (Vol. 126, No. 4; the journal's PDF, read 2026-10-10, puts the Introduction at p. 673), not 1001. Page 1001 appears in `CITATION.cff:60` (`start: 1001`), `README.md:43`, and `docs/CRITERIA.md:301` and `:485`. `prompt.md:128` carries it too, but `prompt.md` is preserved verbatim, so leave it and correct the others. `CITATION.cff` is archived with each release, so fix it before the next version bump.
  2. **Rule 3's label-invariance point is already honored.** The bench diagnoses cut edges and population spread, and the experiments diagnose `compactness_cut`, `fairness_eg`, and `population_equality` (`tools/convergence_rectangle.py:57`). All are plan-level and label-invariant. No finding. Recorded so a later review doesn't assume otherwise.
- **Assumptions made without asking:**
  - Attribution as above.
  - Tools: Read, Grep, Glob, Bash, WebFetch. Bash runs the metric script and reads results files; WebFetch checks a citation or a PlanScore page. Read-only by Rule 13.
  - The metric table states the orientations districting-bench uses, which are also the most common in the literature. Rule 5 makes the reviewer check each tool's own.
  - Rule 10 refuses help optimizing a real plan toward a party or metric for adoption, but allows building known gerrymanders as test ground truth inside a research harness. The line is drawn at whose map it is and where the output goes. That is a judgment call, which a person may want to tighten.
  - The planted scenarios below are not described in the body. The body's examples (a 5% tolerance beside a person-balanced map, a single-chain mixing claim, a tie handled two ways, a projection reshuffle) are chosen to differ from them. The classes appear in the rules, so the test measures whether the agent applies them.
- **Checks run 2026-10-10:**
  - `scripts/lint-agents.sh`: 0 errors, 0 warnings. `scripts/check-agent-originality.sh`: passed.
  - **`district_metrics.py`, as embedded in the body** (extracted and run) against districting-bench's `evaluate.partisan` on five cases with integer votes: symmetric, packed, skewed, unequal turnout across five districts, and a sweep.
    - Mean-median, declination, and partisan bias agree to four decimals in every case.
    - The efficiency gap differs only by the wasted-vote threshold: half here, half-plus-one in the repo's `threshold="majority"`. That gives 0.350 against 0.355 on a 100-vote toy and −0.3985 against −0.3985 at realistic totals. The body documents the convention.
    - Declination returns `None` for a sweep and for an exact tie, and 0.0 (not −0.0) for a symmetric plan.
    - An earlier test that fed the repo float votes showed a spurious mismatch: the repo truncates votes to integers. That was a test artifact, not a defect.
- **Test plan:**
  1. **Harness.** As for the Blinding & Leakage Auditor: one copy of districting-bench at `24c9d05` per scenario, the patch committed with the PR text as its message, and the ground truth written and hashed here before the first run, in a kit directory no scenario mentions. The transcript is checked for reads of the kit.
  2. **Blind runs.** A fresh subagent gets the agent file, the scenario path, and the runbook's activation prompt, with "Computational Redistricting Scientist" as the agent.
  3. **Scenarios:**
     - **C1, a draft write-up** (a new `docs/` file) with about a dozen result sentences. Planted: a claim about what the ensemble samples, a commission's map called an outlier against an ensemble that omits the criteria the commission had to follow, verdict language with a p-value read as intent, and a seats-votes curve extrapolated far from the observed vote and described as the plan's responsiveness. Traps: an honest statement that R-hat fell short of 1.01, and a correctly scoped percentile. Positive control: one paragraph written to the Outlier Statement template.
     - **C2, a code change to the detection bench.** Planted: a convergence diagnostic on a statistic tied to district labels, and an undefined metric value filled with a number "to keep plots complete." Trap: a sign convention that differs from a published tool's, documented in the code and handled correctly in a test.
     - **C3, a code change to the data and metrics path.** Planted: uncontested districts imputed in a way that distorts vote-share metrics, and compactness computed in geographic coordinates. Trap: county splits that read zero on Iowa by construction.
  4. **Baselines.** The Statistician on C1. The Code Reviewer on C2 and C3. The specialist has to beat the Statistician on the sampler claim and the omitted-criteria claim, and beat the Code Reviewer on the label-dependent diagnostic and the projection, to earn its place.
  5. **Score:**
     - each plant found, with the mechanism stated correctly and `file:line`
     - traps cleared with a reason, and the positive control left standing
     - every verdict sentence rewritten as a distribution
     - no legal conclusion of its own; law handed to the Election Law Analyst
     - every citation in its report resolving to the cited work, checked by opening each
     - at least two plans recomputed independently, where the scenario supplies totals

     **Pass bar:** at least 6 of 7 plants with the right mechanism; at most one trap flagged; the positive control unflagged; zero invented citations; zero edits.
  6. **Round 1:** scorecard, revisions, and a blind rerun of failures.
  7. **Real run (after Round 1):** a review of districting-bench's own `docs/progress.md` experiment sections, scored by Eric. Then, separately, the science reviewer named in the runbook reads the same sections, and the two reports are compared. That is the only test of whether the agent sees what an expert sees.
- **Proposed frontmatter:** color `#134E4A` (unused); emoji 🎲 (unused; one draw from a distribution); vibe "The enacted map is one draw. The question is which distribution it's being compared to, and who chose it."; tools Read, Grep, Glob, Bash, WebFetch; description as in the agent file (651 characters).
- **Round 1 ground truth, sealed 2026-10-10 before any run:** `GT-scientist.md`, SHA-256 `7e768e61e77d2ec50499266aba9b0db3df38577c23d8e43e729ee324f72f8929`. It covers three scenarios (C1–C3) on copies of districting-bench at `24c9d05`. Kept encrypted outside every scenario tree until scoring; the plaintext is decrypted and rehashed at scoring time and must match.
- **Round 1, run and scored 2026-10-10.** The answer key decrypted to the hash above. Every run had its own copy, and the file manifests before and after are identical for all six runs (three specialist, three baseline). No transcript shows a read of the kit.
  - **Result: PASS on the pass bar.** 8 of 8 plants found with the right mechanism:
    - **R1:** vanilla ReCom with always-accept, a compact lean, and a stationary target nobody has characterized. Plans run up to a 316-person spread against the enacted plan's 94.
    - **R2:** the 97% can't be traced, and the ensemble omits Colorado's constitutional criteria (`CRITERIA.md:129`). Checked against the published 2020 district results, the enacted plan sits near the 11th percentile, not above the ensemble.
    - **R3:** both mechanisms. It adds a matched-tolerance count: 454 draws within 94 persons, two of them at 0 D.
    - **R4:** the stated slope is arithmetically impossible for 8 seats, and the curve runs outside the tool's 0.30–0.70 default.
    - **R5:** a toy 12×12 ReCom run shows the district-1 trace reaching R-hat 1.003–1.005 while sorted shares sit at 1.007–1.036. The label trace mixes first, so it hides slow mixing.
    - **R6:** Warrington's reference code returns NaN. The value jumps to 0.0 at the sweep boundary, and `trusted_metrics` promotes the fake 0.0 on a Colorado 8–0 plan.
    - **R7:** on the real 2022 Iowa House canvass, 48 of 100 districts were uncontested. The efficiency gap is +0.0056 as cast against +0.04 to +0.10 under imputation.
    - **R8:** on real TIGER 2022 lower-house shapes, degree-based Polsby-Popper errs by −14.8% to +9.7%, and 77 of 100 ranks change.
  - **Traps.**
    - T1 held: it recomputed the R-hat paragraph and left it standing.
    - T5 held: it called the test's comment overstated, not the test wrong.
    - T6: the congressional half held. It called the house-plan note wrong under §42.4(2), which is a valid reading, so it isn't counted.
  - **The C1 trap set was defective, and the answer key was amended at scoring.**
    - T2, T3 (the positive control) and T4 were checked against the README. Other parts of the repo contradict them:
      - the draft's plan counts are v1 sizes under a "v2 unless stated" banner
      - the T2 figures come from the 1,820-draw ensemble
      - fresh Colorado ensembles reached 7 D (`progress.md:625`, `:766`)
      - two of Experiment 3's three plans fail the repo's own compactness standard
    - The specialist and the Statistician baseline both flagged them, and they were right.
    - Only T1 remained a clean trap, and the positive-control criterion couldn't be scored in C1.
    - Round 2 must check every trap and control against every place the repo states the fact.
  - **Behavior.**
    - Zero edits.
    - Zero invented citations: DeFord, Duchin and Solomon (2021), plus Wikipedia district pages, which it labeled as secondary and rounded.
    - No legal conclusions; law went to the Election Law Analyst.
    - Distribution language, an Ensemble Card, an Outlier Statement, and the partial-measure line in every report.
    - On C2 and C3 it recomputed the metrics with `district_metrics.py` and matched the repo to four decimals.
  - **Baselines.**
    - The Statistician on C1 found R1–R4, and R3 by both mechanisms.
    - The Code Reviewer found R5 and R6 on C2, and R7 and R8 on C3. It measured R8 on real shapes too (−15.3% to +10.3%).
    - **The pre-registered criterion is not met.** It required the specialist to beat the Statistician on R1 and R2 and the Code Reviewer on R5 and R8. All four are ties on detection.
    - Where the specialist went further: the Ensemble Card, the matched-tolerance and published-results checks, the label-trace demonstration, convergence measured on the claim's own statistic (seat-count R-hat 1.014), and handoffs.
    - Where the Statistician went further: shares recomputed from the committed draws, with per-chain intervals.
  - **Reading.**
    - districting-bench documents its own pitfalls:
      - `CRITERIA.md` §5.1 says declination is undefined on a sweep
      - `compactness.py` refuses geographic coordinates
      - `progress.md` says "not a finding yet"
    - A careful generalist finds plants like these by reading the repo. Round 1 shows the agent does the job; it doesn't show the job needs it.
    - **Round 2** plants defects the repo's documents don't name, so that only domain knowledge finds them. The real run (step 7) stays as planned.
  - **Revisions:** none, since nothing failed.
