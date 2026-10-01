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
import hashlib
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
    "## HOT",
    "## COMPACT_REFS",
    "## CURRENT_STATE",
    "## REVIEW",
    "## RAW_REFS",
    "## REPORT",
    "## NEXTSTEP",
]

HOT_FIELDS = (
    "HMD_SCHEMA", "HMD_VERSION", "WORKSTREAM_ID", "HANDOFF_ID",
    "HANDOFF_TYPE", "REPO", "BRANCH", "REPO_HEAD", "REMOTE_HEAD",
    "HANDOFF_AT_HEAD", "LAST_VERIFIED_AT", "AUTH", "STATE", "GATE",
    "BLOCKER", "NEXT_DECISION",
)
WORKSTREAM_RE = re.compile(r"^[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+$")
SHA_RE = re.compile(r"^(?:[0-9a-fA-F]{40}|UNKNOWN)$")
NEXT_DECISION_RE = re.compile(
    r"^(?:ACTION\([^()]+\)|WAIT\([^()]+\)|DONE|NO_WORK_NEEDED|OWNER_DECISION|STOP)$"
)
VALID_TYPES = ("NORMAL", "CORRECTION", "VERIFICATION", "BLOCKED")
CURRENT_PRIORITY_POINTER_TEXT = """<!-- FST / CenVu | (+84) 842 841 222 -->

# Deprecated Current Priority Pointer

ROLE=DEPRECATED_POINTER
AUTHORITY=NONE
CURRENT_PROJECT_SNAPSHOT=handoffs/CURRENT_HANDOFF.md
TASK_QUEUE=GITHUB_ISSUES

This compatibility path is retained for existing links. It contains no live
priority, task, blocker, or next-action state. Read the HOT header in
`handoffs/CURRENT_HANDOFF.md` for the current project snapshot and GitHub Issues
for queued work. Confirm both against repository/GitHub state.
"""

def _section_bodies(text):
    lines = text.splitlines()
    heading_index = {}
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped in REQUIRED_HEADINGS:
            if stripped in heading_index:
                die("draft repeats required heading: %s" % stripped)
            heading_index[stripped] = idx
    for expected in REQUIRED_HEADINGS:
        if expected not in heading_index:
            die("draft is missing required heading: %s" % expected)
    positions = [heading_index[h] for h in REQUIRED_HEADINGS]
    if positions != sorted(positions):
        die("draft headings are out of schema order")
    bodies = {}
    for i, heading in enumerate(REQUIRED_HEADINGS[1:], start=1):
        start = heading_index[heading] + 1
        end = heading_index[REQUIRED_HEADINGS[i + 1]] if i + 1 < len(REQUIRED_HEADINGS) else len(lines)
        body = "\n".join(lines[start:end]).strip()
        if not body:
            die("draft section %s is empty" % heading)
        bodies[heading[3:]] = body
    return bodies


def _fields(body, section_name):
    """Read unique machine fields from section lines."""
    result = {}
    for line in body.splitlines():
        match = re.match(r"^([A-Z][A-Z0-9_]*)=(.*)$", line.strip())
        if not match:
            continue
        key, value = match.groups()
        if key in result:
            die("section %s repeats field %s" % (section_name, key))
        result[key] = value.strip()
    return result


def _repo_file(root, ref):
    """Resolve a repo-relative path/ref without following it outside root."""
    path = ref.split("#", 1)[0].strip()
    if not path or os.path.isabs(path):
        die("reference path must be repository-relative: %s" % ref)
    root_real = os.path.realpath(root)
    candidate = os.path.realpath(os.path.join(root_real, path))
    if os.path.commonpath((root_real, candidate)) != root_real:
        die("reference escapes repository root: %s" % ref)
    if not os.path.isfile(candidate):
        die("required reference does not exist: %s" % ref)
    return candidate


def _validate_refs(root, compact_refs, raw_refs):
    compact_count = 0
    for line in compact_refs.splitlines():
        value = line.strip()
        if value.startswith("REF="):
            _repo_file(root, value[4:])
            compact_count += 1
    if compact_count == 0:
        die("COMPACT_REFS must contain at least one REF=<repo-path>")

    raw_count = 0
    none_seen = False
    for line in raw_refs.splitlines():
        value = line.strip()
        if value == "RAW_REF=NONE":
            none_seen = True
            continue
        if not value.startswith("RAW_REF="):
            continue
        parts = dict(
            item.split("=", 1) for item in value[len("RAW_REF="):].split(";") if "=" in item
        )
        if set(parts) != {"PATH", "BYTES", "SHA256"}:
            die("RAW_REF must include PATH, BYTES, and SHA256")
        candidate = _repo_file(root, parts["PATH"])
        try:
            expected_bytes = int(parts["BYTES"])
        except ValueError:
            die("RAW_REF BYTES must be an integer")
        if not re.fullmatch(r"[0-9a-fA-F]{64}", parts["SHA256"]):
            die("RAW_REF SHA256 is malformed")
        with open(candidate, "rb") as fh:
            data = fh.read()
        if len(data) != expected_bytes:
            die("RAW_REF byte length mismatch: %s" % parts["PATH"])
        if hashlib.sha256(data).hexdigest().lower() != parts["SHA256"].lower():
            die("RAW_REF SHA256 mismatch: %s" % parts["PATH"])
        raw_count += 1
    if none_seen and raw_count:
        die("RAW_REF=NONE cannot be combined with raw refs")
    if raw_count == 0 and not none_seen:
        die("RAW_REFS must contain RAW_REF=NONE or a verified RAW_REF")


def validate_handoff(text, root=None, final=False, expected_handoff_id=None):
    """Validate the versioned handoff schema and deterministic ownership gates."""
    if not text.startswith("# FST Agent Handoff\n"):
        die("draft must start with # FST Agent Handoff")
    if root is None:
        die("repository root is required for handoff reference validation")
    bodies = _section_bodies(text)
    hot = _fields(bodies["HOT"], "HOT")
    missing = [key for key in HOT_FIELDS if key not in hot]
    if missing:
        die("HOT header is missing fields: %s" % ", ".join(missing))
    for key in HOT_FIELDS:
        if not hot[key]:
            die("HOT field %s is empty" % key)
    if hot["HMD_SCHEMA"] != "HANDOFF_MARKDOWN" or hot["HMD_VERSION"] != "1":
        die("unsupported handoff schema/version")
    if not WORKSTREAM_RE.fullmatch(hot["WORKSTREAM_ID"]):
        die("WORKSTREAM_ID is malformed")
    if hot["HANDOFF_TYPE"] not in VALID_TYPES:
        die("HANDOFF_TYPE is invalid")
    if hot["HANDOFF_ID"] == "PUBLISHER_ASSIGNED":
        if final:
            die("published HANDOFF_ID was not assigned by the publisher")
    elif not re.fullmatch(r"\d{8}-\d{6}_[A-Za-z0-9_-]+", hot["HANDOFF_ID"]):
        die("HANDOFF_ID is malformed")
    if expected_handoff_id and hot["HANDOFF_ID"] != expected_handoff_id:
        die("HANDOFF_ID does not match the published filename")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+|UNKNOWN", hot["REPO"]):
        die("REPO must be owner/name or UNKNOWN")
    if not re.fullmatch(r"[A-Za-z0-9._/-]+|UNKNOWN", hot["BRANCH"]):
        die("BRANCH is malformed")
    if not SHA_RE.fullmatch(hot["REPO_HEAD"]):
        die("REPO_HEAD must be a full SHA or UNKNOWN")
    if not SHA_RE.fullmatch(hot["REMOTE_HEAD"]):
        die("REMOTE_HEAD must be a full SHA or UNKNOWN")
    if hot["HANDOFF_AT_HEAD"] not in ("YES", "NO", "UNKNOWN"):
        die("HANDOFF_AT_HEAD must be YES, NO, or UNKNOWN")
    if hot["LAST_VERIFIED_AT"] != "UNKNOWN":
        try:
            checked_at = _dt.datetime.fromisoformat(
                hot["LAST_VERIFIED_AT"].replace("Z", "+00:00")
            )
        except ValueError:
            die("LAST_VERIFIED_AT must be ISO-8601 or UNKNOWN")
        if checked_at.tzinfo is None:
            die("LAST_VERIFIED_AT must include a timezone")
    if hot["AUTH"] != "REPO_GITHUB_CANONICAL":
        die("AUTH must declare REPO_GITHUB_CANONICAL")
    if hot["STATE"] not in ("IN_PROGRESS", "WORKER_REPORT_COMPLETE", "WORKER_BLOCKED"):
        die("STATE must describe Worker report progress, not BRAIN acceptance")
    if hot["GATE"] not in ("WORKER_EVIDENCE_INCOMPLETE", "WORKER_RETURN_READY"):
        die("GATE must describe Worker evidence readiness, not BRAIN classification")
    if not re.fullmatch(r"NONE|[A-Z][A-Z0-9_.:-]*", hot["BLOCKER"]):
        die("BLOCKER must be NONE or a stable blocker key")
    if not NEXT_DECISION_RE.fullmatch(hot["NEXT_DECISION"]):
        die("NEXT_DECISION must be one valid action, wait, done, no-work, owner decision, or stop")

    review = _fields(bodies["REVIEW"], "REVIEW")
    expected_review = {
        "BRAIN_REVIEW_STATUS": "PENDING",
        "BRAIN_CLASSIFICATION": "UNSET",
        "ACCEPTED_STATE": "UNSET",
    }
    for key, expected in expected_review.items():
        if review.get(key) != expected:
            die("REVIEW.%s must remain %s before BRAIN adjudication" % (key, expected))

    nextstep = _fields(bodies["NEXTSTEP"], "NEXTSTEP")
    if nextstep.get("WORKER_NEXT") != "PROPOSAL_ONLY":
        die("NEXTSTEP.WORKER_NEXT must be PROPOSAL_ONLY")
    active_next = nextstep.get("ACTIVE_NEXT")
    if active_next != "NONE":
        die("ACTIVE_NEXT must be NONE; prior BRAIN gates are not yet verifiable")

    all_lines = text.splitlines()
    field_counts = {}
    for line in all_lines:
        match = re.match(r"^([A-Z][A-Z0-9_]*)=(.*)$", line.strip())
        if match:
            key, _ = match.groups()
            field_counts[key] = field_counts.get(key, 0) + 1
    for key in HOT_FIELDS:
        if field_counts.get(key) != 1:
            die("HOT.%s must appear exactly once" % key)
    for key in ("WORKER_NEXT", "ACTIVE_NEXT"):
        if field_counts.get(key) != 1:
            die("%s must appear exactly once" % key)
    for key in expected_review:
        if field_counts.get(key) != 1:
            die("%s must appear exactly once" % key)

    if re.search(r"<[^>\n]+>|\b(?:TBD|TODO|PLACEHOLDER|REPLACE_ME)\b", text, re.IGNORECASE):
        die("handoff contains a pending template placeholder")

    current_state = _fields(bodies["CURRENT_STATE"], "CURRENT_STATE")
    dead_ends = []
    malformed_dead_end_keys = [
        key for key in current_state
        if key.startswith("DEAD_END_") and not re.fullmatch(r"DEAD_END_\d+", key)
    ]
    if malformed_dead_end_keys:
        die("CURRENT_STATE has malformed dead-end key: %s" % malformed_dead_end_keys[0])
    for line in bodies["CURRENT_STATE"].splitlines():
        match = re.match(r"^DEAD_END_(\d+)=(.+)$", line)
        if match:
            number, value = int(match.group(1)), match.group(2)
            parts = value.split("|")
            if (
                len(parts) != 3
                or not parts[0].strip()
                or not parts[1].startswith("FAIL=")
                or not parts[1][len("FAIL="):].strip()
                or not parts[2].startswith("EV=")
                or not parts[2][len("EV="):].strip()
            ):
                die("DEAD_END_%d must be approach|FAIL=reason|EV=ref" % number)
            _repo_file(root, parts[2][len("EV="):].strip())
            dead_ends.append((number, value))
    if current_state.get("DEAD_ENDS") == "NONE":
        if dead_ends:
            die("DEAD_ENDS=NONE cannot be combined with DEAD_END entries")
    elif (
        current_state.get("DEAD_ENDS") != "LISTED"
        or len(dead_ends) == 0
        or len(dead_ends) > 5
        or sorted(n for n, _ in dead_ends) != list(range(1, len(dead_ends) + 1))
    ):
        die("CURRENT_STATE must list no more than five active DEAD_END entries")

    _validate_refs(root, bodies["COMPACT_REFS"], bodies["RAW_REFS"])
    return True

def validate_whitespace(text):
    """Fail if text contains trailing whitespace or whitespace-only lines (except empty lines)."""
    lines = text.splitlines()
    for idx, line in enumerate(lines, start=1):
        if not line:
            continue
        if line.isspace():
            die("draft contains whitespace-only line at line %d" % idx)
        if line.endswith(' ') or line.endswith('\t'):
            if line.endswith('\t'):
                die("draft contains trailing tab at line %d" % idx)
            else:
                die("draft contains trailing whitespace at line %d" % idx)
    return True

def fill_identity(text, filename, now, handoff_type, corrects, previous):
    """Replace publication identity fields with publisher-authoritative values."""
    out = []
    handoff_id = filename[:-3] if filename.endswith(".md") else filename
    for line in text.splitlines():
        if line.startswith("HANDOFF_ID=PUBLISHER_ASSIGNED"):
            out.append("HANDOFF_ID=%s" % handoff_id)
        elif line.startswith("HANDOFF_TYPE="):
            out.append("HANDOFF_TYPE=%s" % handoff_type)
        elif line.startswith("PREVIOUS_HANDOFF=PUBLISHER_ASSIGNED"):
            out.append("PREVIOUS_HANDOFF=%s" % previous)
        elif line.startswith("CORRECTS_HANDOFF=PUBLISHER_ASSIGNED"):
            out.append("CORRECTS_HANDOFF=%s" % corrects)
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
    validate_handoff(draft_text, root=root)
    validate_whitespace(draft_text)

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
    validate_handoff(
        final_text,
        root=root,
        final=True,
        expected_handoff_id=filename[:-3],
    )
    validate_whitespace(final_text)

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
        if "HMD_SCHEMA=HANDOFF_MARKDOWN" in current_text:
            try:
                validate_handoff(
                    current_text,
                    root=root,
                    final=True,
                    expected_handoff_id=newest[:-3],
                )
                validate_whitespace(current_text)
            except SystemExit:
                problems.append("CURRENT_HANDOFF.md fails the deterministic handoff schema")
    if newest:
        count = read_index_count(index_path, newest)
        if count != 1:
            problems.append("INDEX.md has %d entries for %s (expected 1)" % (count, newest))
        last = last_index_handoff(index_path)
        if last != newest:
            problems.append("INDEX.md last entry is %s, expected %s" % (last, newest))

    pointer_path = os.path.join(root, "FST_AI", "memory", "current-priority.md")
    if not os.path.isfile(pointer_path):
        problems.append("current-priority.md compatibility pointer missing")
    else:
        with open(pointer_path, "r", encoding="utf-8") as fh:
            pointer_text = fh.read()
        if pointer_text != CURRENT_PRIORITY_POINTER_TEXT:
            problems.append("current-priority.md is not a non-authoritative pointer to CURRENT")

    if problems:
        for p in problems:
            print("VERIFY: FAIL - %s" % p)
        return 1
    print("VERIFY: PASS - CURRENT is the newest snapshot; pointer resolves; INDEX has exactly 1 entry; history preserved")
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
