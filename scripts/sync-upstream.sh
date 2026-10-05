#!/usr/bin/env bash
#
# sync-upstream.sh — keep this fork current with msitarzewski/agency-agents, so
# new and updated upstream agents arrive without anyone running git by hand.
# Run daily by .github/workflows/sync-upstream.yml; safe to run locally too.
#
#   main        fast-forwarded to upstream. It is a pure mirror: if it ever has
#               a commit upstream lacks, the script stops rather than guess.
#   hackshaven  upstream is merged in only when the merge is clean AND the
#               checks below pass on the merged tree. Otherwise the upstream tip
#               is pushed to sync/upstream and a PR into hackshaven is opened
#               (or updated) for a human, and the script exits 1 so the run's
#               failure notification says something needs attention.
#
# The checks are the ones this fork's own additions can break:
#   check-divisions.sh    earth-science in the hardcoded division lists
#   check-runbooks.sh     the TerraViz runbook naming upstream agents by slug
#   lint-agents.sh        fork-added or fork-edited agents, under upstream's
#                         current lint rules (upstream lints its own)
#   test-claude-skills.sh build-claude-skills.py against upstream's convert.sh
#
# Usage: ./scripts/sync-upstream.sh [--dry-run]
#   --dry-run   merge and check locally; push nothing, open no PR
# Env: UPSTREAM_URL, UPSTREAM_BRANCH, MIRROR_BRANCH, WORK_BRANCH, SYNC_BRANCH,
#      REMOTE (default origin), PYTHON (default python3), SYNC_CHECKS (the
#      space-separated check list above).
# Needs git, python3, and (unless --dry-run) gh. Runs on bash 3.2 and 5.

set -euo pipefail
cd "$(dirname "$0")/.."

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/msitarzewski/agency-agents.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
MIRROR_BRANCH="${MIRROR_BRANCH:-main}"
WORK_BRANCH="${WORK_BRANCH:-hackshaven}"
SYNC_BRANCH="${SYNC_BRANCH:-sync/upstream}"
REMOTE="${REMOTE:-origin}"
PY="${PYTHON:-python3}"
CHECKS="${SYNC_CHECKS:-check-divisions.sh check-runbooks.sh lint-agents.sh test-claude-skills.sh}"
LIST_MAX=40

DRY_RUN=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

# gh must never guess the repo: with an `upstream` remote configured locally it
# may pick msitarzewski/agency-agents, and the PR would land there.
REPO="${GITHUB_REPOSITORY:-$(git remote get-url "$REMOTE" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')}"

log() { printf '%s\n' "$*"; }
err() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then printf '::error::%s\n' "$*"; else printf 'error: %s\n' "$*"; fi >&2
}
summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then printf '%s\n' "$@" >> "$GITHUB_STEP_SUMMARY"; fi
}
# push_ref <sha> <branch> [force]
push_ref() {
  if [ "$DRY_RUN" = 1 ]; then
    log "dry-run: would push ${1:0:9} to $REMOTE/$2"
  elif [ "${3:-}" = force ]; then
    git push --quiet --force "$REMOTE" "$1:refs/heads/$2"
  else
    git push --quiet "$REMOTE" "$1:refs/heads/$2"
  fi
}

git fetch --quiet --no-tags "$UPSTREAM_URL" "$UPSTREAM_BRANCH"
up="$(git rev-parse FETCH_HEAD)"
git fetch --quiet --no-tags "$REMOTE" "$MIRROR_BRANCH" "$WORK_BRANCH"
mirror="$(git rev-parse "refs/remotes/$REMOTE/$MIRROR_BRANCH")"
work="$(git rev-parse "refs/remotes/$REMOTE/$WORK_BRANCH")"

# --- 1. main: fast-forward only --------------------------------------------
if [ "$mirror" = "$up" ]; then
  log "$MIRROR_BRANCH: already at upstream ${up:0:9}"
elif git merge-base --is-ancestor "$mirror" "$up"; then
  push_ref "$up" "$MIRROR_BRANCH"
  log "$MIRROR_BRANCH: fast-forwarded to upstream ${up:0:9}"
else
  err "$MIRROR_BRANCH has commits upstream doesn't. It must stay a mirror: move them to $WORK_BRANCH, then reset $MIRROR_BRANCH to upstream."
  exit 1
fi

# --- 2. hackshaven: what's incoming -----------------------------------------
if git merge-base --is-ancestor "$up" "$work"; then
  log "$WORK_BRANCH: already contains upstream ${up:0:9}"
  exit 0
fi
base="$(git merge-base "$work" "$up")"
count="$(git rev-list --count "$work..$up")"

# Agent files are the .md files in division directories.
# division_specs <rev> — set specs to "<division>/*.md" for every division in
# <rev>'s divisions.json.
division_specs() {
  specs=()
  while IFS= read -r d; do
    [ -n "$d" ] && specs+=("$d/*.md")
  done <<EOF
$(git show "$1:divisions.json" | "$PY" -c 'import json, sys; print("\n".join(json.load(sys.stdin)["divisions"]))' | tr -d '\r')
EOF
}

# Upstream's divisions, including any it just added.
division_specs "$up"
changes="$(git diff --name-status --no-renames "$base" "$up" -- "${specs[@]}")"
# section <status letter> <title>
section() {
  printf '%s\n' "$changes" | awk -F'\t' -v s="$1" -v t="$2" -v max="$LIST_MAX" '
    $1 == s { n++; if (n <= max) files = files "  " $2 "\n" }
    END {
      if (!n) exit
      printf "%s (%d):\n%s", t, n, files
      if (n > max) printf "  ... and %d more\n", n - max
    }'
}
report="$(section A 'New agents'; section M 'Updated agents'; section D 'Removed agents')"
[ -n "$report" ] || report="No agent files changed (scripts, docs, or config only)."

log "$WORK_BRANCH: $count upstream commit(s) to merge"
log "$report"
summary "## Upstream ${up:0:9}: $count commit(s)" '```' "$report" '```'

# needs_human <headline> <details> — hand the merge to a person via a PR.
needs_human() {
  local body prev pr
  body="$(printf '%s.\n\n%s\n\n**Incoming from upstream** (%s commit(s) up to `%s`):\n\n```\n%s\n```\n\nTo finish by hand:\n\n```sh\ngit fetch origin\ngit switch %s && git pull\ngit merge origin/%s\n# resolve, run the checks, commit\ngit push\n```\n\nThis PR closes on its own once `%s` contains its head. Opened by `scripts/sync-upstream.sh`.' \
    "$1" "$2" "$count" "${up:0:9}" "$report" "$WORK_BRANCH" "$SYNC_BRANCH" "$WORK_BRANCH")"
  summary "**$1** — see the PR from \`$SYNC_BRANCH\` into \`$WORK_BRANCH\`." "" "$2"

  if [ "$DRY_RUN" = 1 ]; then
    log "dry-run: would push ${up:0:9} to $REMOTE/$SYNC_BRANCH and open or update a PR into $WORK_BRANCH:"
    log "----"; log "$body"; log "----"
    exit 1
  fi

  prev="$(git ls-remote "$REMOTE" "refs/heads/$SYNC_BRANCH" | cut -f1)"
  pr="$(gh pr list --repo "$REPO" --head "$SYNC_BRANCH" --base "$WORK_BRANCH" --state open \
    --json number --jq '.[0].number // empty')"
  if [ "$prev" = "$up" ] && [ -z "$pr" ]; then
    # This exact upstream tip was already handed over and the PR closed
    # without merging: someone decided. Wait for upstream to move.
    log "A PR for upstream ${up:0:9} was closed unmerged; waiting for upstream to move."
    exit 0
  fi
  if [ "$prev" = "$up" ]; then
    log "PR #$pr is already open for upstream ${up:0:9}; nothing new."
    exit 0
  fi

  push_ref "$up" "$SYNC_BRANCH" force
  if [ -n "$pr" ]; then
    gh pr edit "$pr" --repo "$REPO" --body "$body" >/dev/null
    gh pr comment "$pr" --repo "$REPO" --body "Upstream moved to \`${up:0:9}\`. $1." >/dev/null
    log "Updated PR #$pr."
  else
    gh pr create --repo "$REPO" --head "$SYNC_BRANCH" --base "$WORK_BRANCH" \
      --title "Merge upstream into $WORK_BRANCH (needs attention)" --body "$body"
  fi
  err "$1. See the PR from $SYNC_BRANCH into $WORK_BRANCH."
  exit 1
}

# --- 3. merge in a throwaway worktree ---------------------------------------
# A worktree leaves whatever is checked out here untouched, so a local run is
# as safe as a CI one.
wt="$(mktemp -d "${TMPDIR:-/tmp}/agency-sync.XXXXXX")"
cleanup() { git worktree remove --force "$wt" >/dev/null 2>&1 || true; rm -rf "$wt"; }
trap cleanup EXIT
git worktree add --quiet --detach "$wt" "$work"

msg="$(printf 'Merge upstream %s into %s\n\n%s commit(s) from %s.\n\n%s' \
  "${up:0:9}" "$WORK_BRANCH" "$count" "${UPSTREAM_URL%.git}" "$report")"
if ! out="$(git -C "$wt" merge --no-ff -m "$msg" "$up" 2>&1)"; then
  conflicts="$(git -C "$wt" diff --name-only --diff-filter=U)"
  if [ -z "$conflicts" ]; then
    err "git merge failed: $out"
    exit 1
  fi
  git -C "$wt" merge --abort
  needs_human "Merging upstream into $WORK_BRANCH conflicts" \
    "$(printf 'Conflicted files:\n\n```\n%s\n```' "$conflicts")"
fi

# --- 4. check the merged tree -----------------------------------------------
# Lint only what this fork added or changed relative to upstream, across the
# merged tree's divisions so the fork's own (earth-science) are included.
division_specs "$(git -C "$wt" rev-parse HEAD)"
fork_agents=()
while IFS= read -r f; do
  [ -n "$f" ] && fork_agents+=("$f")
done <<EOF
$(git -C "$wt" diff --name-only --diff-filter=AM "$up" HEAD -- "${specs[@]}")
EOF

failed=""
details=""
for check in $CHECKS; do
  args=()
  label="$check"
  if [ "$check" = lint-agents.sh ]; then
    [ "${#fork_agents[@]}" -gt 0 ] || continue
    args=("${fork_agents[@]}")
    label="$check (${#fork_agents[@]} fork agents)"
  fi
  # "${args[@]+...}" keeps an empty array from tripping set -u on bash 3.2.
  if out="$(cd "$wt" && bash "scripts/$check" ${args[@]+"${args[@]}"} 2>&1)"; then
    log "  pass  $label"
  else
    log "  FAIL  $label"
    failed="$failed $check"
    details="$details$(printf '\n\n**%s** (last 25 lines):\n\n```\n%s\n```' \
      "$check" "$(printf '%s\n' "$out" | tail -n 25)")"
  fi
done

if [ -n "$failed" ]; then
  needs_human "The merge is clean but checks fail on the merged tree:$failed" "${details#$'\n\n'}"
fi

# --- 5. publish --------------------------------------------------------------
push_ref "$(git -C "$wt" rev-parse HEAD)" "$WORK_BRANCH"
log "$WORK_BRANCH: merged upstream ${up:0:9}"
summary "Merged into \`$WORK_BRANCH\`; all checks passed."
