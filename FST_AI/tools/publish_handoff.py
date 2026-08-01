#!/usr/bin/env python3
# FST / CenVu | (+84) 842 841 222
#
# publish_handoff.py — FST cross-agent Handoff publisher.
#
# Validates a completed handoff draft and publishes it atomically:
#   - creates an immutable timestamped file under handoffs/ (exclusive create),
#   - atomically replaces handoffs/CURRENT_HANDOFF.md,
#   - appends exactly one line to handoffs/INDEX.md under an flock lock.
#
# Uses only the Python standard library. Never runs Git mutation commands.
# Never modifies application source. The agent writes the technical content;
# this tool validates and publishes it.
#
# Usage examples:
#   python3 FST_AI/tools/publish_handoff.py \
#     --draft /path/to/completed-handoff.md \
#     --agent "Claude Code" --model "Claude" \
#     --task "Implement append-only handoff system" \
#     --phase "Infrastructure setup" --type NORMAL --corrects NONE
#   python3 FST_AI/tools/publish_handoff.py --verify
#   python3 FST_AI/tools/publish_handoff.py --draft ... --dry-run

import argparse
import datetime as _dt
import os
import re
import subprocess
import sys

# ---------------------------------------------------------------- paths

def resolve_repo_root():
    """Resolve the repository root from this script's location."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Expected layout: <root>/FST_AI/tools/publish_handoff.py
    if os.path.basename(script_dir) == "tools" and os.path.basename(os.path.dirname(script_dir)) in ("FST_AI", "FST_AI_V2"):
        return os.path.dirname(os.path.dirname(script_dir))
    # Alternative layout: <root>/tools/publish_handoff.py (test fixtures)
    if os.path.basename(script_dir) == "tools":
        return os.path.dirname(script_dir)
    return None

def handoffs_dir(root):
    return os.path.join(root, "handoffs")

def require_root(root):
    if not root:
        die("cannot resolve repository root from script location")
    if not os.path.isfile(os.path.join(root, "AGENTS.md")):
        die("repository root %s does not look like FST (AGENTS.md missing)" % root)
    return root

# ---------------------------------------------------------------- time

def bangkok_now():
    """Current time in Asia/Bangkok (+07:00), with a fixed-offset fallback."""
    try:
        from zoneinfo import ZoneInfo  # Python 3.9+ / stdlib tz database
        return _dt.datetime.now(ZoneInfo("Asia/Bangkok"))
    except Exception:
        return _dt.datetime.now(_dt.timezone(_dt.timedelta(hours=7)))

def filename_timestamp(now):
    return now.strftime("%Y%m%d-%H%M%S")

def iso_timestamp(now):
    return now.isoformat(timespec="seconds")

# ---------------------------------------------------------------- helpers

def die(message, code=1):
    sys.stderr.write("publish_handoff: ERROR: %s\n" % message)
    sys.exit(code)

def slugify(value, limit=48):
    value = re.sub(r"[^A-Za-z0-9]+", "-", value.strip().lower())
    value = value.strip("-")
    return value[:limit].strip("-") or "task"

def sanitize_cell(value):
    """Keep the INDEX table well-formed."""
    return value.replace("|", "/").replace("\n", " ").strip()

def git_readonly(args):
    """Run a read-only Git command; never a mutation."""
    try:
        proc = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True, cwd=os.getcwd(), timeout=15,
        )
        return proc.stdout.strip() if proc.returncode == 0 else ""
    except Exception:
        return ""

# ---------------------------------------------------------------- schema

REQUIRED_HEADINGS = [
    "# FST Agent Handoff",
    "## 1. Handoff Identity",
    "## 2. Task and Phase",
    "## 3. Agent and Model",
    "## 4. Repository Snapshot",
    "## 5. Starting Context",
    "## 6. Work Completed",
    "## 7. Files Changed",
    "## 8. Verification Evidence",
    "## 9. Git and GitHub Evidence",
    "## 10. CodeGraph Evidence",
    "## 11. Remaining Risks and Unknowns",
    "## 12. Safety Invariants",
    "## 13. Single Next Action",
    "## 14. Resume Prompt",
    "## 15. References",
]

VALID_TYPES = ("NORMAL", "CORRECTION", "VERIFICATION", "BLOCKED")

def validate_handoff(text):
    """Validate required headings in order and required sections non-empty."""
    lines = text.splitlines()
    heading_index = {}
    seen = []
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped in REQUIRED_HEADINGS:
            heading_index[stripped] = idx
            seen.append(stripped)
    for expected in REQUIRED_HEADINGS:
        if expected not in heading_index:
            die("draft is missing required heading: %s" % expected)
    # Headings must appear in schema order.
    positions = [heading_index[h] for h in REQUIRED_HEADINGS]
    if positions != sorted(positions):
        die("draft headings are out of schema order")
    # Section 13 (Single Next Action) and 14 (Resume Prompt) must have content.
    for section, section_next in (
        ("## 13. Single Next Action", "## 14. Resume Prompt"),
        ("## 14. Resume Prompt", "## 15. References"),
    ):
        start = heading_index[section] + 1
        end = heading_index[section_next]
        body = "\n".join(lines[start:end]).strip()
        if len(body) < 20:
            die("draft section %s is empty or too short" % section)
    # Resume Prompt must contain a fenced code block.
    resume_start = heading_index["## 14. Resume Prompt"]
    resume_end = heading_index["## 15. References"]
    resume = "\n".join(lines[resume_start:resume_end])
    if "```" not in resume:
        die("draft section ## 14. Resume Prompt must contain a fenced ``` block")
    return True

def fill_identity(text, filename, now, handoff_type, corrects, previous):
    """Replace the five identity lines with publisher-authoritative values."""
    iso = iso_timestamp(now)
    out = []
    handoff_id = filename[:-3] if filename.endswith(".md") else filename
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("- Handoff ID:"):
            out.append("- Handoff ID: %s" % handoff_id)
        elif stripped.startswith("- Created At:"):
            out.append("- Created At: %s" % iso)
        elif stripped.startswith("- Handoff Type:"):
            out.append("- Handoff Type: %s" % handoff_type)
        elif stripped.startswith("- Corrects Handoff:"):
            out.append("- Corrects Handoff: %s" % corrects)
        elif stripped.startswith("- Previous Handoff:"):
            out.append("- Previous Handoff: %s" % previous)
        else:
            out.append(line)
    return "\n".join(out)

def last_index_handoff(index_path):
    """Return the filename of the newest handoff from INDEX, or None."""
    if not os.path.isfile(index_path):
        return None
    last = None
    try:
        with open(index_path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("|") and "|" in line[1:]:
                    cells = [c.strip() for c in line.strip("|").split("|")]
                    if len(cells) >= 2 and cells[1].endswith(".md"):
                        last = cells[1]
    except Exception:
        return None
    return last

def find_newest_timestamped(handoffs_dir):
    """Newest handoff by filename sort order; templates/README excluded."""
    pattern = re.compile(r"^\d{8}-\d{6}_.+\.md$")
    candidates = []
    if os.path.isdir(handoffs_dir):
        for name in os.listdir(handoffs_dir):
            if pattern.match(name):
                candidates.append(name)
    return max(candidates) if candidates else None

# ---------------------------------------------------------------- index

INDEX_HEADER = (
    "# FST Handoff Index\n"
    "\n"
    "Append-only history of published handoffs. Never edit, reorder, or delete\n"
    "existing entries. Each publication appends exactly one line. Corrections are\n"
    "new handoffs that reference the older handoff; history is never erased.\n"
    "\n"
    "| ISO timestamp | Handoff filename | Type | Agent/Model | Task/Phase | Branch@Commit | Status | Corrects |\n"
    "|---|---|---|---|---|---|---|---|\n"
)

def append_index(index_path, line):
    """Append one line under an exclusive flock; preserve all history."""
    import fcntl
    existed = os.path.isfile(index_path)
    fd = os.open(index_path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        if not existed:
            os.write(fd, INDEX_HEADER.encode("utf-8"))
        else:
            # ensure trailing newline before appending
            os.lseek(fd, 0, os.SEEK_END)
            size = os.lseek(fd, 0, os.SEEK_END)
            if size:
                os.lseek(fd, size - 1, os.SEEK_SET)
                tail = os.read(fd, 1)
                if tail not in (b"\n", b""):
                    os.write(fd, b"\n")
        os.write(fd, (line + "\n").encode("utf-8"))
        os.fsync(fd)
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)

# ---------------------------------------------------------------- publish

def read_index_count(index_path, filename):
    if not os.path.isfile(index_path):
        return 0
    count = 0
    with open(index_path, "r", encoding="utf-8") as fh:
        for line in fh:
            if filename in line:
                count += 1
    return count

def publish(args):
    root = require_root(resolve_repo_root())
    hdir = handoffs_dir(root)
    if not os.path.isdir(hdir):
        os.makedirs(hdir, exist_ok=True)

    draft_path = os.path.abspath(args.draft)
    if not os.path.isfile(draft_path):
        die("draft file not found: %s" % draft_path)
    with open(draft_path, "r", encoding="utf-8") as fh:
        draft_text = fh.read()
    validate_handoff(draft_text)

    handoff_type = args.type.upper()
    if handoff_type not in VALID_TYPES:
        die("invalid --type %r (expected %s)" % (args.type, ", ".join(VALID_TYPES)))
    if handoff_type == "CORRECTION" and (not args.corrects or args.corrects.upper() == "NONE"):
        die("CORRECTION handoff requires --corrects <historical-filename>")

    now = bangkok_now()
    agent_slug = slugify(args.agent)
    task_slug = slugify(args.task)
    filename = "%s_%s_%s.md" % (filename_timestamp(now), agent_slug, task_slug)
    index_path = os.path.join(hdir, "INDEX.md")
    current_path = os.path.join(hdir, "CURRENT_HANDOFF.md")
    previous = last_index_handoff(index_path) or "NONE"

    final_text = fill_identity(draft_text, filename, now, handoff_type,
                               args.corrects or "NONE", previous)
    validate_handoff(final_text)

    # Branch@commit + status from read-only Git.
    branch = git_readonly(["rev-parse", "--abbrev-ref", "HEAD"]) or "unknown"
    commit = git_readonly(["rev-parse", "--short", "HEAD"]) or "unknown"
    porcelain = git_readonly(["status", "--porcelain"])
    status = "clean" if not porcelain else "modified"
    index_line = "| %s | %s | %s | %s/%s | %s/%s | %s@%s | %s | %s |" % (
        iso_timestamp(now), filename, handoff_type,
        sanitize_cell(args.agent), sanitize_cell(args.model),
        sanitize_cell(args.task), sanitize_cell(args.phase),
        sanitize_cell(branch), sanitize_cell(commit),
        status, sanitize_cell(args.corrects or "NONE"),
    )

    if args.dry_run:
        print("DRY-RUN: would publish %s" % filename)
        print("DRY-RUN: CURRENT -> %s" % os.path.join(hdir, "CURRENT_HANDOFF.md"))
        print("DRY-RUN: INDEX += 1 line: %s" % index_line)
        return 0

    target = os.path.join(hdir, filename)
    if os.path.exists(target):
        die("refusing to overwrite existing handoff: %s" % target)

    # 1. Timestamped immutable file (exclusive create), flushed and fsynced.
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    try:
        os.write(fd, final_text.encode("utf-8"))
        os.fsync(fd)
    finally:
        os.close(fd)

    # 2. Atomic CURRENT replacement (temp + os.replace + dir fsync).
    tmp_current = current_path + ".tmp"
    with open(tmp_current, "w", encoding="utf-8") as fh:
        fh.write(final_text)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp_current, current_path)
    try:
        dfd = os.open(hdir, os.O_RDONLY)
        try:
            os.fsync(dfd)
        finally:
            os.close(dfd)
    except OSError:
        pass  # directory fsync is best-effort on some filesystems

    # 3. INDEX append: exactly one line, locked, flushed and fsynced.
    append_index(index_path, index_line)

    print("PUBLISHED: handoffs/%s" % filename)
    print("CURRENT: handoffs/CURRENT_HANDOFF.md (atomically replaced)")
    print("INDEX: handoffs/INDEX.md appended (1 line, flock held, fsynced)")
    return 0

# ---------------------------------------------------------------- verify

def verify(args):
    root = require_root(resolve_repo_root())
    hdir = handoffs_dir(root)
    current_path = os.path.join(hdir, "CURRENT_HANDOFF.md")
    index_path = os.path.join(hdir, "INDEX.md")
    newest = find_newest_timestamped(hdir)
    problems = []

    if not newest:
        problems.append("no timestamped handoff found in %s" % hdir)
    if not os.path.isfile(current_path):
        problems.append("CURRENT_HANDOFF.md missing")
    elif newest:
        with open(current_path, "r", encoding="utf-8") as fh:
            current_text = fh.read()
        with open(os.path.join(hdir, newest), "r", encoding="utf-8") as fh:
            newest_text = fh.read()
        if current_text != newest_text:
            problems.append("CURRENT_HANDOFF.md does not match %s" % newest)
    if newest:
        count = read_index_count(index_path, newest)
        if count != 1:
            problems.append("INDEX.md has %d entries for %s (expected 1)" % (count, newest))
        last = last_index_handoff(index_path)
        if last != newest:
            problems.append("INDEX.md last entry is %s, expected %s" % (last, newest))

    if problems:
        for p in problems:
            print("VERIFY: FAIL - %s" % p)
        return 1
    print("VERIFY: PASS - CURRENT matches %s; INDEX has exactly 1 entry; history preserved" % newest)
    return 0

# ---------------------------------------------------------------- main

def main():
    parser = argparse.ArgumentParser(
        description="FST Handoff publisher: validate a completed draft and "
                    "publish it immutably (timestamped file, CURRENT, INDEX)."
    )
    parser.add_argument("--draft", metavar="PATH", help="completed handoff draft (Markdown)")
    parser.add_argument("--agent", default="UNVERIFIED", help="agent host, e.g. Claude Code")
    parser.add_argument("--model", default="UNVERIFIED", help="model, e.g. Claude (never guess; use UNVERIFIED)")
    parser.add_argument("--task", default="task", help="task slug")
    parser.add_argument("--phase", default="phase", help="phase name")
    parser.add_argument("--type", default="NORMAL", choices=VALID_TYPES,
                        help="handoff type (default NORMAL)")
    parser.add_argument("--corrects", default="NONE",
                        help="historical handoff filename this handoff corrects (CORRECTION/VERIFICATION)")
    parser.add_argument("--dry-run", action="store_true",
                        help="validate and print the planned publication without writing anything")
    parser.add_argument("--verify", action="store_true",
                        help="verify CURRENT/INDEX consistency against the newest timestamped handoff")
    args = parser.parse_args()

    if args.verify:
        return verify(args)
    if not args.draft:
        parser.error("--draft is required unless --verify is used")
    return publish(args)

if __name__ == "__main__":
    sys.exit(main())
