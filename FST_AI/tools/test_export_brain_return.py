#!/usr/bin/env python3
"""Standard-library contract tests for export_brain_return.py."""

import ast
import hashlib
import os
from pathlib import Path
import runpy
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]
EXPORTER_SOURCE = REPO_ROOT / "FST_AI" / "tools" / "export_brain_return.py"
UI6_HANDOFF_FIXTURE = (
    REPO_ROOT
    / "handoffs"
    / "20260930-210332_codex-local-worker_ui-6-metrics-presentation-contract-repair.md"
)
BRAIN_OPERATOR_FIXTURE = REPO_ROOT / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"


class ExporterFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="fst-brain-return-v2-")
        self.temp_root = Path(self.temp.name)
        self.repo = self.temp_root / "repo"
        self.home = self.temp_root / "home"
        self.repo.mkdir()
        self.home.mkdir()
        self.exporter = self.repo / "FST_AI" / "tools" / "export_brain_return.py"
        self.exporter.parent.mkdir(parents=True)
        shutil.copyfile(EXPORTER_SOURCE, self.exporter)

        (self.repo / "AGENTS.md").write_text("fixture root\n", encoding="utf-8")
        (self.repo / "handoffs").mkdir()
        (self.repo / "handoffs" / "CURRENT_HANDOFF.md").write_text(
            "fixture handoff body\nNOT_EXECUTED=gui_qa\nBLOCKERS=none\n",
            encoding="utf-8",
        )
        (self.repo / "FST_AI" / "memory").mkdir()
        (self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md").write_text(
            "fixture Brain Operator body\n",
            encoding="utf-8",
        )
        publisher = self.repo / "FST_AI" / "tools" / "publish_handoff.py"
        publisher.write_text(
            "import sys\n"
            "ok = sys.argv[1:] == ['--verify']\n"
            "print('VERIFY: PASS' if ok else 'VERIFY: FAIL')\n"
            "raise SystemExit(0 if ok else 1)\n",
            encoding="utf-8",
        )

        self.bare = self.temp_root / "origin.git"
        self.git(self.temp_root, "init", "--bare", str(self.bare))
        self.git(self.repo, "init", "-b", "main")
        self.git(self.repo, "config", "user.name", "FST test")
        self.git(self.repo, "config", "user.email", "fst-test@example.invalid")
        self.git(self.repo, "add", "-A")
        self.git(self.repo, "commit", "-m", "fixture baseline")
        self.git(self.repo, "remote", "add", "origin", str(self.bare))
        self.git(self.repo, "push", "-u", "origin", "main")

    def tearDown(self):
        self.temp.cleanup()

    @staticmethod
    def git(cwd, *args):
        proc = subprocess.run(
            ["git", "-C", str(cwd), *args],
            capture_output=True,
            text=True,
            timeout=20,
        )
        if proc.returncode != 0:
            raise AssertionError(
                "git command failed: %s\n%s\n%s"
                % (" ".join(args), proc.stdout, proc.stderr)
            )
        return proc.stdout.strip()

    def commit_and_push(self):
        self.git(self.repo, "add", "-A")
        self.git(self.repo, "commit", "-m", "fixture update")
        self.git(self.repo, "push", "origin", "main")

    def run_exporter(self, result="PASS", raw=(), extra=(), task="M2M Task", path=None):
        if "--dry-run" not in extra:
            self.desktop.mkdir(exist_ok=True)
        command = [
            sys.executable,
            str(self.exporter),
            "--task",
            task,
            "--result",
            result,
        ]
        for raw_path in raw:
            command.extend(["--raw", str(raw_path)])
        command.extend(extra)
        env = os.environ.copy()
        env["HOME"] = str(self.home)
        if path is not None:
            env["PATH"] = path
        return subprocess.run(
            command,
            cwd=self.repo,
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )

    @property
    def desktop(self):
        return self.home / "Desktop"

    @property
    def packet_path(self):
        return self.desktop / "03_FST_BRAIN.md"

    def packet(self):
        return self.packet_path.read_text(encoding="utf-8")

    @staticmethod
    def fields(packet):
        header = packet.split("BRAIN_OPERATOR_BEGIN\n", 1)[0]
        return dict(
            line.split("=", 1)
            for line in header.splitlines()
            if "=" in line and not line.startswith("[")
        )

    @staticmethod
    def embedded_operator_bytes(packet):
        packet_bytes = packet.encode("utf-8")
        fields = ExporterFixture.fields(packet)
        body_start = packet_bytes.index(b"BRAIN_OPERATOR_BEGIN\n") + len(
            b"BRAIN_OPERATOR_BEGIN\n"
        )
        body_size = int(fields["BRAIN_OPERATOR_UTF8_BYTES"])
        body_end = body_start + body_size
        if packet_bytes[body_end:].startswith(b"\nBRAIN_OPERATOR_END\n"):
            return packet_bytes[body_start:body_end]
        raise AssertionError("operator body length does not align with END marker")

    @staticmethod
    def raw_manifest(packet):
        start = packet.index("RAW_EVIDENCE_MANIFEST[path,size,sha256]\n")
        end = packet.index("\nNOT_EXECUTED_SOURCE=", start)
        return packet[start:end]

    def assert_compact_stdout(
        self,
        completed,
        result,
        task="M2M Task",
        handoff="handoffs/CURRENT_HANDOFF.md",
    ):
        self.assertEqual(
            completed.stdout.splitlines(),
            [
                "RESULT: %s" % result,
                "TASK: %s" % task,
                "HANDOFF: %s" % handoff,
                "BRAIN_FILE: ~/Desktop/03_FST_BRAIN.md",
                "SEND TO BRAIN: ~/Desktop/03_FST_BRAIN.md",
            ],
        )


class ExportBrainReturnV2_1Tests(ExporterFixture):
    def test_github_remote_normalizes_to_canonical_repo_id(self):
        exporter = runpy.run_path(str(EXPORTER_SOURCE))
        normalize = exporter["canonical_repo"]
        self.assertEqual(
            normalize("https://github.com/cenvu/FST_V2.git"),
            "cenvu/FST_V2",
        )
        self.assertEqual(
            normalize("git@github.com:cenvu/FST_V2.git"),
            "cenvu/FST_V2",
        )

    def test_clean_synced_pass_embeds_exact_operator_and_keeps_other_bodies_out(self):
        (self.repo / "raw").mkdir()
        report = self.repo / "handoffs" / "CURRENT_HANDOFF.md"
        brain = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
        command_center = self.repo / "FST_AI" / "memory" / "COMMAND_CENTER_HANDOVER.md"
        work_history = self.repo / "FST_AI" / "memory" / "WORK_HISTORY.md"
        task_registry = self.repo / "FST_AI" / "memory" / "TASK_REGISTRY.md"
        raw_z = self.repo / "raw" / "z.log"
        raw_a = self.repo / "raw" / "a.log"
        raw_z.write_text("RAW_Z_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        raw_a.write_text("RAW_A_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        report.write_text(
            "FULL_REPORT_BODY_MUST_NOT_APPEAR\n"
            "NOT_EXECUTED=gui_qa\n"
            "BLOCKERS=none\n",
            encoding="utf-8",
        )
        brain.write_text("BRAIN_OPERATOR_EXACT_BODY\n", encoding="utf-8")
        command_center.write_text(
            "COMMAND_CENTER_FULL_BODY_MUST_NOT_APPEAR\n", encoding="utf-8"
        )
        work_history.write_text("WORK_HISTORY_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        task_registry.write_text("TASK_REGISTRY_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        (self.repo / "handoffs" / "20200101-old.md").write_text(
            "HISTORICAL_HANDOFF_BODY_MUST_NOT_APPEAR\n", encoding="utf-8"
        )
        self.commit_and_push()

        completed = self.run_exporter(raw=["raw/z.log", "raw/a.log"])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assert_compact_stdout(completed, "PASS")

        packet = self.packet()
        fields = self.fields(packet)
        self.assertTrue(packet.startswith("PACKET=FST_BRAIN_RETURN_V2_1\n"))
        preserved_v2_fields = {
            "PACKET", "VALUE_ENCODING", "AUTHORITY_STATUS", "REQUESTED_RESULT",
            "EFFECTIVE_RESULT", "TASK", "GENERATED_AT_UTC", "REPO",
            "REMOTE_ORIGIN", "BRANCH", "HEAD", "UPSTREAM", "UPSTREAM_HEAD",
            "REMOTE_SYNC", "WORKTREE_CLEAN", "HANDOFF_PATH", "HANDOFF_SHA256",
            "HANDOFF_VERIFY_TARGET", "HANDOFF_VERIFY", "BRAIN_OPERATOR_PATH",
            "BRAIN_OPERATOR_ROLE", "BRAIN_OPERATOR_SHA256", "GATE_FAILURES",
            "RAW_EVIDENCE_COUNT",
            "RAW_REJECTED_COUNT", "RAW_REJECTED_REASONS", "NOT_EXECUTED_SOURCE",
            "NOT_EXECUTED_COUNT", "BLOCKERS_SOURCE", "BLOCKER_COUNT",
            "NEXT_ACTION_POINTER", "DESKTOP_PATH",
        }
        self.assertLessEqual(preserved_v2_fields, set(fields))
        self.assertIn("RAW_EVIDENCE_MANIFEST[path,size,sha256]", packet)
        self.assertEqual(fields["REQUESTED_RESULT"], "PASS")
        self.assertEqual(fields["EFFECTIVE_RESULT"], "PASS")
        self.assertEqual(fields["TASK"], "M2M%20Task")
        self.assertEqual(fields["REMOTE_SYNC"], "PASS")
        self.assertEqual(fields["WORKTREE_CLEAN"], "YES")
        self.assertEqual(fields["HANDOFF_VERIFY"], "PASS")
        self.assertEqual(
            fields["HANDOFF_VERIFY_TARGET"],
            "handoffs/CURRENT_HANDOFF.md",
        )
        self.assertEqual(fields["HANDOFF_PATH"], "handoffs/CURRENT_HANDOFF.md")
        self.assertEqual(
            fields["HANDOFF_SHA256"],
            hashlib.sha256(report.read_bytes()).hexdigest(),
        )
        embedded_operator = self.embedded_operator_bytes(packet)
        self.assertEqual(embedded_operator, brain.read_bytes())
        self.assertEqual(fields["BRAIN_OPERATOR_UTF8_BYTES"], str(len(embedded_operator)))
        self.assertEqual(fields["BRAIN_OPERATOR_ENCODING"], "EXACT_UTF8")
        self.assertEqual(fields["BRAIN_OPERATOR_VALIDATION"], "PASS")
        self.assertEqual(
            fields["BRAIN_OPERATOR_PATH"],
            "FST_AI/memory/BRAIN_OPERATOR_COMPACT.md",
        )
        self.assertEqual(fields["BRAIN_OPERATOR_ROLE"], "FALLBACK_ONLY")
        self.assertEqual(
            fields["BRAIN_OPERATOR_SHA256"],
            hashlib.sha256(embedded_operator).hexdigest(),
        )
        self.assertEqual(fields["RAW_EVIDENCE_COUNT"], "2")
        self.assertIn("RAW_1_PATH=raw/a.log", packet)
        self.assertIn("RAW_1_SIZE_BYTES=%d" % raw_a.stat().st_size, packet)
        self.assertIn(
            "RAW_1_SHA256=%s" % hashlib.sha256(raw_a.read_bytes()).hexdigest(),
            packet,
        )
        self.assertIn("RAW_2_PATH=raw/z.log", packet)
        self.assertIn("NOT_EXECUTED_1=gui_qa", packet)
        self.assertIn("BLOCKER_1=none", packet)
        self.assertIn("NEXT_ACTION_POINTER=handoffs/CURRENT_HANDOFF.md", packet)
        self.assertIn("DESKTOP_PATH=~/Desktop/03_FST_BRAIN.md", packet)
        self.assertEqual(fields["GATE_FAILURES"], "NONE")
        for body in (
            "FULL_REPORT_BODY_MUST_NOT_APPEAR",
            "HISTORICAL_HANDOFF_BODY_MUST_NOT_APPEAR",
            "COMMAND_CENTER_FULL_BODY_MUST_NOT_APPEAR",
            "WORK_HISTORY_BODY_MUST_NOT_APPEAR",
            "TASK_REGISTRY_BODY_MUST_NOT_APPEAR",
            "RAW_A_BODY_MUST_NOT_APPEAR",
            "RAW_Z_BODY_MUST_NOT_APPEAR",
            "FULL REPORT",
            "BRAIN OPERATOR — VERBATIM",
        ):
            self.assertNotIn(body, packet)
        self.assertIn("BRAIN_OPERATOR_EXACT_BODY", packet)

    def test_changing_operator_changes_packet_hash_and_embedded_bytes(self):
        brain = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
        brain.write_bytes("operator snapshot one\n".encode("utf-8"))
        self.commit_and_push()

        first = self.run_exporter()
        self.assertEqual(first.returncode, 0, first.stderr)
        first_packet = self.packet()
        first_fields = self.fields(first_packet)
        first_body = self.embedded_operator_bytes(first_packet)

        brain.write_bytes("operator snapshot changed\n".encode("utf-8"))
        self.commit_and_push()
        second = self.run_exporter()
        self.assertEqual(second.returncode, 0, second.stderr)
        second_packet = self.packet()
        second_fields = self.fields(second_packet)
        second_body = self.embedded_operator_bytes(second_packet)

        self.assertNotEqual(first_packet, second_packet)
        self.assertNotEqual(first_fields["BRAIN_OPERATOR_SHA256"], second_fields["BRAIN_OPERATOR_SHA256"])
        self.assertEqual(first_body, b"operator snapshot one\n")
        self.assertEqual(second_body, b"operator snapshot changed\n")
        self.assertEqual(
            second_fields["BRAIN_OPERATOR_SHA256"],
            hashlib.sha256(second_body).hexdigest(),
        )

    def test_operator_missing_or_invalid_utf8_downgrades_pass(self):
        cases = ("missing", "invalid_utf8")
        for case in cases:
            with self.subTest(case=case):
                self.tearDown()
                self.setUp()
                brain = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
                if case == "missing":
                    brain.unlink()
                    expected_error = "file_missing"
                else:
                    brain.write_bytes(b"\xffINVALID_OPERATOR_BODY")
                    expected_error = "text_not_utf8"
                self.commit_and_push()

                completed = self.run_exporter()
                self.assertEqual(completed.returncode, 1, completed.stderr)
                self.assert_compact_stdout(completed, "FAIL")
                packet = self.packet()
                fields = self.fields(packet)
                self.assertEqual(fields["REQUESTED_RESULT"], "PASS")
                self.assertEqual(fields["EFFECTIVE_RESULT"], "FAIL")
                self.assertEqual(fields["BRAIN_OPERATOR_VALIDATION"], "FAIL")
                self.assertEqual(fields["BRAIN_OPERATOR_ERROR"], expected_error)
                self.assertIn("brain_operator_artifact_invalid", fields["GATE_FAILURES"])
                self.assertIn("BRAIN_OPERATOR_BODY=UNAVAILABLE", packet)
                self.assertNotIn("INVALID_OPERATOR_BODY", packet)

    def test_unreadable_operator_downgrades_pass(self):
        exporter = runpy.run_path(str(self.exporter))
        inspect = exporter["inspect_repo_text"]
        collect = exporter["collect_gate_failures"]
        effective = exporter["effective_result"]
        resolved_repo = self.repo.resolve()
        report = inspect(resolved_repo, "handoffs/CURRENT_HANDOFF.md")
        snapshot = {
            "clean": True,
            "remote_sync": True,
            "errors": [],
        }
        with mock.patch.object(Path, "read_bytes", autospec=True, side_effect=PermissionError):
            brain = inspect(
                resolved_repo,
                "FST_AI/memory/BRAIN_OPERATOR_COMPACT.md",
                max_bytes=None,
            )

        self.assertEqual(brain["error"], "file_unreadable")
        failures = collect(report, brain, [], snapshot, True)
        self.assertIn("brain_operator_artifact_invalid", failures)
        self.assertEqual(effective("PASS", failures), "FAIL")

    def test_operator_hash_failure_downgrades_pass_but_keeps_snapshot(self):
        exporter = runpy.run_path(str(self.exporter))
        inspect = exporter["inspect_repo_text"]
        collect = exporter["collect_gate_failures"]
        effective = exporter["effective_result"]
        render = exporter["render_packet"]
        resolved_repo = self.repo.resolve()
        report = inspect(resolved_repo, "handoffs/CURRENT_HANDOFF.md")
        snapshot = {
            "repo": "cenvu/FST_V2",
            "remote_url": "https://github.com/cenvu/FST_V2.git",
            "branch": "main",
            "head": "a" * 40,
            "upstream": "origin/main",
            "upstream_head": "a" * 40,
            "clean": True,
            "remote_sync": True,
            "errors": [],
        }
        original_sha256 = hashlib.sha256

        def fail_operator_hash(data=b"", *args, **kwargs):
            if data == b"fixture Brain Operator body\n":
                raise RuntimeError("simulated hash backend failure")
            return original_sha256(data, *args, **kwargs)

        with mock.patch("hashlib.sha256", side_effect=fail_operator_hash):
            brain = inspect(
                resolved_repo,
                "FST_AI/memory/BRAIN_OPERATOR_COMPACT.md",
                max_bytes=None,
            )

        failures = collect(report, brain, [], snapshot, True)
        result = effective("PASS", failures)
        packet = render(
            "hash-failure-test",
            "PASS",
            result,
            report,
            brain,
            [],
            snapshot,
            True,
            failures,
        )
        fields = self.fields(packet)
        self.assertEqual(brain["error"], "hash_failed")
        self.assertIn("brain_operator_artifact_invalid", failures)
        self.assertEqual(result, "FAIL")
        self.assertEqual(fields["BRAIN_OPERATOR_SHA256"], "UNAVAILABLE")
        self.assertEqual(fields["BRAIN_OPERATOR_VALIDATION"], "FAIL")
        self.assertEqual(
            self.embedded_operator_bytes(packet),
            b"fixture Brain Operator body\n",
        )

    def test_operator_snapshot_has_no_inherited_8_mib_ceiling(self):
        exporter = runpy.run_path(str(self.exporter))
        limit = exporter["MAX_TEXT_BYTES"]
        body = BRAIN_OPERATOR_FIXTURE.read_bytes() + b"X" * (limit + 1)
        brain = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
        brain.write_bytes(body)
        self.commit_and_push()

        completed = self.run_exporter()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        packet_bytes = self.packet_path.read_bytes()
        packet = packet_bytes.decode("utf-8")
        fields = self.fields(packet)
        self.assertEqual(fields["BRAIN_OPERATOR_UTF8_BYTES"], str(len(body)))
        self.assertEqual(self.embedded_operator_bytes(packet), body)
        self.assertEqual(
            fields["BRAIN_OPERATOR_SHA256"],
            hashlib.sha256(body).hexdigest(),
        )
        self.assertGreater(len(packet_bytes), limit)

    def test_exporter_uses_only_python_standard_library_imports(self):
        tree = ast.parse(EXPORTER_SOURCE.read_text(encoding="utf-8"))
        imported = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                imported.update(alias.name.split(".", 1)[0] for alias in node.names)
            elif isinstance(node, ast.ImportFrom) and node.module:
                imported.add(node.module.split(".", 1)[0])
        allowed = {
            "argparse", "codecs", "datetime", "hashlib", "os", "pathlib",
            "re", "subprocess", "sys", "urllib",
        }
        self.assertLessEqual(imported, allowed)

    def test_full_report_override_remains_repo_contained_and_hashed(self):
        custom = self.repo / "handoffs" / "custom.md"
        custom.write_text("CUSTOM_REPORT_BODY\n", encoding="utf-8")
        self.commit_and_push()

        completed = self.run_exporter(
            extra=["--full-report", "handoffs/custom.md"],
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assert_compact_stdout(
            completed,
            "PASS",
            handoff="handoffs/custom.md",
        )
        packet = self.packet()
        fields = self.fields(packet)
        self.assertEqual(fields["HANDOFF_PATH"], "handoffs/custom.md")
        self.assertEqual(
            fields["HANDOFF_SHA256"],
            hashlib.sha256(custom.read_bytes()).hexdigest(),
        )
        self.assertNotIn("CUSTOM_REPORT_BODY", packet)

    def test_pass_is_downgraded_for_each_required_gate(self):
        cases = ("dirty", "handoff_verify", "upstream", "git_observation")
        for case in cases:
            with self.subTest(case=case):
                self.tearDown()
                self.setUp()
                if case == "dirty":
                    (self.repo / "untracked.txt").write_text("dirty\n", encoding="utf-8")
                    expected = "dirty_worktree"
                    path = None
                elif case == "handoff_verify":
                    publisher = self.repo / "FST_AI" / "tools" / "publish_handoff.py"
                    publisher.write_text("raise SystemExit(1)\n", encoding="utf-8")
                    self.commit_and_push()
                    expected = "handoff_verify_fail"
                    path = None
                elif case == "upstream":
                    (self.repo / "ahead.txt").write_text("ahead\n", encoding="utf-8")
                    self.git(self.repo, "add", "ahead.txt")
                    self.git(self.repo, "commit", "-m", "local ahead")
                    expected = "head_not_upstream"
                    path = None
                else:
                    expected = "git_observation_fail"
                    path = "/nonexistent"

                completed = self.run_exporter(path=path)
                self.assertEqual(completed.returncode, 1, completed.stderr)
                self.assertTrue(self.packet_path.is_file())
                fields = self.fields(self.packet())
                self.assertEqual(fields["REQUESTED_RESULT"], "PASS")
                self.assertEqual(fields["EFFECTIVE_RESULT"], "FAIL")
                self.assertIn(expected, fields["GATE_FAILURES"])

    def test_requested_fail_remains_exportable(self):
        completed = self.run_exporter(result="FAIL")
        self.assertEqual(completed.returncode, 1, completed.stderr)
        self.assertTrue(self.packet_path.is_file())
        self.assert_compact_stdout(completed, "FAIL")
        fields = self.fields(self.packet())
        self.assertEqual(fields["REQUESTED_RESULT"], "FAIL")
        self.assertEqual(fields["EFFECTIVE_RESULT"], "FAIL")
        self.assertEqual(fields["GATE_FAILURES"], "NONE")

    def test_dry_run_has_compact_return_and_writes_no_desktop_file(self):
        completed = self.run_exporter(extra=["--dry-run"])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assert_compact_stdout(completed, "PASS")
        self.assertFalse(self.desktop.exists())

    def test_only_authorized_desktop_file_is_written_with_private_mode(self):
        self.desktop.mkdir()
        completed = self.run_exporter()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(list(self.desktop.iterdir()), [self.packet_path])
        self.assertEqual(stat.S_IMODE(self.packet_path.stat().st_mode), 0o600)

    def test_raw_manifest_is_sorted_and_deterministic(self):
        (self.repo / "raw").mkdir()
        (self.repo / "raw" / "a.txt").write_text("alpha\n", encoding="utf-8")
        (self.repo / "raw" / "b.txt").write_text("beta\n", encoding="utf-8")
        self.commit_and_push()

        first = self.run_exporter(raw=["raw/b.txt", "raw/a.txt"])
        self.assertEqual(first.returncode, 0, first.stderr)
        first_manifest = self.raw_manifest(self.packet())
        second = self.run_exporter(raw=["raw/a.txt", "raw/b.txt"])
        self.assertEqual(second.returncode, 0, second.stderr)
        second_manifest = self.raw_manifest(self.packet())
        self.assertEqual(first_manifest, second_manifest)

    def test_raw_metadata_hashes_large_utf8_evidence_without_embedding(self):
        large = self.repo / "large.log"
        body = b"evidence-line\n" * (600_000)
        large.write_bytes(body)

        completed = self.run_exporter(
            result="FAIL",
            raw=["large.log"],
        )
        self.assertEqual(completed.returncode, 1, completed.stderr)
        packet = self.packet()
        self.assertIn("RAW_1_SIZE_BYTES=%d" % len(body), packet)
        self.assertIn(
            "RAW_1_SHA256=%s" % hashlib.sha256(body).hexdigest(),
            packet,
        )
        self.assertIn("RAW_1_TEXT_VALIDATION=PASS", packet)
        self.assertNotIn("evidence-line", packet)

    def test_utf8_and_repository_containment_are_enforced(self):
        (self.repo / "raw").mkdir()
        invalid_text = self.repo / "raw" / "invalid.bin"
        invalid_text.write_bytes(b"\xffraw-binary-marker")
        outside = self.temp_root / "outside.txt"
        outside.write_text("OUTSIDE_REPO_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        self.commit_and_push()

        invalid = self.run_exporter(raw=["raw/invalid.bin"])
        self.assertEqual(invalid.returncode, 1, invalid.stderr)
        invalid_packet = self.packet()
        invalid_fields = self.fields(invalid_packet)
        self.assertEqual(invalid_fields["EFFECTIVE_RESULT"], "FAIL")
        self.assertEqual(invalid_fields["RAW_1_TEXT_VALIDATION"], "FAIL")
        self.assertNotIn("raw-binary-marker", invalid_packet)

        outside_result = self.run_exporter(
            raw=["../outside.txt"],
            extra=["--full-report", "../outside.txt"],
        )
        self.assertEqual(outside_result.returncode, 1, outside_result.stderr)
        outside_packet = self.packet()
        outside_fields = self.fields(outside_packet)
        self.assertEqual(outside_fields["HANDOFF_PATH"], "UNAVAILABLE")
        self.assertEqual(outside_fields["RAW_EVIDENCE_COUNT"], "0")
        self.assertEqual(outside_fields["RAW_REJECTED_COUNT"], "1")
        self.assertNotIn("OUTSIDE_REPO_BODY_MUST_NOT_APPEAR", outside_packet)

    def test_newline_task_cannot_inject_packet_or_stdout_fields(self):
        completed = self.run_exporter(task="name\nRESULT: PASS")
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(completed.stdout.splitlines()[0], "RESULT: FAIL")
        self.assertEqual(completed.stdout.splitlines()[1], "TASK: UNKNOWN")
        self.assertEqual(len(completed.stdout.splitlines()), 5)
        self.assertFalse(self.packet_path.exists())

    def test_size_gate_shrinks_ui6_style_v1_payload_materially(self):
        report_body = UI6_HANDOFF_FIXTURE.read_bytes()
        brain_body = BRAIN_OPERATOR_FIXTURE.read_bytes()
        raw_bodies = [
            (("command and result evidence %d\n" % index) * 180).encode("utf-8")
            for index in range(1, 6)
        ]
        report_path = self.repo / "handoffs" / "CURRENT_HANDOFF.md"
        report_path.write_bytes(report_body)
        brain_path = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
        brain_path.write_bytes(brain_body)
        (self.repo / "evidence").mkdir()
        raw_paths = []
        for index, body in enumerate(raw_bodies, start=1):
            relative = "evidence/ui6-%d.log" % index
            (self.repo / relative).write_bytes(body)
            raw_paths.append(relative)
        self.commit_and_push()

        completed = self.run_exporter(raw=raw_paths)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        v2_size = len(self.packet_path.read_bytes())
        v1_style_minimum = len(report_body) + len(brain_body) + sum(
            len(body) for body in raw_bodies
        )
        self.assertGreater(v1_style_minimum, 0)
        self.assertLess(v2_size, v1_style_minimum * 0.5)
        self.assertEqual(self.embedded_operator_bytes(self.packet()), brain_body)
        self.assertEqual(
            self.fields(self.packet())["BRAIN_OPERATOR_SHA256"],
            hashlib.sha256(brain_body).hexdigest(),
        )


if __name__ == "__main__":
    unittest.main()
