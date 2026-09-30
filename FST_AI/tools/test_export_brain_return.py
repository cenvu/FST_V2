#!/usr/bin/env python3
"""Standard-library contract tests for export_brain_return.py."""

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
        return dict(
            line.split("=", 1)
            for line in packet.splitlines()
            if "=" in line and not line.startswith("[")
        )

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


class ExportBrainReturnV2Tests(ExporterFixture):
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

    def test_clean_synced_pass_renders_metadata_only_packet(self):
        (self.repo / "raw").mkdir()
        report = self.repo / "handoffs" / "CURRENT_HANDOFF.md"
        brain = self.repo / "FST_AI" / "memory" / "BRAIN_OPERATOR_COMPACT.md"
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
        brain.write_text("BRAIN_OPERATOR_BODY_MUST_NOT_APPEAR\n", encoding="utf-8")
        self.commit_and_push()

        completed = self.run_exporter(raw=["raw/z.log", "raw/a.log"])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assert_compact_stdout(completed, "PASS")

        packet = self.packet()
        fields = self.fields(packet)
        self.assertTrue(packet.startswith("PACKET=FST_BRAIN_RETURN_V2\n"))
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
        self.assertEqual(
            fields["BRAIN_OPERATOR_SHA256"],
            hashlib.sha256(brain.read_bytes()).hexdigest(),
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
            "BRAIN_OPERATOR_BODY_MUST_NOT_APPEAR",
            "RAW_A_BODY_MUST_NOT_APPEAR",
            "RAW_Z_BODY_MUST_NOT_APPEAR",
            "FULL REPORT",
            "BRAIN OPERATOR — VERBATIM",
        ):
            self.assertNotIn(body, packet)

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


if __name__ == "__main__":
    unittest.main()
