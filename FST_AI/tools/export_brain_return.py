#!/usr/bin/env python3
# FST / CenVu | (+84) 842 841 222
#
# export_brain_return.py — metadata-only FST BRAIN return transport.
#
# GitHub and repository artifacts are canonical. This tool writes exactly one
# Desktop transport file: ~/Desktop/03_FST_BRAIN.md. V2 contains pointers,
# hashes, Git/handoff gates, and explicit handoff facts only. It does not
# summarize handoffs or embed repository file bodies.

import argparse
import codecs
import datetime as _dt
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import quote

BRAIN_DESKTOP_FILENAME = "03_FST_BRAIN.md"
BRAIN_OPERATOR_RELATIVE_PATH = "FST_AI/memory/BRAIN_OPERATOR_COMPACT.md"
DEFAULT_FULL_REPORT = "handoffs/CURRENT_HANDOFF.md"
NEXT_ACTION_POINTER = "handoffs/CURRENT_HANDOFF.md"
VALID_RESULTS = ("PASS", "FAIL")
MAX_TEXT_BYTES = 8 * 1024 * 1024


def compact_return(result, task, handoff_path):
    if any(ord(char) < 32 or ord(char) == 127 for char in handoff_path):
        handoff_path = encoded(handoff_path)
    print("RESULT: %s" % result)
    print("TASK: %s" % task)
    print("HANDOFF: %s" % handoff_path)
    print("BRAIN_FILE: ~/Desktop/%s" % BRAIN_DESKTOP_FILENAME)
    print("SEND TO BRAIN: ~/Desktop/%s" % BRAIN_DESKTOP_FILENAME)


def die(message, task="UNKNOWN", code=1):
    sys.stderr.write("EXPORT_ERROR=%s\n" % message)
    compact_return("FAIL", task, DEFAULT_FULL_REPORT)
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
        die("repo_root_unavailable", task)
    return root.resolve()


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
        return 127, "", type(exc).__name__


def git(root, args):
    return run(root, ["git"] + list(args))


def utc_now():
    return (
        _dt.datetime.now(_dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value, safe="/-._~"):
    return quote(str(value), safe=safe, encoding="utf-8", errors="strict")


def canonical_repo(remote_url):
    remote = (remote_url or "").strip()
    if not remote:
        return "UNKNOWN"
    if remote.lower().startswith("git@github.com:"):
        path = remote.split(":", 1)[1]
    else:
        match = re.fullmatch(
            r"(?:https?|ssh)://github\.com[:/](.+?)/?",
            remote,
            flags=re.IGNORECASE,
        )
        path = match.group(1) if match else ""
    if path.endswith(".git"):
        path = path[:-4]
    path = path.strip("/")
    if path.count("/") == 1 and all(path.split("/")):
        return path
    return remote


def git_snapshot(root):
    observations = {
        "branch": git(root, ["rev-parse", "--abbrev-ref", "HEAD"]),
        "head": git(root, ["rev-parse", "HEAD"]),
        "status": git(root, ["status", "--porcelain"]),
        "upstream": git(root, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]),
        "upstream_head": git(root, ["rev-parse", "@{u}"]),
        "remote_url": git(root, ["config", "--get", "remote.origin.url"]),
    }
    errors = [name for name, (rc, _, _) in observations.items() if rc != 0]

    branch = observations["branch"][1] if observations["branch"][0] == 0 else "UNKNOWN"
    head = observations["head"][1] if observations["head"][0] == 0 else "UNKNOWN"
    status = observations["status"][1] if observations["status"][0] == 0 else "UNKNOWN"
    upstream = observations["upstream"][1] if observations["upstream"][0] == 0 else "UNKNOWN"
    upstream_head = (
        observations["upstream_head"][1]
        if observations["upstream_head"][0] == 0
        else "UNKNOWN"
    )
    remote_url = (
        observations["remote_url"][1]
        if observations["remote_url"][0] == 0
        else "UNKNOWN"
    )
    clean = observations["status"][0] == 0 and status == ""
    remote_sync = (
        observations["head"][0] == 0
        and observations["upstream_head"][0] == 0
        and bool(head)
        and head != "UNKNOWN"
        and upstream_head == head
    )

    return {
        "branch": branch or "UNKNOWN",
        "head": head or "UNKNOWN",
        "upstream": upstream or "UNKNOWN",
        "upstream_head": upstream_head or "UNKNOWN",
        "remote_url": remote_url or "UNKNOWN",
        "repo": canonical_repo(remote_url),
        "clean": clean,
        "remote_sync": remote_sync,
        "errors": errors,
    }


def inspect_repo_text(root, value, metadata_only=False):
    result = {
        "path": None,
        "size_bytes": None,
        "sha256": None,
        "text": None,
        "error": None,
    }
    try:
        candidate = (root / value).resolve()
        relative = candidate.relative_to(root).as_posix()
    except ValueError:
        result["error"] = "path_outside_repo"
        return result
    except (OSError, RuntimeError, TypeError):
        result["error"] = "path_unresolvable"
        return result

    result["path"] = relative
    try:
        if not candidate.is_file():
            result["error"] = "file_missing"
            return result
        size = candidate.stat().st_size
        result["size_bytes"] = size
        if size > MAX_TEXT_BYTES and not metadata_only:
            result["error"] = "file_too_large"
            return result
    except OSError:
        result["error"] = "file_unreadable"
        return result

    if metadata_only:
        digest = hashlib.sha256()
        decoder = codecs.getincrementaldecoder("utf-8")()
        encoding_error = False
        nul_found = False
        total = 0
        try:
            with candidate.open("rb") as stream:
                while True:
                    chunk = stream.read(64 * 1024)
                    if not chunk:
                        break
                    total += len(chunk)
                    digest.update(chunk)
                    if b"\x00" in chunk:
                        nul_found = True
                    if not encoding_error:
                        try:
                            decoder.decode(chunk, final=False)
                        except UnicodeDecodeError:
                            encoding_error = True
                if not encoding_error:
                    try:
                        decoder.decode(b"", final=True)
                    except UnicodeDecodeError:
                        encoding_error = True
        except OSError:
            result["size_bytes"] = total
            result["error"] = "file_unreadable"
            return result
        result["size_bytes"] = total
        result["sha256"] = digest.hexdigest()
        if nul_found:
            result["error"] = "text_contains_nul"
        elif encoding_error:
            result["error"] = "text_not_utf8"
        return result

    try:
        data = candidate.read_bytes()
    except OSError:
        result["error"] = "file_unreadable"
        return result
    result["size_bytes"] = len(data)
    result["sha256"] = sha256_bytes(data)
    if len(data) > MAX_TEXT_BYTES:
        result["error"] = "file_too_large"
        return result
    if b"\x00" in data:
        result["error"] = "text_contains_nul"
        return result
    try:
        result["text"] = data.decode("utf-8")
    except UnicodeDecodeError:
        result["error"] = "text_not_utf8"
        return result
    return result


def verify_handoff(root):
    publisher = root / "FST_AI" / "tools" / "publish_handoff.py"
    if not publisher.is_file():
        return False
    rc, _, _ = run(root, [sys.executable, str(publisher), "--verify"])
    return rc == 0


def explicit_handoff_facts(handoff_text):
    not_executed = []
    blockers = []
    if handoff_text is None:
        return not_executed, blockers
    for line in handoff_text.splitlines():
        if line.startswith("NOT_EXECUTED="):
            not_executed.append(line[len("NOT_EXECUTED="):])
        elif line.startswith("BLOCKER="):
            blockers.append(line[len("BLOCKER="):])
        elif line.startswith("BLOCKERS="):
            blockers.append(line[len("BLOCKERS="):])
    return not_executed, blockers


def render_packet(task, requested_result, effective_result, report, brain_operator,
                  raw_files, snapshot, handoff_ok, gate_failures):
    not_executed, blockers = explicit_handoff_facts(report["text"])
    manifest_files = [raw for raw in raw_files if raw["path"] is not None]
    rejected_files = [raw for raw in raw_files if raw["path"] is None]
    lines = [
        "PACKET=FST_BRAIN_RETURN_V2",
        "VALUE_ENCODING=PERCENT_UTF8_RFC3986",
        "AUTHORITY_STATUS=WORKER_EVIDENCE;REPO_GITHUB_CANONICAL;DESKTOP_TRANSPORT_ONLY",
        "REQUESTED_RESULT=%s" % requested_result,
        "EFFECTIVE_RESULT=%s" % effective_result,
        "TASK=%s" % encoded(task, safe="-._~"),
        "GENERATED_AT_UTC=%s" % utc_now(),
        "REPO=%s" % encoded(snapshot["repo"]),
        "REMOTE_ORIGIN=%s" % encoded(snapshot["remote_url"]),
        "BRANCH=%s" % encoded(snapshot["branch"]),
        "HEAD=%s" % snapshot["head"],
        "UPSTREAM=%s" % encoded(snapshot["upstream"]),
        "UPSTREAM_HEAD=%s" % snapshot["upstream_head"],
        "REMOTE_SYNC=%s" % ("PASS" if snapshot["remote_sync"] else "FAIL"),
        "WORKTREE_CLEAN=%s" % ("YES" if snapshot["clean"] else "NO"),
        "HANDOFF_PATH=%s" % (
            encoded(report["path"]) if report["path"] else "UNAVAILABLE"
        ),
        "HANDOFF_SHA256=%s" % (report["sha256"] or "UNAVAILABLE"),
        "HANDOFF_VERIFY_TARGET=%s" % NEXT_ACTION_POINTER,
        "HANDOFF_VERIFY=%s" % ("PASS" if handoff_ok else "FAIL"),
        "BRAIN_OPERATOR_PATH=%s" % (
            encoded(brain_operator["path"])
            if brain_operator["path"]
            else BRAIN_OPERATOR_RELATIVE_PATH
        ),
        "BRAIN_OPERATOR_SHA256=%s" % (brain_operator["sha256"] or "UNAVAILABLE"),
        "GATE_FAILURES=%s" % (",".join(gate_failures) if gate_failures else "NONE"),
        "RAW_EVIDENCE_MANIFEST[path,size,sha256]",
        "RAW_EVIDENCE_COUNT=%d" % len(manifest_files),
    ]
    for index, raw in enumerate(manifest_files, start=1):
        lines.extend([
            "RAW_%d_PATH=%s" % (index, encoded(raw["path"])),
            "RAW_%d_SIZE_BYTES=%s" % (
                index,
                raw["size_bytes"] if raw["size_bytes"] is not None else "UNAVAILABLE",
            ),
            "RAW_%d_SHA256=%s" % (index, raw["sha256"] or "UNAVAILABLE"),
            "RAW_%d_TEXT_VALIDATION=%s" % (
                index,
                "PASS" if raw["error"] is None else "FAIL",
            ),
        ])
    lines.extend([
        "RAW_REJECTED_COUNT=%d" % len(rejected_files),
        "RAW_REJECTED_REASONS=%s" % (
            ",".join(sorted({raw["error"] or "unknown" for raw in rejected_files}))
            if rejected_files
            else "NONE"
        ),
        "NOT_EXECUTED_SOURCE=EXPLICIT_HANDOFF_LINES_ONLY",
        "NOT_EXECUTED_COUNT=%d" % len(not_executed),
    ])
    if not not_executed:
        lines.append("NOT_EXECUTED=NOT_REPORTED")
    else:
        lines.extend(
            "NOT_EXECUTED_%d=%s" % (index, encoded(value, safe="-._~"))
            for index, value in enumerate(not_executed, start=1)
        )
    lines.extend([
        "BLOCKERS_SOURCE=EXPLICIT_HANDOFF_LINES_ONLY",
        "BLOCKER_COUNT=%d" % len(blockers),
    ])
    if not blockers:
        lines.append("BLOCKERS=NOT_REPORTED")
    else:
        lines.extend(
            "BLOCKER_%d=%s" % (index, encoded(value, safe="-._~"))
            for index, value in enumerate(blockers, start=1)
        )
    lines.extend([
        "NEXT_ACTION_POINTER=%s" % NEXT_ACTION_POINTER,
        "DESKTOP_PATH=~/Desktop/%s" % BRAIN_DESKTOP_FILENAME,
        "",
    ])
    return "\n".join(lines)


def write_desktop_packet(packet, task, dry_run):
    target_display = "~/Desktop/%s" % BRAIN_DESKTOP_FILENAME
    if dry_run:
        return target_display

    desktop = Path.home() / "Desktop"
    if not desktop.is_dir():
        die("desktop_directory_missing", task)
    target = desktop / BRAIN_DESKTOP_FILENAME
    if target.is_symlink():
        die("desktop_target_is_symlink", task)

    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        descriptor = os.open(str(target), flags, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(packet)
            stream.flush()
            os.fsync(stream.fileno())
    except OSError as exc:
        die("desktop_write_failed_%s" % type(exc).__name__, task)
    try:
        os.chmod(target, 0o600)
    except OSError:
        pass
    return target_display


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Write the metadata-only FST BRAIN RETURN V2 transport packet."
    )
    parser.add_argument("--task", required=True, help="short task identifier")
    parser.add_argument(
        "--result",
        required=True,
        choices=VALID_RESULTS,
        help="requested Worker result; PASS is downgraded when a gate fails",
    )
    parser.add_argument(
        "--full-report",
        default=DEFAULT_FULL_REPORT,
        help="repo-local UTF-8 handoff/report path (default handoffs/CURRENT_HANDOFF.md)",
    )
    parser.add_argument(
        "--raw",
        action="append",
        default=[],
        metavar="REPO_RELATIVE_PATH",
        help="optional repo-local UTF-8 evidence file; manifest metadata only",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="render and evaluate gates without writing Desktop",
    )
    args = parser.parse_args(argv)

    task = args.task.strip()
    if not task or any(ord(char) < 32 or ord(char) == 127 for char in task):
        die("invalid_task", "UNKNOWN")

    root = require_repo_root(task)
    report = inspect_repo_text(root, args.full_report)
    brain_operator = inspect_repo_text(root, BRAIN_OPERATOR_RELATIVE_PATH)
    raw_files = [inspect_repo_text(root, path, metadata_only=True) for path in args.raw]
    raw_files.sort(key=lambda item: (item["path"] is None, item["path"] or ""))

    snapshot = git_snapshot(root)
    handoff_ok = verify_handoff(root)

    gate_failures = []
    if not handoff_ok:
        gate_failures.append("handoff_verify_fail")
    if not snapshot["clean"]:
        gate_failures.append("dirty_worktree")
    if not snapshot["remote_sync"]:
        gate_failures.append("head_not_upstream")
    if snapshot["errors"]:
        gate_failures.append("git_observation_fail")
    if report["error"] is not None:
        gate_failures.append("handoff_artifact_invalid")
    if brain_operator["error"] is not None:
        gate_failures.append("brain_operator_artifact_invalid")
    if any(raw["error"] is not None for raw in raw_files):
        gate_failures.append("raw_evidence_invalid")

    effective_result = args.result
    if args.result == "PASS" and gate_failures:
        effective_result = "FAIL"

    packet = render_packet(
        task=task,
        requested_result=args.result,
        effective_result=effective_result,
        report=report,
        brain_operator=brain_operator,
        raw_files=raw_files,
        snapshot=snapshot,
        handoff_ok=handoff_ok,
        gate_failures=gate_failures,
    )
    handoff_display = report["path"] or DEFAULT_FULL_REPORT
    write_desktop_packet(packet, task, args.dry_run)
    compact_return(effective_result, task, handoff_display)
    return 0 if effective_result == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
