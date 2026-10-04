#!/usr/bin/env python3
"""Package Agency agents as Claude skills (Agent Skills SKILL.md).

Claude — chat on claude.ai, Cowork in the Claude desktop app, and Claude Code —
loads skills in the Agent Skills format: a folder named for the skill that holds
a SKILL.md with `name` + `description` frontmatter and instructions as the body.
The repo already renders exactly that shape as the `skill-md` format (the
antigravity / osaurus / dsh converters in convert.sh). This script emits the
same bytes, checks them against Claude's limits, and adds the packaging that
Claude's install paths need:

  <out>/skills/<name>/SKILL.md  copy into ~/.claude/skills/ (Claude Code, user)
                                or <project>/.claude/skills/ (Claude Code, project)
  <out>/zips/<name>.zip         upload in claude.ai or the desktop app
                                (Customize > Skills) — chat and Cowork
  <out>/<plugin>.plugin         optional: every selected skill in one plugin,
                                installable in Cowork, claude.ai, or Claude Code

Skill names keep the `agency-` prefix the skill-md format uses, so they never
collide with a user's own skills.

Usage:
  scripts/build-claude-skills.py --agent "Pre-Submission Peer Reviewer,scientific-visualization-reviewer"
  scripts/build-claude-skills.py --division research --plugin agency-research
  scripts/build-claude-skills.py --agents-file scripts/agents-to-install.example
  scripts/build-claude-skills.py --all --check        # validate the whole catalog, write nothing

Selection flags may be combined and repeated; with no selection flag, every
agent is built (like convert.sh). Standard library only; Python 3.8+.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Claude's SKILL.md frontmatter limits (Agent Skills specification + Claude docs).
NAME_RE = re.compile(r"^[a-z0-9-]{1,64}$")
RESERVED_WORDS = ("anthropic", "claude")
DESCRIPTION_MAX = 1024
XML_TAG_RE = re.compile(r"</?[A-Za-z][^<>]*>")
BODY_LINES_ADVISORY = 500  # Claude's guidance, not a hard limit -> warning only

SKILL_PREFIX = "agency-"
MARKER = ".agency-claude-skills"  # marks an --out dir this script owns
ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)  # fixed timestamps -> reproducible archives
REPO_URL = "https://github.com/msitarzewski/agency-agents"


# --- Agent data model: a Python mirror of scripts/lib.sh ---------------------
# The renderer must stay byte-identical to convert.sh's skill-md output;
# scripts/test-claude-skills.sh diffs the two across the whole catalog.

def get_field(field: str, text: str) -> str:
    """lib.sh get_field: first `field: ` in the frontmatter, folded and unquoted."""
    fm = 0
    found = False
    val = ""
    prefix = field + ": "

    def emit(v: str) -> str:
        v = v.strip(" \t")
        if len(v) >= 2 and v.startswith('"') and v.endswith('"'):
            v = v[1:-1].replace('\\"', '"').replace("\\\\", "\\")
        elif len(v) >= 2 and v.startswith("'") and v.endswith("'"):
            v = v[1:-1].replace("''", "'")
        return v

    for line in split_lines(text):
        if line == "---":
            fm += 1
            if fm == 2 and found:
                return emit(val)
            continue
        if fm == 1 and not found and line.startswith(prefix):
            val = line[len(prefix):]
            found = True
            continue
        if fm == 1 and found and re.match(r"^[ \t]+[^ \t]", line):
            val = val + " " + line.lstrip(" \t")
            continue
        if fm == 1 and found:
            return emit(val)
    return emit(val) if found else ""


def get_body(text: str) -> str:
    """lib.sh get_body, as captured by $(...): trailing newlines stripped."""
    fm = 0
    out = []
    for line in split_lines(text):
        if fm < 2 and line == "---":
            fm += 1
            continue
        if fm >= 2:
            out.append(line)
    return "\n".join(out).rstrip("\n")


def split_lines(text: str) -> List[str]:
    """Split on LF only, the way awk does (str.splitlines also splits on U+2028 etc.)."""
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def slugify(value: str) -> str:
    """lib.sh slugify: lowercase, every run of non [a-z0-9] -> '-', trim '-'."""
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def yaml_quote(value: str) -> str:
    """convert.sh yaml_quote: YAML single-quoted scalar ('' escapes ')."""
    return "'" + value.replace("'", "''") + "'"


def render_skill_md(name: str, description: str, body: str) -> str:
    """The skill-md format, byte-for-byte (see convert_antigravity in convert.sh)."""
    return (
        "---\n"
        f"name: {yaml_quote(name)}\n"
        f"description: {yaml_quote(description)}\n"
        "---\n"
        f"{body}\n"
    )


# --- Roster -------------------------------------------------------------------

def division_dirs(repo_root: Path) -> List[str]:
    """divisions.json is the source of truth for the division set."""
    data = json.loads((repo_root / "divisions.json").read_text(encoding="utf-8"))
    return sorted(data["divisions"].keys())


def collect_agents(repo_root: Path) -> List[Dict[str, str]]:
    agents = []
    for division in division_dirs(repo_root):
        base = repo_root / division
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*.md")):
            text = path.read_text(encoding="utf-8")
            if split_lines(text)[:1] != ["---"]:
                continue  # no frontmatter: not an agent (READMEs, guides)
            display = get_field("name", text)
            if not display:
                continue
            slug = slugify(display)
            agents.append({
                "path": path.relative_to(repo_root).as_posix(),
                "stem": path.stem,
                "division": division,
                "display": display,
                "slug": slug,
                "skill": SKILL_PREFIX + slug,
                "description": get_field("description", text),
                "body": get_body(text),
            })
    return agents


def split_list(values: List[str]) -> List[str]:
    out = []
    for v in values:
        out.extend(p.strip() for p in v.split(",") if p.strip())
    return out


def select_agents(agents: List[Dict[str, str]], args: argparse.Namespace) -> List[Dict[str, str]]:
    wanted = split_list(args.agent)
    if args.agents_file:
        for line in Path(args.agents_file).read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip()
            if line:
                wanted.append(line)
    divisions = split_list(args.division)

    if args.all or not (wanted or divisions):
        return agents

    known_divisions = {a["division"] for a in agents}
    unknown = [d for d in divisions if d not in known_divisions]
    if unknown:
        sys.exit(f"ERROR unknown division(s): {', '.join(unknown)}")

    picked: Dict[str, Dict[str, str]] = {}
    for a in agents:
        if a["division"] in divisions:
            picked[a["path"]] = a
    for ident in wanted:
        key = ident.lower()
        matches = [a for a in agents if key in (
            a["slug"], a["skill"], a["stem"].lower(), a["display"].lower())]
        if not matches:
            sys.exit(f"ERROR unknown agent '{ident}' (use a slug, display name, or file name)")
        for a in matches:
            picked[a["path"]] = a
    return [a for a in agents if a["path"] in picked]


# --- Validation ---------------------------------------------------------------

def validate(agent: Dict[str, str], rendered: str) -> Tuple[List[str], List[str]]:
    errors, warnings = [], []
    name, desc = agent["skill"], agent["description"]
    if not NAME_RE.match(name):
        errors.append(f"name '{name}' must be 1-64 chars of a-z, 0-9 and '-'")
    for word in RESERVED_WORDS:
        if word in name:
            errors.append(f"name '{name}' contains the reserved word '{word}'")
    if not desc:
        errors.append("description is empty")
    if len(desc) > DESCRIPTION_MAX:
        errors.append(f"description is {len(desc)} chars (max {DESCRIPTION_MAX})")
    if XML_TAG_RE.search(desc):
        errors.append("description contains an XML/HTML tag")
    body_lines = rendered.count("\n") - 4  # minus the 4 frontmatter lines
    if body_lines > BODY_LINES_ADVISORY:
        warnings.append(f"body is {body_lines} lines (Claude recommends < {BODY_LINES_ADVISORY})")
    try:  # optional strict parse, when PyYAML happens to be installed
        import yaml  # type: ignore
        fm = yaml.safe_load(rendered.split("---\n", 2)[1])
        if fm.get("name") != name or fm.get("description") != desc:
            errors.append("frontmatter does not round-trip through a YAML parser")
    except ImportError:
        pass
    except Exception as exc:  # noqa: BLE001 — any parse failure is a finding
        errors.append(f"frontmatter is not valid YAML: {exc}")
    return errors, warnings


# --- Output -------------------------------------------------------------------

def prepare_out(out: Path, force: bool) -> None:
    """Clear stale output only in a directory this script created (it holds MARKER).

    A non-empty directory without the marker is refused unless --force, and even
    then nothing in it is deleted — files are only added or overwritten.
    """
    if (out / MARKER).exists():
        for child in ("skills", "zips"):
            shutil.rmtree(out / child, ignore_errors=True)
        for stale in out.glob("*.plugin"):
            stale.unlink()
    elif out.exists() and any(out.iterdir()) and not force:
        sys.exit(f"ERROR {out} is not empty and was not created by this script; "
                 "choose another --out or pass --force (adds files, deletes nothing)")
    out.mkdir(parents=True, exist_ok=True)
    (out / MARKER).write_text("Generated by scripts/build-claude-skills.py — safe to delete.\n",
                              encoding="utf-8")


def zip_write(zf: zipfile.ZipFile, arcname: str, data: Optional[bytes]) -> None:
    info = zipfile.ZipInfo(arcname, date_time=ZIP_EPOCH)
    if data is None:  # directory entry
        info.external_attr = (0o40755 << 16) | 0x10
        zf.writestr(info, b"")
    else:
        info.external_attr = 0o100644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        zf.writestr(info, data)


def write_skill_zip(path: Path, skill: str, content: bytes) -> None:
    # Claude expects <skill-name>/SKILL.md inside the archive, not SKILL.md at the root.
    with zipfile.ZipFile(path, "w") as zf:
        zip_write(zf, f"{skill}/", None)
        zip_write(zf, f"{skill}/SKILL.md", content)


def plugin_readme(plugin: str, agents: List[Dict[str, str]]) -> str:
    rows = "\n".join(f"| `{a['skill']}` | {a['display']} | {a['division']} |" for a in agents)
    return (
        f"# {plugin}\n\n"
        f"{len(agents)} specialists from [The Agency]({REPO_URL}), packaged as Claude skills.\n"
        "Claude loads a skill when a request matches its description, or when you name it.\n\n"
        "| Skill | Agent | Division |\n|---|---|---|\n"
        f"{rows}\n\n"
        "Generated by `scripts/build-claude-skills.py`. Agents are MIT-licensed; see the repository.\n"
    )


def write_plugin(path: Path, plugin: str, version: str, agents: List[Dict[str, str]],
                 rendered: Dict[str, bytes]) -> None:
    manifest = {
        "name": plugin,
        "version": version,
        "description": f"{len(agents)} Agency Agents specialists packaged as Claude skills",
        "author": {"name": "The Agency contributors"},
        "homepage": REPO_URL,
        "license": "MIT",
    }
    with zipfile.ZipFile(path, "w") as zf:  # plugin contents sit at the archive root
        zip_write(zf, ".claude-plugin/", None)
        zip_write(zf, ".claude-plugin/plugin.json",
                  (json.dumps(manifest, indent=2) + "\n").encode("utf-8"))
        zip_write(zf, "README.md", plugin_readme(plugin, agents).encode("utf-8"))
        zip_write(zf, "skills/", None)
        for a in agents:
            zip_write(zf, f"skills/{a['skill']}/", None)
            zip_write(zf, f"skills/{a['skill']}/SKILL.md", rendered[a["skill"]])


# --- Main ---------------------------------------------------------------------

def main() -> int:
    repo_default = Path(__file__).resolve().parent.parent
    p = argparse.ArgumentParser(
        description="Package Agency agents as Claude skills (folders, upload zips, plugin).")
    p.add_argument("--agent", action="append", default=[],
                   help="agent(s) by slug, display name, or file name; comma-separated, repeatable")
    p.add_argument("--division", action="append", default=[],
                   help="division(s) to include; comma-separated, repeatable")
    p.add_argument("--agents-file", help="file with one agent per line (# comments ok)")
    p.add_argument("--all", action="store_true", help="every agent (the default with no selection)")
    p.add_argument("--plugin", metavar="NAME", help="also bundle the selection as NAME.plugin")
    p.add_argument("--plugin-version", default="0.1.0", help="version for the plugin manifest")
    p.add_argument("--out", type=Path, default=None, help="output dir (default: <repo>/dist/claude-skills)")
    p.add_argument("--repo-root", type=Path, default=repo_default, help=argparse.SUPPRESS)
    p.add_argument("--check", action="store_true", help="validate and list only; write nothing")
    p.add_argument("--force", action="store_true", help="allow writing into a non-empty --out")
    args = p.parse_args()

    repo_root = args.repo_root.resolve()
    out = (args.out or repo_root / "dist" / "claude-skills").resolve()

    agents = select_agents(collect_agents(repo_root), args)
    if not agents:
        sys.exit("ERROR nothing selected")

    seen: Dict[str, str] = {}
    for a in agents:  # same guard as convert.sh check_agent_slug_collisions
        if a["skill"] in seen:
            sys.exit(f"ERROR duplicate skill name '{a['skill']}': {seen[a['skill']]} and {a['path']}")
        seen[a["skill"]] = a["path"]

    if args.plugin and (not NAME_RE.match(args.plugin)
                        or any(w in args.plugin for w in RESERVED_WORDS)):
        sys.exit(f"ERROR plugin name '{args.plugin}' must be kebab-case without reserved words")

    rendered: Dict[str, bytes] = {}
    n_err = n_warn = 0
    for a in agents:
        text = render_skill_md(a["skill"], a["description"], a["body"])
        errors, warnings = validate(a, text)
        for e in errors:
            print(f"ERROR {a['path']}: {e}", file=sys.stderr)
        for w in warnings:
            print(f"WARN  {a['path']}: {w}", file=sys.stderr)
        n_err += len(errors)
        n_warn += len(warnings)
        rendered[a["skill"]] = text.encode("utf-8")

    if n_err:
        print(f"\n{n_err} error(s) — nothing written.", file=sys.stderr)
        return 1

    if args.check:
        for a in agents:
            print(f"{a['skill']:<55} {a['path']}")
        print(f"\n{len(agents)} skill(s) valid, {n_warn} warning(s).")
        return 0

    prepare_out(out, args.force)
    (out / "skills").mkdir(exist_ok=True)
    (out / "zips").mkdir(exist_ok=True)
    for a in agents:
        skill_dir = out / "skills" / a["skill"]
        skill_dir.mkdir(exist_ok=True)
        (skill_dir / "SKILL.md").write_bytes(rendered[a["skill"]])
        write_skill_zip(out / "zips" / f"{a['skill']}.zip", a["skill"], rendered[a["skill"]])
    if args.plugin:
        write_plugin(out / f"{args.plugin}.plugin", args.plugin, args.plugin_version,
                     agents, rendered)

    print(f"Built {len(agents)} skill(s) in {out}  ({n_warn} warning(s))")
    print(f"  skills/  folders for ~/.claude/skills/ or <project>/.claude/skills/")
    print(f"  zips/    upload in claude.ai or the desktop app: Customize > Skills")
    if args.plugin:
        print(f"  {args.plugin}.plugin  install the whole set in Cowork, claude.ai, or Claude Code")
    return 0


if __name__ == "__main__":
    sys.exit(main())
