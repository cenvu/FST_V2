#!/usr/bin/env python3
# FST / CenVu | (+84) 842 841 222
#
# export_brain_return.py — FST single-file Desktop bridge for ChatGPT Web BRAIN.
#
# The canonical repository and handoff stay in the repository. This tool writes
# exactly one allowed Desktop artifact: ~/Desktop/03_FST_BRAIN.md.
# The bundle contains: FULL REPORT + RAW EVIDENCE + BRAIN OPERATOR.
#
# PASS is fail-closed: the handoff publisher must verify, the tracked worktree
# must be clean, and local HEAD must equal its configured upstream. FAIL remains
# exportable so BRAIN can adjudicate the failure evidence.
#
# This script intentionally has no --output option and never enumerates,
# creates, deletes, renames, or cleans any other Desktop path.

import argparse
import datetime as _dt
import hashlib
import os
from pathlib import Path
import subprocess
import sys

BRAIN_DESKTOP_FILENAME = "03_FST_BRAIN.md"
BRAIN_OPERATOR_RELATIVE_PATH = "FST_AI/memory/BRAIN_OPERATOR_COMPACT.md"
DEFAULT_FULL_REPORT = "handoffs/CURRENT_HANDOFF.md"
VALID_RESULTS = ("PASS", "FAIL")
MAX_TEXT_BYTES = 8 * 1024 * 1024


def die(message, task="UNKNOWN", code=1):
    sys.stderr.write("RESULT: FAIL\n")
    sys.stderr.write("TASK: %s\n" % task)
    sys.stderr.write("REASON: %s\n" % message)
    sys.stderr.write("BRAIN_FILE: NOT UPDATED\n")
    sys.stderr.write("SEND TO BRAIN: BLOCKED — ~/Desktop/%s was not updated\n" % BRAIN_DESKTOP_FILENAME)
    raise SystemExit(code)


def resolve_repo_root():
    script_dir = Path(__file__).resolve().parent
    if script_dir.name == "tools" and script_dir.parent.name in ("FST_AI", "FST_AI_V2"):
        return script_dir.parent.parent
    if script_dir.name == "tools":
        return script_dir.parent
    return None


def require_repo_root(task):
    root = resolve_repo_root()
    if root is None or not (root / "AGENTS.md").is_file():
        die("cannot resolve FST repository root", task)
    return root.resolve()


def read_repo_text(root, value, label, task):
    candidate = (root / value).resolve()
    try:
        relative = candidate.relative_to(root)
    except ValueError:
        die("%s must stay inside the FST repository: %s" % (label, value), task)
    if not candidate.is_file():
        die("%s file not found: %s" % (label, value), task)
    size = candidate.stat().st_size
    if size > MAX_TEXT_BYTES:
        die("%s exceeds %d bytes: %s" % (label, MAX_TEXT_BYTES, value), task)
    data = candidate.read_bytes()
    if b"\x00" in data:
        die("%s is not a text artifact: %s" % (label, value), task)
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        die("%s is not valid UTF-8: %s" % (label, value), task)
    return relative.as_posix(), text


def run(root, argv):
    try:
        proc = subprocess.run(
            argv,
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=30,
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except Exception as exc:
        return 127, "", "%s: %s" % (type(exc).__name__, exc)


def git(root, args):
    return run(root, ["git"] + list(args))


def utc_now():
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def sha256_text(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def git_snapshot(root):
    branch_rc, branch, branch_err = git(root, ["rev-parse", "--abbrev-ref", "HEAD"])
    head_rc, head, head_err = git(root, ["rev-parse", "HEAD"])
    status_rc, status, status_err = git(root, ["status", "--porcelain"])
    upstream_rc, upstream, upstream_err = git(root, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
    upstream_head_rc, upstream_head, upstream_head_err = git(root, ["rev-parse", "@{u}"])
    remote_rc, remote_url, remote_err = git(root, ["config", "--get", "remote.origin.url"])
    log_rc, log_line, log_err = git(root, ["log", "-1", "--oneline"])

    clean = status_rc == 0 and status == ""
    remote_sync = (
        head_rc == 0
        and upstream_head_rc == 0
        and bool(head)
        and head == upstream_head
    )

    raw_lines = [
        "GIT_BRANCH=%s" % (branch if branch_rc == 0 and branch else "UNKNOWN"),
        "GIT_HEAD=%s" % (head if head_rc == 0 and head else "UNKNOWN"),
        "GIT_UPSTREAM=%s" % (upstream if upstream_rc == 0 and upstream else "UNKNOWN"),
        "GIT_UPSTREAM_HEAD=%s" % (upstream_head if upstream_head_rc == 0 and upstream_head else "UNKNOWN"),
        "GIT_REMOTE_ORIGIN=%s" % (remote_url if remote_rc == 0 and remote_url else "UNKNOWN"),
        "GIT_WORKTREE_CLEAN=%s" % ("YES" if clean else "NO"),
        "GIT_REMOTE_SYNC=%s" % ("PASS" if remote_sync else "FAIL"),
        "GIT_LAST_COMMIT=%s" % (log_line if log_rc == 0 and log_line else "UNKNOWN"),
        "GIT_STATUS_PORCELAIN_BEGIN",
        status if status else "<clean>",
        "GIT_STATUS_PORCELAIN_END",
    ]

    errors = []
    for name, rc, err in (
        ("branch", branch_rc, branch_err),
        ("head", head_rc, head_err),
        ("status", status_rc, status_err),
        ("upstream", upstream_rc, upstream_err),
        ("upstream_head", upstream_head_rc, upstream_head_err),
        ("remote", remote_rc, remote_err),
        ("log", log_rc, log_err),
    ):
        if rc != 0:
            errors.append("%s: %s" % (name, err or "command failed"))

    return {
        "branch": branch if branch_rc == 0 and branch else "UNKNOWN",
        "head": head if head_rc == 0 and head else "UNKNOWN",
        "upstream": upstream if upstream_rc == 0 and upstream else "UNKNOWN",
        "upstream_head": upstream_head if upstream_head_rc == 0 and upstream_head else "UNKNOWN",
        "remote_url": remote_url if remote_rc == 0 and remote_url else "UNKNOWN",
        "clean": clean,
        "remote_sync": remote_sync,
        "raw": "\n".join(raw_lines),
        "errors": errors,
    }


def verify_handoff(root):
    publisher = root / "FST_AI" / "tools" / "publish_handoff.py"
    if not publisher.is_file():
        return False, "publish_handoff.py missing"
    rc, out, err = run(root, [sys.executable, str(publisher), "--verify"])
    text = "\n".join(part for part in (out, err) if part).strip()
    return rc == 0, text or ("exit=%d" % rc)


def render_packet(task, requested_result, effective_result, full_report_path, full_report_text,
                  raw_files, brain_operator_path, brain_operator_text, snapshot,
                  handoff_ok, handoff_output, gate_failures):
    raw_source_names = [path for path, _ in raw_files]
    metadata = [
        "# FST BRAIN RETURN — 03_FST_BRAIN",
        "",
        "PACKET=FST_BRAIN_RETURN_V1",
        "AUTHORITY_STATUS=WORKER_EVIDENCE_NOT_CANONICAL_TRUTH",
        "REQUESTED_RESULT=%s" % requested_result,
        "RESULT=%s" % effective_result,
        "TASK=%s" % task,
        "GENERATED_AT_UTC=%s" % utc_now(),
        "CANONICAL_REPOSITORY=%s" % snapshot["remote_url"],
        "BRANCH=%s" % snapshot["branch"],
        "HEAD=%s" % snapshot["head"],
        "UPSTREAM=%s" % snapshot["upstream"],
        "UPSTREAM_HEAD=%s" % snapshot["upstream_head"],
        "REMOTE_SYNC=%s" % ("PASS" if snapshot["remote_sync"] else "FAIL"),
        "WORKTREE_CLEAN=%s" % ("YES" if snapshot["clean"] else "NO"),
        "HANDOFF_VERIFY=%s" % ("PASS" if handoff_ok else "FAIL"),
        "FULL_REPORT_SOURCE=%s" % full_report_path,
        "RAW_SOURCES=%s" % (",".join(raw_source_names) if raw_source_names else "BUILTIN_REPO_SNAPSHOT_ONLY"),
        "BRAIN_OPERATOR_SOURCE=%s" % brain_operator_path,
        "DESKTOP_PATH=~/Desktop/%s" % BRAIN_DESKTOP_FILENAME,
        "FULL_REPORT_SHA256=%s" % sha256_text(full_report_text),
        "BRAIN_OPERATOR_SHA256=%s" % sha256_text(brain_operator_text),
        "GATE_FAILURES=%s" % ("NONE" if not gate_failures else " | ".join(gate_failures)),
        "",
        "Repo/GitHub truth wins over this Desktop projection.",
        "The Desktop file is a one-file transport envelope only; it is never canonical authority.",
        "",
        "## 1. FULL REPORT — VERBATIM",
        "",
        full_report_text.rstrip(),
        "",
        "## 2. RAW EVIDENCE",
        "",
        "### 2.1 Built-in repository snapshot",
        "",
        "```text",
        snapshot["raw"],
        "HANDOFF_VERIFY_OUTPUT_BEGIN",
        handoff_output or "<none>",
        "HANDOFF_VERIFY_OUTPUT_END",
    ]
    if snapshot["errors"]:
        metadata.extend(["GIT_OBSERVATION_ERRORS_BEGIN"] + snapshot["errors"] + ["GIT_OBSERVATION_ERRORS_END"])
    metadata.append("```")

    for idx, (path, text) in enumerate(raw_files, start=2):
        metadata.extend([
            "",
            "### 2.%d %s — VERBATIM" % (idx, path),
            "",
            text.rstrip(),
        ])

    metadata.extend([
        "",
        "## 3. BRAIN OPERATOR — VERBATIM",
        "",
        brain_operator_text.rstrip(),
        "",
    ])
    return "\n".join(metadata)


def write_desktop_packet(text, task, dry_run):
    target_display = "~/Desktop/%s" % BRAIN_DESKTOP_FILENAME
    if dry_run:
        return target_display

    desktop = Path.home() / "Desktop"
    if not desktop.is_dir():
        die("Desktop directory not found", task)
    target = desktop / BRAIN_DESKTOP_FILENAME

    # Direct write to the one authorized path only. No temp/sibling Desktop file.
    with target.open("w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    try:
        os.chmod(target, 0o600)
    except OSError:
        pass
    return target_display


def compact_return(result, task, full_report_path, target_display, dry_run):
    print("RESULT: %s" % result)
    print("TASK: %s" % task)
    print("HANDOFF: %s" % full_report_path)
    print("BRAIN_FILE: %s%s" % (target_display, " (DRY-RUN; NOT WRITTEN)" if dry_run else ""))
    if dry_run:
        print("SEND TO BRAIN: DRY-RUN ONLY — do not upload yet")
    else:
        print("SEND TO BRAIN: %s" % target_display)


def main():
    parser = argparse.ArgumentParser(
        description="Build the single FST Desktop return envelope: FULL REPORT + RAW + BRAIN OPERATOR."
    )
    parser.add_argument("--task", required=True, help="short human-readable task name")
    parser.add_argument("--result", required=True, choices=VALID_RESULTS,
                        help="worker result; PASS is downgraded to FAIL if final gates do not prove it")
    parser.add_argument("--full-report", default=DEFAULT_FULL_REPORT,
                        help="repo-relative full report/handoff (default handoffs/CURRENT_HANDOFF.md)")
    parser.add_argument("--raw", action="append", default=[], metavar="REPO_RELATIVE_PATH",
                        help="optional repo-local UTF-8 raw evidence file; may be repeated")
    parser.add_argument("--dry-run", action="store_true",
                        help="validate and render in memory without writing Desktop")
    args = parser.parse_args()

    task = args.task.strip() or "UNKNOWN"
    root = require_repo_root(task)
    full_report_path, full_report_text = read_repo_text(root, args.full_report, "full report", task)
    brain_operator_path, brain_operator_text = read_repo_text(
        root, BRAIN_OPERATOR_RELATIVE_PATH, "BRAIN operator contract", task
    )
    raw_files = [read_repo_text(root, path, "raw evidence", task) for path in args.raw]

    snapshot = git_snapshot(root)
    handoff_ok, handoff_output = verify_handoff(root)

    gate_failures = []
    if not handoff_ok:
        gate_failures.append("handoff verify failed")
    if not snapshot["clean"]:
        gate_failures.append("worktree is not clean")
    if not snapshot["remote_sync"]:
        gate_failures.append("local HEAD does not equal configured upstream")
    if snapshot["errors"]:
        gate_failures.append("one or more Git observations failed")

    effective_result = args.result
    if args.result == "PASS" and gate_failures:
        effective_result = "FAIL"

    packet = render_packet(
        task=task,
        requested_result=args.result,
        effective_result=effective_result,
        full_report_path=full_report_path,
        full_report_text=full_report_text,
        raw_files=raw_files,
        brain_operator_path=brain_operator_path,
        brain_operator_text=brain_operator_text,
        snapshot=snapshot,
        handoff_ok=handoff_ok,
        handoff_output=handoff_output,
        gate_failures=gate_failures,
    )
    target_display = write_desktop_packet(packet, task, args.dry_run)
    compact_return(effective_result, task, full_report_path, target_display, args.dry_run)
    return 0 if effective_result == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
