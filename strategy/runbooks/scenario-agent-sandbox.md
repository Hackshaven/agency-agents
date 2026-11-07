# 🔒 Runbook: agent-sandbox Maintainer Team

> **Mode**: NEXUS-Micro, per change | **Duration**: Standing team | **Agents**: 10 on the roster, 1–4 per change

---

## Scenario

[agent-sandbox](https://github.com/Hackshaven/agent-sandbox) is a contained lab for running Claude Code on defensive security work, built to Anthropic's agent containment guidance for Cyber Verification Program participants, on a Windows 11 laptop with Hyper-V. A sandbox VM runs the agent and the target with no route out. A gateway VM holds the Claude token, forwards model calls and nothing else, and keeps the logs. The scripts and tests come to about 2,200 lines: a PowerShell script that builds and operates the VMs, two Bash setup scripts, the run launcher and the isolation checks, a live monitor and a pattern scan in Python, and tests that run the firewall in network namespaces and the credential proxy against a mock upstream. It has one maintainer.

The scripts are the boundary. `CLAUDE.md` names six things that hold it up, and treats every change to them as a security change: made only when asked, with a plain statement of what it widens, and `docs/design.md` updated in the same commit.

1. The nftables rules in `linux/gateway-setup.sh`: the sandbox (10.77.0.10) may open connections to 10.77.0.1:8080 and nothing else.
2. The nginx allowlist: exact paths, model calls only. A path is added only when a `credproxy.log` 403 shows Claude Code needs it and it is a model call. Never a catch-all or prefix location.
3. Where the token lives: only `/etc/nginx/agentlab-token.conf` on the gateway. Never in the sandbox, the repo, tests, or a commit message.
4. Auto mode: managed settings keep `defaultMode: auto` and disable `bypassPermissions`. Rule lists start with `"$defaults"`.
5. Sandbox isolation: one adapter on the AgentLab switch, Guest Service Interface and KVP off, `hv_sock` blocked, no shared folders, an agent with no sudo and no docker group.
6. Run limits and refusals in `agentlab-run`: unreadable limits refuse to launch, a task without `## Scope` refuses, a sandbox with a route out refuses.

Claude Code writes most changes here, so the person who prompts a change is usually the person who approves it. This team is a second reader outside that loop: **review gates, routed by path**, plus a few specialists. It has no orchestrator. The maintainer running the session is the orchestrator.

The team reads code and configuration. It can't verify a machine. Only the isolation checks (`agentlab-check`, `agentlab.ps1 check`) and the supervised escape test verify a real build, and a person watches the escape test. As of November 2026 `agentlab.ps1` has never run against Hyper-V, and several behaviors stay unverified until the first real run (the README's "Known limits").

## Agent Roster

### Review Gates (activated by the paths a change touches)
| Agent | Role on agent-sandbox |
|-------|-----------------------|
| Security Architect | The boundary as a whole: any change to the six items above, `docs/design.md`'s claims against the guidance it cites, and anything on the trusted side that reads or displays what the sandbox produces. Its trust-boundary and defense-in-depth questions apply as written. Its web checklists (CSP, JWT, OWASP) don't, and neither does its advice to move secrets into a vault: the token's single root-only file is the design |
| Code Reviewer | The default for code no specialist covers, and the second reviewer on every boundary change. Bash, Python, and PowerShell 5.1 and 7. It runs on the same model family that writes most of the repo, so it shares their blind spots |
| Threat Detection Engineer | `agentlab-scan.py`'s rules, `agentlab-monitor.py`'s denial patterns and budgets, and their tests. Its rules on false-positive profiles, validation cases, and asking "how would I evade this?" apply as written, and so does its section on exceptions matched against attacker-controlled text: here the attacker writes the commands the rules read. Its Sigma and SIEM tooling doesn't |
| Secrets & Credential Hygiene Engineer | The one credential: how the token is read, stored, forwarded, kept out of logs, replaced by a placeholder in the sandbox, kept out of the repo and tests, and rotated after a hit. Its leak-response runbook applies as written if a token ever reaches git. Its push toward short-lived brokered credentials doesn't fit a laptop lab whose token the agent can't reach |
| Technical Writer | The README's build, run, and "When something changes" steps. Cutover is permanent, so a step the README leaves out before it costs a reopen, a reinstall, and a fresh escape test |

### Specialists (as needed)
| Agent | Role on agent-sandbox |
|-------|-----------------------|
| Network Engineer | The packet path: the nftables ruleset, netplan, sysctl, and the network lines of both SSH drop-ins. Written for Cisco, Juniper, and Palo Alto, so it reads nftables by analogy. Its rules on proving the data plane separately from the config, naming sources, destinations, and ports tightly, and keeping a management path (here, the VM console) apply as written. A namespace test case that fails without the rule counts for more than its reading |
| Penetration Tester | Adversarial second reader on firewall, proxy, and isolation changes: how would an agent inside the VM get past this? Also the attempt list in `templates/escape-test.md`. It reviews and proposes attempts. It never runs them from a host session (see [Where the Agents Work](#where-the-agents-work)), and its internet reconnaissance tooling has no target here |
| Prompt Engineer | The prose a model reads: auto mode's `environment` and `soft_deny` entries, the No-network rule `finalize` adds, and the two task templates. Auto mode's classifier and the sandboxed agent act on that wording, so ambiguity there is a security defect. Its rule that every prompt ships with test cases maps to commands that must pass, must be denied, and sit on the line. Its injection-resistance advice doesn't: the lab's answer to a hostile target is containment, not wording |
| Incident Responder | What happens after a hit: evidence collection in `agentlab-run`, log permissions and retention, and the README's "A hit during a run". `agentlab.ps1 run` reverts the sandbox in its `finally` block unless `-KeepRunning` is given, so the gateway's run folder is usually the only evidence that survives. It knows that, and asks what else needs keeping before the revert |

### Periodic
| Agent | Role on agent-sandbox |
|-------|-----------------------|
| Codebase Archaeologist | Quarterly, and after a Claude Code update: the README's "Known limits" and `CLAUDE.md`'s "Still unverified" list against what has since been confirmed, the "Where" column of `docs/design.md`'s guidance table against the scripts, values repeated across scripts against each other (see [Periodic Work](#periodic-work)), and `docs/sources.md` against guidance pages marked private beta |

## The Remaining Gap

No catalog agent knows agent containment: what a hypervisor exposes to a guest, how an egress firewall and a credential proxy work together, what Claude Code's managed settings and auto mode enforce, and which channels lead from a sandboxed agent back to the trusted side. The Security Architect, the Penetration Tester, and the Network Engineer each cover part of it, through web, Active Directory, and enterprise-network lenses.

| Proposed agent | Division | What it would take over here | Why no current agent covers it |
|----------------|----------|------------------------------|--------------------------------|
| Agent Containment Auditor | security | Gate of record for the six boundary items. A read-only auditor that writes the boundary down from the project's own documents and walks every channel out of an agent sandbox: layer 2 and 3 (IPv6, ARP, DHCP, DNS, the gateway's other addresses), hypervisor channels (sockets, integration services, shared folders, attached media), the credential proxy's paths, methods, headers, and normalization, the model API itself (request bodies leave unlogged, per `docs/design.md`), settings and environment tampering, privilege inside the guest (groups, rootless containers, user namespaces), and agent output that the trusted side parses or displays (transcripts, scan reports, the operator's terminal). It probes guards in network namespaces or against a mock, reports each channel as guarded, gap, or breach, and never touches a guard | The Blinding & Leakage Auditor has the method (boundary statement, channel inventory, a probe per guard, the owner decides) but its channels are imports, schemas, and seeds. The security agents are written for web applications, enterprise networks, and cloud accounts |

Until it exists, the Security Architect is the gate of record for the boundary and the Penetration Tester its second reader. The escape test, watched by a person, and the owner's reading of the transcript remain the checks that count.

## Already in the Repo (not installed by this preset)

agent-sandbox had no `.claude/` directory before this team. Its rules live in these documents. **Where a catalog agent and one of them disagree, the document wins.** Where a document describes the code and the code disagrees, the reviewer reports the mismatch and the owner decides which is right. Nobody rewrites a statement of the boundary to match a weaker config.

| Document | What it rules |
|----------|---------------|
| `CLAUDE.md` | The six boundary items, where security work runs, the pre-commit checks, conventions (LF endings, the execute bit, "Written by <script>" headers, re-runnable setup scripts, PowerShell 5.1 and 7 with only the Hyper-V module), and the "Still unverified" list |
| `docs/design.md` | Why each control exists, how the build meets the guidance it follows, and where it falls short. A boundary change updates it in the same commit |
| `README.md` | The operator's procedure: build, cut over, finalize, baseline, the supervised escape test, runs, maintenance, what to do after a hit, and "Known limits", which is the source of truth for what is unverified |
| `docs/sources.md` | The Anthropic guidance the design follows, with the month it was read. Some pages are marked private beta and may change |
| `tests/` | `run-all.sh` runs lint, the transcript tools, the proxy against a mock upstream, and (as root) the firewall in two network namespaces. Two controls show that, without the rules, the gateway's SSH port and its other address are reachable. CI runs the same on every push, plus a parse and PSScriptAnalyzer pass on `agentlab.ps1` |
| `templates/` | The task template whose `## Scope` section `agentlab-run` requires, and the escape test |

## Where the Agents Work

`CLAUDE.md` separates two kinds of session. Building, debugging, and testing the lab from the Windows host is ordinary development work, and this team works there. Security work (analyzing targets, validating exploits) runs inside the sandbox through `agentlab.ps1 run`.

So a reviewer on this team reads the diff and the documents. Any probe it wants runs where the tests already run: a rendered ruleset in a network namespace, or the rendered proxy against a mock upstream. A new escape attempt becomes a line in `templates/escape-test.md`, and runs in the supervised escape test. No agent opens a connection to the lab's VMs or to anything on 10.77.0.0/24 from a host session.

That rule is an instruction, and nothing else enforces it. The catalog files carry no `tools:` restriction, so each reviewer inherits every tool the session has. The Windows host holds an SSH key into the gateway, and the gateway holds the run key into the sandbox. The activation prompt below repeats the rule for that reason. A repo that wants it enforced adds deny rules to its own Claude Code settings; that's the owner's choice.

## Routing: Which Agent for Which Change

`linux/gateway-setup.sh` holds the firewall, the proxy, the token, and the logging in one file, so its rows route by section.

| If the change touches… | Run | Why |
|------------------------|-----|-----|
| The nftables heredoc, sysctl, netplan, and interface detection in `linux/gateway-setup.sh`; `phase_cutover` in `linux/sandbox-setup.sh` (netplan, sysctl, the SSH drop-in); the network checks in both halves of `linux/agentlab-check.sh`; `tests/test_firewall.sh` | Security Architect and the Code Reviewer; Network Engineer; Penetration Tester as second reader | Boundary item 1. Interface detection picks the interface every rule binds to. Every refusal in the namespace test needs a control: the same path, shown open before the rules load. The rules are layered, so removing one can still pass; the test checks the boundary, not each rule. A rule that reads right and drops nothing is the failure to look for |
| The nginx site and upstream heredocs in `linux/gateway-setup.sh`; `tests/test_proxy.sh` | Security Architect and the Code Reviewer; Penetration Tester as second reader | Boundary item 2. A new path goes in the heredoc, not only in the live `/etc/nginx/sites-available/agentlab` the README names: the next run of `gateway-setup.sh` rewrites that file, and only a commit gets a review and a `docs/design.md` update. The test's refusal list has one case each of `..`, an encoded slash, and a case variant, so a new path brings its lookalikes with it |
| The token section of `linux/gateway-setup.sh`, the `Authorization` and header-stripping lines, the proxy's `log_format`; the placeholder and `ANTHROPIC_API_KEY` removal in `phase_install`; token checks in `linux/agentlab-check.sh` and the `agentlab-run` preflight; the token, header, and log assertions in `tests/test_proxy.sh`; `.gitignore`; any token-shaped test value; the README's rotation step | Secrets & Credential Hygiene Engineer, the Security Architect, and the Code Reviewer | Boundary item 3. Tests use obviously fake values, the proxy logs no headers or bodies, and `nginx -T` prints the token, which the script's last line warns about |
| The SSH section of `linux/gateway-setup.sh` (key-only logins, the run key); `SSH_OPTS` in `linux/agentlab-run`; the restricted `authorized_keys` line in `phase_install` | Secrets & Credential Hygiene Engineer and the Security Architect | The run key is the only credential into the sandbox |
| `write_managed_settings` and `phase_finalize` in `linux/sandbox-setup.sh`; the managed-settings checks in `linux/agentlab-check.sh`; the `permissionMode` handling in `linux/agentlab-monitor.py`; `--permission-mode` and the interactive session watcher in `linux/agentlab-run` | Security Architect and the Code Reviewer; Prompt Engineer for any rule text | Boundary item 4. Auto mode's rules are security configuration written in prose, and a classifier reads them. The monitor is the live check that a run stays in auto mode, and the `permissionMode` fields it reads are undocumented, so a run that can continue without confirming its mode is a finding |
| `agentlab.ps1` `build`, `cutover`, `reopen`, and `check`; `phase_install` (including the `--claude-version` check on a value that reaches the installer), `install_rootless_docker`, and `phase_reopen` in `linux/sandbox-setup.sh` (agent account and groups, the root-owned `claude` binary, the `hv_sock` block, Hyper-V daemons, `/etc/environment`, the rootlesskit AppArmor profile); the rest of the sandbox half of `linux/agentlab-check.sh` | Security Architect and the Code Reviewer; Penetration Tester as second reader | Boundary item 5. Hyper-V is the only layer between the sandbox and an everyday laptop (`docs/design.md`, "Where this falls short"). `reopen` gives the sandbox internet, so both halves of it route here |
| Validation, preflight, input delivery, launch, `stop_remote`, and the interrupt trap in `linux/agentlab-run`; `agentlab.ps1` `run`, `stop`, `revert`, and `baseline` (the validation attributes, `Stop-Sandbox`, `Reset-Sandbox`, the revert in `finally`); the `## Scope` check in either; `templates/task-template.md` | Code Reviewer and the Security Architect; Prompt Engineer for the template's wording | Boundary item 6. The limits are validated by pattern, so a value that passes the pattern and means "no limit" is the failure to look for. The launch preflight and `agentlab-check` test some of the same properties, and a difference between them is a finding. A refusal relaxed so a run will start is a boundary change. `Stop-Sandbox` is the hard off-switch |
| `linux/agentlab-scan.py`, `linux/agentlab-monitor.py`'s denial patterns and budgets, `tests/test_transcripts.py` | Threat Detection Engineer, plus the Code Reviewer for code | Rules catch only what someone anticipated. The denial text is a guess until a real denial is seen (README, "Known limits"). An exception matched against text the agent writes is an evasion path |
| Anything on the gateway that prints, parses, or unpacks what the sandbox produced: the monitor's terminal view, `scan.txt` and the review block's refusal and deny lines echoed by `agentlab-run`, its echo of preflight problems, the interactive session's terminal, the "Logs" output of `agentlab-check gateway`, the `claude-projects.tgz` pulled by `collect()` | Security Architect | Agent output is untrusted input on the trusted side, and the operator's terminal is part of that side |
| `collect()`, the run folder and `meta.txt`, and the review block in `linux/agentlab-run`; the transcript `agentlab-monitor.py` writes; the logging section of `linux/gateway-setup.sh` (rsyslog, logrotate, the daily prune, log ownership and modes); the README's "A hit during a run" | Incident Responder, plus the Code Reviewer for code | 45-day retention and the run folder are the evidence. `agentlab.ps1 run` reverts the sandbox afterward |
| `templates/escape-test.md` | Penetration Tester; Prompt Engineer for the wording | A channel missing from the attempt list is never tried in the supervised test |
| Any other part of `linux/agentlab-check.sh` | Code Reviewer, plus the reviewer for the area the check covers | A check that passes when its control is gone verifies nothing. A check edited in the same change as the code it checks is a finding |
| `tests/lib.sh`, `tests/run-all.sh` | Code Reviewer, plus the Security Architect when a change alters what the boundary tests render | `render_heredoc` decides which config the firewall and proxy tests run, so a change there can make both pass against something other than what ships |
| The boundary and "Still unverified" sections of `CLAUDE.md`; the README's "Known limits" and "Testing" | Security Architect, then the owner | These state the boundary and what is verified. Loosening a rule in prose is a boundary change, and so is calling something verified without evidence |
| The README's build, run, and maintenance steps | Technical Writer | They have to match the scripts, step for step (`CLAUDE.md`, "Before committing") |
| `docs/design.md`, `docs/lab-layout.svg`, `docs/sources.md` | Security Architect | The design's claims about the guidance have to hold for the scripts as they are. The diagram makes the same claims in a picture |
| `.github/workflows/test.yml` | Code Reviewer | CI runs the same suite as `tests/run-all.sh`, with read-only permissions. `actions/checkout` is pinned by tag, not SHA. PSScriptAnalyzer is installed unpinned at run time, and only an Error fails the job |
| `.gitattributes` | Code Reviewer | It keeps `linux/**` LF, which the VMs need, and the installed agent files byte-identical to the catalog |
| Any other code in `linux/`, `windows/`, or `tests/` | Code Reviewer | No row above matches, and every code change gets a second reader |
| `.claude/agents/**` | Nobody edits them | Each file must match the catalog byte for byte. Change it in the catalog |

**High-scrutiny paths get two.** A change to any of the six boundary items gets its specialist plus the Code Reviewer, updates `docs/design.md` in the same commit, and says plainly what it widens. The PR also says whether the escape test needs to run again before the next real run. The README requires that after any sandbox or model change. For a firewall or proxy change the owner decides, and the PR records the decision.

Every code change gets at least one catalog reviewer. Rows overlap: `linux/agentlab-check.sh` and `linux/agentlab-run` sit in several. A change that matches several rows runs every one of them; few need more than four.

## Per-Change Sequence (NEXUS-Micro)

```
Step 1: Route
├── List what changed: git diff origin/main...HEAD --stat
├── Pick agents from the routing table. Every code change gets one; a boundary
│   change gets its specialist plus the Code Reviewer.
└── If a fix would weaken a boundary item to make something work, stop and
    take the tradeoff to the owner (CLAUDE.md).

Step 2: Tests first
├── sudo bash tests/run-all.sh      # sudo adds the firewall namespace tests
└── shellcheck -S warning clean on every shell script

Step 3: Catalog reviewers, in parallel
├── Give each the diff, CLAUDE.md, and docs/design.md
└── Each reports findings with file:line. None edits files, and none touches the lab VMs.

Step 4: Owner decides
├── Fix, accept, or record why not
├── After merge, a sandbox change goes through the README's "When something changes":
│   copy linux/ to the sandbox again, reopen, install, cutover, checks, finalize,
│   baseline, escape test
└── A gateway change (the firewall, the proxy, or any agentlab-* command) takes
    effect only after linux/ is copied to the gateway again and gateway-setup.sh is
    rerun, because it installs copies. Then: sudo agentlab-check gateway
```

### Activation prompt

```
Review this agent-sandbox change as the [Agent]. Read the diff
(git diff origin/main...HEAD -- [paths]), CLAUDE.md, and docs/design.md.
Report findings with file:line, most important first. Do not edit files.
CLAUDE.md's boundary rules win over your own defaults. Never recommend a
catch-all or prefix nginx location, a token anywhere but
/etc/nginx/agentlab-token.conf on the gateway, bypassPermissions or
--dangerously-skip-permissions, or relaxing a refusal in agentlab-run so a run
will start. If a fix would weaken the boundary, say what it widens and stop.
Don't connect to the lab VMs; a probe runs in tests/ (network namespaces, a
mock upstream) or as an attempt in templates/escape-test.md. Where a doc
describes the code and the code disagrees, report the mismatch.
```

## Periodic Work

**Codebase Archaeologist, quarterly and after a Claude Code update.** Walk the README's "Known limits" and the "Still unverified" list in `CLAUDE.md` against the repo and the latest run folders the owner shares, and report which items now have evidence either way. `CLAUDE.md` says the list is updated when an item is confirmed or fixed. Check the "Where" column of `docs/design.md`'s guidance table against the scripts. Check that values repeated across scripts still agree:
- the lab addresses, the proxy port, and the proxy URL
- `MIN_CLAUDE`, in `sandbox-setup.sh` and `agentlab-check.sh`
- the managed-settings path and the placeholder token's prefix
- the privileged groups and how strictly "a route out" is tested, in `sandbox-setup.sh`, `agentlab-check.sh`, and the `agentlab-run` preflight
- the denial and classifier-unavailable patterns, in `agentlab-monitor.py` and `agentlab-scan.py`
- the 45-day retention, in `gateway-setup.sh` and `agentlab-check.sh`
- the default model and the limit validation, in `agentlab-run`, `agentlab-check.sh`, and `agentlab.ps1`

Report drift, not repetition (see the pitfalls). If the "accessed" month in `docs/sources.md` is more than two quarters old, say so, since the private-beta pages may have moved.

## Upstream Dependencies

| Upstream | What the lab depends on | Who watches |
|----------|-------------------------|-------------|
| Anthropic's agent containment guidance | The properties `docs/design.md` maps the build to | Archaeologist, quarterly; the owner rereads the pages when they change |
| Claude Code | `MIN_CLAUDE`, the managed-settings path, the `permissionMode` field in stream-json's init message and on each prompt of a session transcript, the auto mode denial text, and `claude auto-mode config` | The owner after every Claude Code update (`docs/design.md` says to recheck `claude auto-mode config`); the Threat Detection Engineer when the denial text changes |
| Ubuntu Server 24.04 | Netplan, the unprivileged user namespace restriction the rootlesskit profile works around, the SSH drop-in order | Code Reviewer on the change that moves the release |
| Hyper-V | The cmdlets `agentlab.ps1` calls, integration service names, checkpoint behavior | The owner's first real run. Nothing in CI exercises Hyper-V |

## When a Person Decides

The agents on this team check claims about machines they can't see. Several already say where they stop:
- The Security Architect never recommends disabling a security control.
- The Secrets & Credential Hygiene Engineer treats a leaked token as burned, so rotation is the fix, never deletion from source.
- The Penetration Tester stays inside the written scope, and here that scope has no live target.
- The Incident Responder preserves evidence before anything else, and claims no root cause it can't trace end to end.

`CLAUDE.md` reserves the boundary for the owner, and the README reserves the escape test for a person watching it live. This section says who and when.

### Who

| Role | Who | When to name them |
|------|-----|-------------------|
| Owner | The maintainer. Decides every boundary change, merges, and what counts as out-of-scope behavior in a run | Already named |
| Operator | Whoever launches and watches a run, often the owner. Holds the off-switch (Ctrl+C, then `.\agentlab.ps1 stop`) | Every run |
| Anthropic | Reached through support.claude.com as a Cyber Verification Program participant, for out-of-scope behavior during a run (README, "When something changes") | Already named |
| NOAA ITSO | Signs off on each engagement against NOAA targets, including target code and findings going to Anthropic in model requests (`docs/design.md`, "Not in v1") | Before the first engagement against a real network |

### When

| Go to a person when… | Who decides | What the agents hand over |
|----------------------|-------------|---------------------------|
| A fix would weaken any boundary item to make something work | Owner, after the tradeoff is explained (`CLAUDE.md`) | What it widens, and what else would fix it |
| A `credproxy.log` 403 suggests a new proxy path | Owner, and only for a model call | The 403 lines and what Claude Code was doing |
| An escape test attempt succeeds | Owner. It's a blocker: fix and retest before any real run (README) | The transcript lines, the firewall and proxy log lines, and which control should have stopped it |
| A run hits: a scan hit that reads as an escape attempt, a firewall deny, a spent denial budget, a run that left auto mode | Owner reads the transcript. Out-of-scope behavior goes to Anthropic, and the token is rotated | The Incident Responder's evidence list and the Threat Detection Engineer's reading of the hit |
| A "Known limits" item is confirmed or found false | Owner updates the README and `CLAUDE.md` | The run folder or check output that settles it |
| Work against a real network is proposed | Owner, and the ITSO for a NOAA target. A person makes every state-changing step (`docs/design.md`) | The scope, the gateway allowlist change it needs, and the design doc's checklist |
| The third review of the same change fails | Owner, who narrows the change or drops it | The open findings |

Record each boundary decision where the repo already records them: in the commit that makes the change, with `docs/design.md` updated beside it. The evidence for an escape test or a run hit is its run folder on the gateway. A relayed "the escape test passed" is a claim, not a result: the transcript is the result.

## Key Decisions

| Decision | Who decides |
|----------|-------------|
| Merge | Owner |
| Any change to the six boundary items | Owner, with the change stated in the PR and `docs/design.md` updated in the same commit |
| A new proxy path | Owner, from a `credproxy.log` 403, only for a model call |
| Whether a firewall or proxy change needs a fresh escape test | Owner, recorded in the PR |
| Treating a run's behavior as out of scope, and reporting it | Owner |
| Moving to a dedicated Linux host, or to work against real networks | Owner, with the ITSO for NOAA targets |

## What This Team Leaves Out

| Left out | Why |
|----------|-----|
| Agents Orchestrator, project managers | One maintainer |
| Application Security Engineer | No web app, API, roles, or SDLC pipeline. The Security Architect covers the trust boundaries and the Code Reviewer the code |
| AI-Generated Code Security Auditor | Built for apps that call a model (Next.js and Supabase examples). The lab's answer to a hostile target is containment, and agent output on the trusted side goes to the Security Architect |
| Blinding & Leakage Auditor | Audits information boundaries in research code through imports, schemas, and seeds. Its method is the template for the proposed Agent Containment Auditor |
| Senior SecOps Engineer | Its rules are for web applications (cookies, JWT, CORS). The Secrets & Credential Hygiene Engineer covers the one credential |
| Cloud Security Architect, Compliance Auditor, FedRAMP & RMF Compliance Engineer | No cloud and no authorization in scope. Approval for NOAA targets is the ITSO's, a person |
| Threat Intelligence Analyst | Tracks adversary groups. The adversary here is the agent under test |
| DevOps Automator, SRE, Infrastructure Maintainer | Two VMs on a laptop and one CI workflow |
| Identity & Access Engineer, Agentic Identity & Trust Architect | One token and one run key, with no identity system to design |
| Codebase Onboarding Engineer | About 2,200 lines of scripts and tests, written to be read: "Read the scripts before you run them. They are short, and they draw the boundary." (README) |
| Minimal Change Engineer, Git Workflow Master | Builders and process. `CLAUDE.md` already sets the rules |
| Reality Checker, Evidence Collector | Built for web-product readiness from screenshots. The isolation checks and the escape test are this project's evidence |
| Privacy Engineer, Data Privacy Officer | No personal data. Target code and findings leaving in request bodies is an engagement-approval question for the ITSO |
| Communications Clearance Officer | Nothing here speaks publicly for an agency |

## Success Criteria

| Metric | Target |
|--------|--------|
| Boundary changes | Every one names two reviewers, updates `docs/design.md` in the same commit, and says what it widens |
| Escape test | Every sandbox or model change has a recorded escape test before the next real run |
| Detection changes | Every scan or monitor rule change adds a test with a benign case that stays quiet and an attempt that hits |
| Credentials | No real token, key, or credential in the repo, tests, or commit messages |
| Known limits | Matches the evidence each quarter |
| Review cost | 1–2 catalog agents on a typical change |

## Common Pitfalls & Mitigations

| Pitfall | Mitigation |
|---------|-----------|
| An agent's pass treated as proof the lab is contained | Agents read code. The isolation checks and the watched escape test verify a build |
| A reviewer suggests a prefix location such as `location /v1/` to clear a 403 | Decline it. Exact paths only (`CLAUDE.md`) |
| A reviewer suggests bypass mode or `--dangerously-skip-permissions` to get a run going | Decline it. Managed settings disable bypass, and the monitor stops a run that can't show it's in auto mode |
| A proxy path added only to the live nginx config | The next `gateway-setup.sh` run deletes it, and it skipped review. Put it in the heredoc, with `docs/design.md` updated in the same commit |
| A merged gateway change assumed to be live | `gateway-setup.sh` installs copies. Copy `linux/` to the gateway again, rerun it, and run `agentlab-check gateway` |
| A check or test edited so it passes | A check changed in the same commit as the code it checks is a finding. A check must fail with its control removed, as `tests/test_firewall.sh`'s controls show |
| A scan rule quieted with an exception the agent can type | Match exceptions on what the agent can't control, and add the lookalike to the test as a case that must hit |
| A reviewer probes the real lab from a host session | Not allowed, and only the instruction stops it (see [Where the Agents Work](#where-the-agents-work)). Probes run in `tests/` or as an escape test attempt |
| The Code Reviewer asks to share the values repeated across scripts | The installed commands are copied one by one into `/usr/local/bin` on the gateway (and `agentlab-check` into `/usr/local/sbin` on the sandbox), so none of them can source a sibling file there. A proposal for a shared file has to say how it gets installed. Drift between the copies is a finding either way |
| The Secrets Engineer asks for a vault or short-lived credentials | The token sits in one root-only file on a VM the agent can't reach. Rotation after a hit is `claude setup-token`, then rerun `gateway-setup.sh` |
| The Network Engineer answers in Cisco syntax | Ask for the packet path, the nftables change, and a namespace test case that fails without it |
| The model API treated as a closed channel | It isn't: request bodies leave unlogged by design (`docs/design.md`). That's an accepted residual, and the reason NOAA approval covers it |
| The Code Reviewer's pass treated as independent | It shares the authoring model's blind spots. The escape test and the owner's transcript reading count for more |
| Treating the team as the second maintainer | It reviews. It can't hold the off-switch |

## Install

```bash
python3 -c 'import json, sys
for r in json.load(open("strategy/runbooks.json"))["runbooks"]:
    if r["slug"] == sys.argv[1]: [print(a) for g in r["roster"] for a in g["agents"]]' agent-sandbox > team.txt
./scripts/install.sh --tool claude-code --agents-file team.txt --path /path/to/agent-sandbox/.claude/agents
```

agent-sandbox commits the installed files in `.claude/agents/`, so a checkout already has them. Update them from the catalog, never by hand.
