#!/usr/bin/env bash
#
# test-claude-skills.sh — regression test for scripts/build-claude-skills.py.
#
# The Claude skills packager re-implements the skill-md renderer in Python so it
# runs anywhere python3 does (Windows included, no bash needed). This test holds
# it to the generator of record and to Claude's packaging rules:
#
#   1. byte-identity  every SKILL.md equals convert.sh's skill-md output
#                     (antigravity) for the same agent, across the whole roster
#   2. count          exactly one skill per roster agent
#   3. limits         the full catalog passes Claude's frontmatter limits
#   4. archives       each upload zip holds exactly <name>/ and <name>/SKILL.md,
#                     and that SKILL.md equals the folder copy
#   5. plugin         a division bundle carries .claude-plugin/plugin.json with
#                     the right name and one SKILL.md per selected agent
#   6. selection      --agent resolves a display name, slug, file name, and skill name
#   7. reproducible   two builds produce byte-identical zips and plugin
#   8. safety         a non-empty --out the script didn't create is refused, untouched
#
# Usage: ./scripts/test-claude-skills.sh        (PYTHON=python3.x to pick an interpreter)
# Runs on bash 3.2 (macOS) and 5 (Linux).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${PYTHON:-python3}"
BUILD="$SCRIPT_DIR/build-claude-skills.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agency-claude-skills.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

failures=0
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; failures=$((failures + 1)); }

# --- 1 + 2: byte-identity and count against convert.sh -------------------------
echo "1-2. Byte-identity and count vs convert.sh skill-md (antigravity)"
"$SCRIPT_DIR/convert.sh" --tool antigravity --out "$TMP/ref" >/dev/null 2>&1 \
  || { echo "  ERROR convert.sh --tool antigravity failed"; exit 2; }
"$PY" "$BUILD" --all --out "$TMP/claude" >/dev/null 2>&1   # warnings are reported in step 3

ref_n=$(find "$TMP/ref/antigravity" -name SKILL.md -type f | wc -l | tr -d ' ')
got_n=$(find "$TMP/claude/skills" -name SKILL.md -type f | wc -l | tr -d ' ')
diffs=0
for ref in "$TMP"/ref/antigravity/*/SKILL.md; do
  name="$(basename "$(dirname "$ref")")"
  got="$TMP/claude/skills/$name/SKILL.md"
  if [[ ! -f "$got" ]]; then
    fail "$name: missing from the Claude build"; diffs=$((diffs + 1))
  elif ! cmp -s "$ref" "$got"; then
    fail "$name: differs from skill-md"; diffs=$((diffs + 1))
    (( diffs <= 3 )) && diff "$ref" "$got" | head -6 | sed 's/^/        /'
  fi
done
(( diffs == 0 )) && pass "$got_n SKILL.md files byte-identical to convert.sh"
if [[ "$ref_n" == "$got_n" && "$ref_n" -gt 0 ]]; then
  pass "count: $got_n skills for $ref_n roster agents"
else
  fail "count: $got_n skills for $ref_n roster agents"
fi

# --- 3: Claude frontmatter limits over the whole catalog -----------------------
echo "3. Claude frontmatter limits (full catalog)"
if "$PY" "$BUILD" --all --check >"$TMP/check.out" 2>"$TMP/check.err"; then
  pass "$(tail -1 "$TMP/check.out")"
else
  fail "catalog has invalid skills:"; sed 's/^/        /' "$TMP/check.err" | head -20
fi

# --- 4: upload zip structure ---------------------------------------------------
echo "4. Upload zips"
if "$PY" - "$TMP/claude" <<'PYEOF'
import pathlib, sys, zipfile
out = pathlib.Path(sys.argv[1]); bad = 0; n = 0
for z in sorted((out / "zips").glob("*.zip")):
    n += 1; name = z.stem
    with zipfile.ZipFile(z) as zf:
        entries = sorted(zf.namelist())
        if entries != [f"{name}/", f"{name}/SKILL.md"]:
            print(f"  FAIL  {z.name}: entries {entries}"); bad += 1; continue
        if zf.read(f"{name}/SKILL.md") != (out / "skills" / name / "SKILL.md").read_bytes():
            print(f"  FAIL  {z.name}: SKILL.md differs from the folder copy"); bad += 1
print(f"  {'PASS' if not bad else 'FAIL'}  {n} zips: <name>/SKILL.md at top level, content matches")
sys.exit(1 if bad else 0)
PYEOF
then :; else failures=$((failures + 1)); fi

# --- 5: plugin bundle ----------------------------------------------------------
echo "5. Plugin bundle (research division)"
research_n=$("$PY" "$BUILD" --division research --check | tail -1 | awk '{print $1}')
"$PY" "$BUILD" --division research --plugin agency-test --out "$TMP/plugin" >/dev/null
if "$PY" - "$TMP/plugin/agency-test.plugin" "$research_n" <<'PYEOF'
import json, sys, zipfile
path, expected = sys.argv[1], int(sys.argv[2])
with zipfile.ZipFile(path) as zf:
    names = zf.namelist()
    manifest = json.loads(zf.read(".claude-plugin/plugin.json"))
    skills = [n for n in names if n.startswith("skills/") and n.endswith("/SKILL.md")]
ok = manifest.get("name") == "agency-test" and len(skills) == expected and "README.md" in names
print(f"  {'PASS' if ok else 'FAIL'}  manifest name={manifest.get('name')!r}, "
      f"{len(skills)} skills (expected {expected}), README present={'README.md' in names}")
sys.exit(0 if ok else 1)
PYEOF
then :; else failures=$((failures + 1)); fi

# --- 6: selection --------------------------------------------------------------
echo "6. Selection by display name, slug, file name, skill name"
for ident in "Code Reviewer" "code-reviewer" "engineering-code-reviewer" "agency-code-reviewer"; do
  line="$("$PY" "$BUILD" --agent "$ident" --check | tail -1)"
  if [[ "$line" == "1 skill(s) valid"* ]]; then pass "--agent '$ident'"; else fail "--agent '$ident': $line"; fi
done
if "$PY" "$BUILD" --agent "no-such-agent" --check >/dev/null 2>&1; then
  fail "unknown agent was accepted"
else
  pass "unknown agent rejected"
fi

# --- 7: reproducible output ----------------------------------------------------
echo "7. Reproducible archives"
"$PY" "$BUILD" --division research --plugin agency-test --out "$TMP/plugin2" >/dev/null
same=1
for f in "$TMP"/plugin/zips/*.zip "$TMP/plugin/agency-test.plugin"; do
  cmp -s "$f" "$TMP/plugin2/${f#"$TMP/plugin/"}" || { same=0; fail "${f##*/} differs between builds"; }
done
(( same == 1 )) && pass "zips and plugin byte-identical across builds"

# --- 8: output-directory safety -------------------------------------------------
echo "8. Refuses a non-empty --out it did not create"
mkdir -p "$TMP/userdir/skills"; echo keep > "$TMP/userdir/skills/keep.txt"
if "$PY" "$BUILD" --agent code-reviewer --out "$TMP/userdir" >/dev/null 2>&1; then
  fail "wrote into a foreign directory"
elif [[ -f "$TMP/userdir/skills/keep.txt" ]]; then
  pass "refused, existing files untouched"
else
  fail "refused, but existing files were removed"
fi

echo
if (( failures == 0 )); then echo "PASSED"; else echo "FAILED: $failures check(s)"; exit 1; fi
