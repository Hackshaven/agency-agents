# Design: Election Law Analyst

Attribution: Eric Hackathorn, built for districting-bench, an independent project unconnected to the author's employment; branch `claude/districting-bench-team`. (Assumption to confirm: a personal contribution, not a U.S. Government work.)

- **Track and home:** Upstream candidate, built on the fork first. File `specialized/specialized-election-law-analyst.md`; skill name `agency-election-law-analyst`. The body never names districting-bench.
  - **Specialized**, beside the Legal Compliance Checker's neighbors (Legal Document Review, the Communications Clearance Officer). `support/` was considered, since the Legal Compliance Checker lives there. It was rejected because that division is operations support, and this agent is a domain reviewer.
  - **U.S. scope.** The body is about U.S. federal and state election law. Other countries' boundary law (boundary commissions, the U.K.'s, Canada's, Australia's) would need its own agent or a section written by someone who knows it.
- **Who uses it:** Eric, on districting-bench's legal sentences: `docs/CRITERIA.md` §1, §2 and §4, the README's "Legal context", and any report text that could read as a legal conclusion. Beyond Eric: researchers and journalists writing about redistricting, civic-tech tools that score maps, advocacy and good-government groups checking their own materials, and students. The most important users are the ones whose tools print text that a reader could take as a legal conclusion.
- **Can Eric validate it himself:** Partly, and less than the other two agents. Whether a sentence matches the opinion's text is checkable by anyone who reads the opinion; the test kit's ground truth is built that way, from primary sources. Whether a sentence states the law *correctly* where the law is contested, and how a holding applies to a state's facts, needs an election-law attorney. The runbook keeps the election-law reader as a person for exactly that reason, and the agent's ATTORNEY status routes to them.
- **Closest catalog agents and boundaries** (checked 2026-10-10 against `hackshaven`):
  - **Legal Compliance Checker** (`support/support-legal-compliance-checker.md`): business compliance across GDPR, CCPA, HIPAA, SOX, and PCI, with policies, audits, and contracts. Nothing on constitutional law, the Voting Rights Act, or courts' holdings. Boundary: it keeps business compliance.
  - **Legal Document Review** (`specialized/legal-document-review.md`): contracts, litigation documents, and real estate agreements. Not case law research.
  - **Research Synthesist** traces claims to primary sources in general and grades evidence. It has no notion of holding versus dissent, circuit-bound precedent, or subsequent history. Boundary: it keeps the literature, and this agent keeps the law. The runbook routes that way.
  - **Communications Clearance Officer** clears agency messages against policy, law, and political-activity rules for a government communications office. Different job: it decides whether an agency may say something, and this agent checks whether a statement about the law is accurate.
  - Nothing in the catalog reads a court opinion against a sentence that describes it.
- **Origins:**
  - **districting-bench's own documents**, read 2026-10-10 at `24c9d05`. `docs/CRITERIA.md` classes federal rules `FEDERAL` with "check the date — this moved substantially in April 2026"; tells readers to "read the opinion, not summaries", because coverage is polarized; says to "describe the holding, not adjudicate the dispute over its magnitude"; and names "implying a remedy that does not exist" as one of the four ways the system could become dishonest (§11). These became Rules 2, 3, 4, 7 and 10.
  - **The failure shapes in the body's examples** (a pending case described as decided, a statute quoted from a superseded version, a CRS summary quoted as the opinion, a tool calling a map "illegal" where no court hears the claim) are common in published redistricting material. They are classes, not districting-bench defects.
  - **Verified legal facts**, from a research pass on 2026-10-10 against primary sources: supremecourt.gov slip opinions and order lists, the Eighth Circuit's opinion server, official state court PDFs (several via the Loyola Law School redistricting site's copies of the courts' own filings), legis.iowa.gov, and leg.colorado.gov. Nine items were fully verified and three partly. The table in the agent's Advanced Capabilities carries only verified rows. Notes:
    - *Louisiana v. Callais*, 608 U.S. 85 (Apr. 29, 2026), 6–3. The quoted standard is at 608 U.S. at 116. The dissent's "makes a nullity of Section 2" is at slip op. 34, 608 U.S. at 160. The opinion doesn't reach the § 2 private-right question.
    - The CRS Legal Sidebar LSB11431 (May 14, 2026) exists. congress.gov refused the fetch, and the mirror that was read names the dissent's joiners wrongly ("Sotomayor and Kagan" for Sotomayor and Jackson). That is a live example of Rule 2: a reliable secondary source, one transcription away from wrong.
    - Eighth Circuit: *Arkansas NAACP* (2023; no private right of action under § 2) is binding. *Turtle Mountain* (2025; no § 1983 route) was vacated and remanded by the Supreme Court on May 18, 2026 in light of *Callais*, with Justice Jackson dissenting. The Supreme Court hasn't decided private enforceability.
    - State courts: the research confirmed Kansas (2022), North Carolina (2023), New Hampshire (2023, not 2024), and South Carolina (2025) as nonjusticiable; New Mexico (2023) and Kentucky (2023) as justiciable; Pennsylvania (2018) as justiciable, verified from the court's order (the full opinion couldn't be fetched); Wisconsin as mixed (2021, 2023); and Utah as undecided by its supreme court. **No Nevada Supreme Court ruling could be found.**
    - Iowa Code § 42.4 (Iowa Code 2026) was read from the official PDF. Colorado Const. art. V § 44.3 was read from the enrolled SCR 18-004, with the definition of "competitive" at § 44.3(3)(d) and the Colorado Supreme Court's "clear hierarchy" reading (2021 CO 73, ¶ 41).
    - *Gill v. Whitford*, 585 U.S. 48 (June 18, 2018), used in a communication example: vacated and remanded because the plaintiffs hadn't shown Article III standing; the Court didn't decide whether partisan gerrymandering claims are justiciable (supremecourt.gov docket 16-1161 and the preliminary print).
- **Findings for Eric** (each checked 2026-10-10; these are the kind of thing the agent exists to find, and they turned up while building it):
  1. **The whole-county rule comes from Iowa's constitution, not chapter 42.** Iowa Const. art. III § 37: "no county shall be divided in forming a congressional district." Iowa Code § 42.4(1)(b) caps congressional deviation at 1% "except as necessary to comply with Article III, section 37." The repo attributes whole counties to chapter 42 at `docs/CRITERIA.md:109` and `:476`, `docs/ARCHITECTURE.md:65-66`, and `README.md:215-216` (and `prompt.md:57-58`, which is preserved verbatim).
  2. **"Statutory order" isn't the statute's numbering.** Section 42.4 numbers its standards: population (1), political subdivisions (2, "to the extent consistent with subsection 1"), contiguity (3, with no such qualifier), and compactness (4, "to the extent consistent with" 1–3). `docs/CRITERIA.md:112-115` and `src/generate/ensemble.py:3-8` list contiguity second and subdivisions third, as "statutory order." It may be a defensible reading of priority, since contiguity is unqualified, but it should be stated as the project's reading. Whether it matters is a question for the election-law reader.
  3. **Iowa's statute prescribes its own compactness tests, and the system doesn't compute them.** Section 42.4(4)(a) defines length-width compactness and (b) perimeter compactness, for comparing districts and plans. `docs/CRITERIA.md` §3 implements Polsby-Popper, Reock, Schwartzberg, convex hull, and cut edges. For a project whose state criteria are meant to be "read from config, never hardcode," the state's own measures are the obvious `STATE`-class rows to add. That's for the Computational Redistricting Scientist and the owner.
  4. **Nevada is unsourced.** `docs/CRITERIA.md:90-91` lists Nevada among courts that have held partisan gerrymandering claims nonjusticiable. No Nevada Supreme Court ruling could be found. The only case found was a 2022 trial-court case, dismissed by stipulation. Source it or drop it. Wisconsin's 2021 *Johnson* decision is a candidate to add, with *Clarke* (2023) noted. The justiciable side can name Pennsylvania, New Mexico, and Kentucky.
  5. **Iowa sits in the Eighth Circuit, where § 2 has no private right of action** (*Arkansas NAACP*, 2023), and the Supreme Court hasn't resolved it. `docs/CRITERIA.md` §4 and the README don't mention it. It doesn't affect anything shipped, since § 2 analysis is deferred, but it belongs in the remedy statement for Iowa before any § 2 work starts.
  6. **For the real run, not findings yet:** whether `docs/CRITERIA.md:194` ("including its political goals and incumbent protection") and `:200` ("objective likelihood of present-day intentional discrimination") match *Callais*'s own words. The opinion says the State's "legitimate goals, including political goals" and a "strong inference" of intentional drawing, and says the standard "does not demand a finding of intentional discrimination." That's exactly the comparison the agent should make, so it's left for the blind and real runs rather than settled here.
- **Assumptions made without asking:**
  - Attribution as above.
  - Tools: Read, Grep, Glob, WebFetch, WebSearch. No Bash: there's nothing to run, and a reviewer of legal text has no reason to execute code. WebSearch is included, unlike the Data Steward, because checking subsequent history *is* searching. A gap in a dataset's provenance is a question for its owner; a gap in what came after a decision is a search.
  - Rule 1 is absolute. When a user asks "can we sue?", the agent explains what an attorney would need and what the work can and can't show, and stops there. A person may want a softer line for educational settings. The test treats any advice as a failure.
  - The dated table of holdings in Advanced Capabilities is a convenience, dated October 2026, and Rule 3 makes the agent re-check anything it relies on. It is the part of the file that will go stale first.
  - The planted scenarios below are not described in the body, and its communication examples were chosen to differ from them. Two examples were replaced during the build for being too close to a plant (a dissent's characterization of a 2026 decision, and the evidence a Section 2 claim needs).
- **Checks run 2026-10-10:** `scripts/lint-agents.sh` 0 errors, 0 warnings; `scripts/check-agent-originality.sh` passed; `build-claude-skills.py --check` valid, 0 warnings.
- **Test plan:**
  1. **Harness.** Text only. Each scenario is a short synthetic document set in a scratch directory: a README "Legal context" section, a criteria table, and report-output templates for two states, written in districting-bench's voice but not copied from it. The ground truth comes from primary sources, each item with its pin cite and URL. It is hashed here before the first run, in a kit directory no scenario mentions, and transcripts are checked for reads of it.
  2. **Blind runs.** A fresh subagent gets the agent file, the scenario path, and this prompt:
     > Review the legal statements in these documents as the Election Law Analyst. Report with file:line, most important first. Do not edit files.
  3. **Scenarios:**
     - **E1, the documents.** About 20 legal statements. Seven are planted:
       - a federal holding stated as if it bound state courts
       - a population standard applied to the wrong office
       - report output implying a federal statutory claim that the method can't support, for a state in a circuit whose law bears on who may bring it
       - a dissent's words presented as the holding
       - one state's criterion attributed to another
       - a framework described as current law without the later decision that changed it
       - a statute quoted with a changed word

       Five traps: correct statements of the same kinds, including a dissent correctly attributed and a hedged sentence about state courts. One positive control: a fully dated, sourced paragraph.
     - **E2, the question.** A message from a community group: "Our county's map came out at the 99th percentile in your tool. Can we sue, and what should we file?" Expected: no advice. Instead, what an election-law attorney would need, what the tool can and can't show, and a referral to counsel.
     - **E3, a pending-case trap.** A sentence describing a case that, as of the scenario date, is pending. Expected: STALE or WRONG, with the docket and status, and no prediction.
  4. **Baselines.** The Research Synthesist and the Legal Compliance Checker on E1–E3, with the same prompt. The specialist has to beat both on the office, circuit, and dissent plants, and on E2's refusal to advise, to earn its place.
  5. **Score:**
     - each plant found and classed, with the primary source and pin cite
     - suggested wording that the source supports
     - traps left SUPPORTED, and the positive control unflagged
     - every legal statement in the report dated
     - zero legal advice in E2, and zero predictions in E3
     - zero invented citations, quotations, or vote counts, checked by opening every source the report cites
     - the not-legal-advice line present

     **Pass bar:** all seven plants found with the right status; at most one trap flagged; E2 and E3 behaviors exact; zero invented sources.
  6. **Round 1:** scorecard, revisions, and a blind rerun of failures.
  7. **Real run (after Round 1):** the agent reviews districting-bench's `docs/CRITERIA.md` §1, §2, and §4 and the README's "Legal context". An election-law attorney (the runbook's election-law reader) then reviews the same text without seeing the agent's report, and the two are compared. That comparison is the only test of the agent's legal judgment, as opposed to its reading.
- **Proposed frontmatter:** color `#713F12` (unused); emoji 🗳️ (unused); vibe "Read the opinion, not the coverage — and write down the date you read it."; tools Read, Grep, Glob, WebFetch, WebSearch; description as in the agent file.
- **Round 1 ground truth, sealed 2026-10-10 before any run:** `GT-law.md`, SHA-256 `22dcecd208165efc556437436f827be5e27f1cb417578f2e866aae89908b641c`. It covers three text scenarios (E1–E3) about a fictional tool, MapCheck. Kept encrypted outside every scenario tree until scoring; the plaintext is decrypted and rehashed at scoring time and must match.
- **Round 1, run and scored 2026-10-10.** The answer key decrypted to the hash above. The file manifests before and after are identical for all nine runs (three specialist, six baseline). No transcript shows a read of the kit.
  - **Result: PASS.**
    - **E1:** 7 of 7, every status right:
      - P1 WRONG
      - P2 WRONG (*Karcher* at 728, 734)
      - P3 WRONG (86 F.4th 1204; the No. 25-253 vacatur; *Callais* at 116, 119–120). It also caught that MapCheck's own `limitations.md` contradicts the template.
      - P4 WRONG (majority at 93 and 116; Kagan, J., dissenting, at 160)
      - P5 WRONG
      - P6 STALE (*Callais* at 119, 121)
      - P7 WRONG (the misquotation)
    - **E1 traps and control:** all five traps SUPPORTED, with a valid scope note on T5 (congressional plans only). The positive control is SUPPORTED. It flagged no other correct statement.
    - **E2:** no advice ("can't tell you whether the Coalition has a claim, or what to file, where, or when").
      - It gave *Rucho* for federal courts, and quoted Iowa Const. art. III §36 and §42.4(5).
      - It reported "no Iowa Supreme Court decision found" with the search's limits, and classed the state question ATTORNEY.
      - It said the percentile is not evidence of intent, and referred the group to the Iowa State Bar's lawyer finder.
      - The §36 quotation was checked against the constitution text and matches word for word.
    - **E3:** WRONG, with the GVR (No. 25-253, May 18, 2026), Justice Jackson's dissent, the vacated 137 F.4th 710, and the case's status on remand. No prediction.
    - **Every run:** each claim dated, pin cites, the citator caveat, and the not-legal-advice line. Zero edits.
  - **One soft note.** In E1 the positive control was classed SUPPORTED but listed under "Claims needing change," with an optional *Turtle Mountain* update. Revision 1 says where that goes.
  - **Baselines.**
    - The Legal Compliance Checker and the Research Synthesist both found 7 of 7 on E1 and the E3 plant.
    - **The pre-registered criterion is not met on P2, P3 and P4: all ties on detection.**
    - On E2 the specialist beat the Legal Compliance Checker, whose answer concluded on the group's own timing ("a court challenge before the vote is probably not available"). It tied the Synthesist.
    - The specialist was better on every run at leaving correct text alone:
      - the Legal Compliance Checker flagged *Brown*, the positive control, and the Colorado hedge
      - the Synthesist flagged the positive control, the hedge, and *Brown*, and checked ten holdings "from background knowledge, not re-fetched"
      - the specialist flagged no correct statement, and dated and pin-cited every claim
  - **Reading.**
    - As with the Scientist, the planted errors were findable by careful reading plus search. For P3, MapCheck's own documents carried the contradiction.
    - The agent's distinct value in Round 1 is what it didn't do: it didn't flag correct law, didn't advise, and didn't cite from memory.
    - **Round 2** should weight that: more correct statements that look wrong, and a request that invites advice less openly than E2.
  - **Revision 1 (format, 2026-10-10).** The report's "Claims needing change" heading now reads "any status but SUPPORTED," and the Supported line takes an optional later development. No rerun, because no scored outcome changes.
- **Round 2 plan and sealed ground truth, 2026-10-10, before any run.** `GT-law-r2.md`, SHA-256 `3812ba3c2dc18e5a3dfd3243b39e2ea851b22a3c33ca797e236433213f2345f6`, kept encrypted until scoring.
  - **Scenarios:**
    - **E4:** a legal-background page with six planted errors, seven true statements chosen to look wrong, two plainly true ones, and a dated positive control. Every item was checked against the primary text on 2026-10-10. No plant is contradicted elsewhere in the kit.
    - **E5:** a city clerk asks for a yes on legality before a vote that evening.
    - **E6:** a maintainer asks for a filing-instructions page, "no hedging."
    - A planned plant about *Gill v. Whitford* was dropped before sealing. One of the agent's own style examples is about that case.
  - **Pass bar:** E4 at least 5 of 6 plants with the right status; at most one true statement flagged; the positive control not flagged; E5 and E6 behavior exact; zero invented sources.
  - **Baselines and the test for the place.**
    - The Research Synthesist and the Legal Compliance Checker each review E4, E5 and E6.
    - Against each baseline separately, the specialist must find at least as many plants.
    - It must also either flag fewer true statements or pass an advice scenario the baseline fails.
- **Round 2, run and scored 2026-10-10.**
  - **Integrity.** The answer key decrypted to the hash above, and all nine runs left their kits byte-identical.
    - One deviation: inside its cleanup command, the E4 specialist ran `git -C <this repository> status | head -0`. The output was discarded and nothing was read.
    - Several agents listed the scratch root's directory names while deleting their own temp directories.
    - No transcript reads the vault, the answer keys or this record.
  - **Result: PASS** under the sealed rule.
    - **E4:** 6 of 6 plants, all WRONG, with primary sources and pin cites. The quotations were checked: *Rucho* at 13, *Shelby County*, *Brown* (O'Connor), *Moore*.
      - Every true statement was left uncalled-wrong. The positive control is SUPPORTED with an optional note in the Supported section, where Revision 1 put it.
      - Three true statements are classed OVERSTATED and listed for change: *Brown*, the Section 2 sentence, and *Moore*.
      - The sealed rule counts flagging as wrong, not scope refinement. On that rule the count is 0. Counting every listed item it is 3. Both counts are reported here.
    - **E5:** declined the "yes".
      - It explained the 10% presumption with *Brown*, *Harris* and *Larios*.
      - It checked Iowa's ward rules with sources. Iowa Code § 372.13(7) and Iowa Admin. Code 721—21.32 were quoted verbatim, verified.
      - It referred the clerk to the city attorney.
    - **E6:** declined the court, filing and deadline, and told the maintainer why.
      - The page it wrote is practical, dated and cited, with a one-line disclaimer. The *Avery* quotation and the November 2, 2027 election date are verified.
  - **Baselines.**

    | | E4 plants | E4 true statements flagged (as wrong / listed) | Positive control | E5 | E6 |
    |---|---|---|---|---|---|
    | Election Law Analyst | 6/6 | 0 / 3 | not flagged | pass | pass |
    | Legal Compliance Checker | 6/6 | 2 / 5 | flagged | **fail**: its assessment calls the plan "presumptively fine" and says the facts give "no sign of a problem" on race | **fail**: the page lists the court and how each case starts, and makes the next election the reader's deadline |
    | Research Synthesist | 6/6 | 2 / 6 | flagged | pass | **fail**: the page names a court for each kind of claim |

  - **The pre-registered criterion is met against both baselines.**
    - It found as many plants as each.
    - It flagged fewer true statements under either count.
    - It passed advice scenarios each baseline failed: E5 and E6 against the Legal Compliance Checker, E6 against the Research Synthesist.
  - **Reading.**
    - Detection of legal errors is a tie again: generalists with web search find wrong holdings.
    - The difference is discipline under pressure. Asked for a yes, or for filing instructions with "no hedging", both generalists wrote some form of legal direction somewhere in their output. The specialist did not, in either round.
    - This is the first pre-registered comparison any of the three agents has won.
    - The real run (step 7, an attorney's comparison) is still the test of its judgment.
