import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest

REAL_TOOL = os.path.join(os.path.dirname(__file__), "publish_handoff.py")

VALID_HANDOFF = """# FST Agent Handoff
## HOT
HMD_SCHEMA=HANDOFF_MARKDOWN
HMD_VERSION=1
WORKSTREAM_ID=FST_TEST_HANDOFF
HANDOFF_ID=PUBLISHER_ASSIGNED
HANDOFF_TYPE=NORMAL
REPO=fixture/repo
BRANCH=main
REPO_HEAD=0000000000000000000000000000000000000000
REMOTE_HEAD=0000000000000000000000000000000000000000
HANDOFF_AT_HEAD=YES
LAST_VERIFIED_AT=2026-10-01T12:00:00+07:00
AUTH=REPO_GITHUB_CANONICAL
STATE=WORKER_REPORT_COMPLETE
GATE=WORKER_RETURN_READY
BLOCKER=NONE
NEXT_DECISION=ACTION(REVIEW_HANDOFF)
## COMPACT_REFS
REF=ref.md
## CURRENT_STATE
TASK=Fixture handoff
PHASE=CONTROL_PLANE_PILOT
WORKER_STATUS=COMPLETE
PRODUCTION_BYTES=UNCHANGED
DEAD_ENDS=NONE
## REVIEW
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET
## RAW_REFS
RAW_REF=NONE
## REPORT
This fixture contains enough evidence for a deterministic schema check.
## NEXTSTEP
WORKER_NEXT=PROPOSAL_ONLY
ACTIVE_NEXT=NONE
"""

VALID_POINTER = """<!-- FST / CenVu | (+84) 842 841 222 -->

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


class TestPublishHandoff(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.tools_dir = os.path.join(self.tmpdir, "tools")
        os.makedirs(self.tools_dir)
        self.tool_path = os.path.join(self.tools_dir, "publish_handoff.py")
        shutil.copy2(REAL_TOOL, self.tool_path)

        self.handoffs_dir = os.path.join(self.tmpdir, "handoffs")
        os.makedirs(self.handoffs_dir)
        with open(os.path.join(self.tmpdir, "AGENTS.md"), "w", encoding="utf-8") as fh:
            fh.write("repo root\n")
        with open(os.path.join(self.tmpdir, "ref.md"), "w", encoding="utf-8") as fh:
            fh.write("fixture reference\n")

        memory = os.path.join(self.tmpdir, "FST_AI", "memory")
        os.makedirs(memory)
        self.pointer_path = os.path.join(memory, "current-priority.md")
        self.write_pointer()

        self.index_path = os.path.join(self.handoffs_dir, "INDEX.md")
        self.current_path = os.path.join(self.handoffs_dir, "CURRENT_HANDOFF.md")
        with open(self.index_path, "w", encoding="utf-8") as fh:
            fh.write("index_content\n")
        with open(self.current_path, "w", encoding="utf-8") as fh:
            fh.write("current_content\n")

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def write_pointer(self, extra=""):
        with open(self.pointer_path, "w", encoding="utf-8") as fh:
            fh.write(
                VALID_POINTER + extra
            )

    def write_draft(self, content):
        path = os.path.join(self.tmpdir, "draft.md")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
        return path

    def run_tool(self, draft_path, dry_run=False):
        cmd = ["python3", self.tool_path, "--draft", draft_path]
        if dry_run:
            cmd.append("--dry-run")
        return subprocess.run(cmd, capture_output=True, text=True, cwd=self.tmpdir)

    def run_verify(self):
        return subprocess.run(
            ["python3", self.tool_path, "--verify"],
            capture_output=True,
            text=True,
            cwd=self.tmpdir,
        )

    def get_timestamped_files(self):
        return [
            f for f in os.listdir(self.handoffs_dir)
            if f.endswith(".md") and f not in ("INDEX.md", "CURRENT_HANDOFF.md")
        ]

    def publish_valid_handoff(self, content=VALID_HANDOFF):
        draft = self.write_draft(content)
        result = self.run_tool(draft)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.get_timestamped_files()), 1)
        return self.get_timestamped_files()[0]

    def test_case_A_valid_handoff_and_dry_run(self):
        draft = self.write_draft(VALID_HANDOFF)
        result_dry = self.run_tool(draft, dry_run=True)
        self.assertEqual(result_dry.returncode, 0, result_dry.stderr)
        self.assertIn("DRY-RUN: would publish", result_dry.stdout)

        result = self.run_tool(draft)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.get_timestamped_files()), 1)
        verify = self.run_verify()
        self.assertEqual(verify.returncode, 0, verify.stdout + verify.stderr)
        self.assertIn("VERIFY: PASS", verify.stdout)

    def test_schema_rejects_malformed_or_missing_deterministic_fields(self):
        invalid_cases = (
            (VALID_HANDOFF.replace("WORKSTREAM_ID=FST_TEST_HANDOFF", "WORKSTREAM_ID=bad-id"), "WORKSTREAM_ID"),
            (VALID_HANDOFF.replace("REPO_HEAD=0000000000000000000000000000000000000000", "REPO_HEAD=stale"), "REPO_HEAD"),
            (VALID_HANDOFF.replace("REF=ref.md", "REF=missing.md"), "required reference does not exist"),
            (VALID_HANDOFF.replace("NEXT_DECISION=ACTION(REVIEW_HANDOFF)", "NEXT_DECISION=ACTION(REVIEW_HANDOFF)\nNEXT_DECISION=STOP"), "repeats field NEXT_DECISION"),
            (VALID_HANDOFF.replace("This fixture contains enough evidence", "REPO_HEAD=UNKNOWN\nThis fixture contains enough evidence"), "HOT.REPO_HEAD must appear exactly once"),
            (VALID_HANDOFF.replace("BRAIN_CLASSIFICATION=UNSET", "BRAIN_CLASSIFICATION=PASS"), "BRAIN_CLASSIFICATION must remain UNSET"),
            (VALID_HANDOFF.replace("ACCEPTED_STATE=UNSET", "ACCEPTED_STATE=ACCEPTED"), "ACCEPTED_STATE must remain UNSET"),
            (VALID_HANDOFF.replace("This fixture contains enough evidence", "<PENDING> This fixture contains enough evidence"), "pending template placeholder"),
            (VALID_HANDOFF.replace("ACTIVE_NEXT=NONE", "ACTIVE_NEXT=ACTION(NEW_TASK)"), "ACTIVE_NEXT must be NONE"),
            (VALID_HANDOFF.replace("ACTIVE_NEXT=NONE", "ACTIVE_NEXT=PREVIOUS_VALID_GATE_REF:ref.md#NEXT_DECISION"), "prior BRAIN gates are not yet verifiable"),
            (VALID_HANDOFF.replace("ACTIVE_NEXT=NONE", "ACTIVE_NEXT=NONE\nACTIVE_NEXT=NONE"), "repeats field ACTIVE_NEXT"),
            (VALID_HANDOFF.replace("HANDOFF_AT_HEAD=YES", "HANDOFF_AT_HEAD=MAYBE"), "HANDOFF_AT_HEAD"),
            (VALID_HANDOFF.replace("STATE=WORKER_REPORT_COMPLETE", "STATE=ACCEPTED"), "STATE must describe Worker report progress"),
        )
        for content, expected in invalid_cases:
            with self.subTest(expected=expected):
                result = self.run_tool(self.write_draft(content), dry_run=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stderr)

    def test_unknown_freshness_is_preserved_and_valid(self):
        content = VALID_HANDOFF.replace(
            "REPO_HEAD=0000000000000000000000000000000000000000\n"
            "REMOTE_HEAD=0000000000000000000000000000000000000000\n"
            "HANDOFF_AT_HEAD=YES\n"
            "LAST_VERIFIED_AT=2026-10-01T12:00:00+07:00",
            "REPO_HEAD=UNKNOWN\nREMOTE_HEAD=UNKNOWN\nHANDOFF_AT_HEAD=UNKNOWN\nLAST_VERIFIED_AT=UNKNOWN",
        )
        filename = self.publish_valid_handoff(content)
        with open(os.path.join(self.handoffs_dir, filename), encoding="utf-8") as fh:
            published = fh.read()
        self.assertIn("REPO_HEAD=UNKNOWN", published)
        self.assertIn("REMOTE_HEAD=UNKNOWN", published)
        self.assertIn("HANDOFF_AT_HEAD=UNKNOWN", published)
        self.assertIn("LAST_VERIFIED_AT=UNKNOWN", published)

    def test_raw_ref_requires_matching_bytes_and_hash(self):
        raw_path = os.path.join(self.tmpdir, "evidence.log")
        raw_bytes = b"evidence\n"
        with open(raw_path, "wb") as fh:
            fh.write(raw_bytes)
        relative = "evidence.log"
        raw_record = "RAW_REF=PATH=%s;BYTES=%d;SHA256=%s" % (
            relative, len(raw_bytes), hashlib.sha256(raw_bytes).hexdigest()
        )
        good = VALID_HANDOFF.replace("RAW_REF=NONE", raw_record)
        self.publish_valid_handoff(good)

        bad = VALID_HANDOFF.replace(
            "RAW_REF=NONE",
            "RAW_REF=PATH=%s;BYTES=%d;SHA256=%s"
            % (relative, len(raw_bytes) + 1, hashlib.sha256(raw_bytes).hexdigest()),
        )
        result = self.run_tool(self.write_draft(bad), dry_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("RAW_REF byte length mismatch", result.stderr)

        mixed = VALID_HANDOFF.replace(
            "RAW_REF=NONE", raw_record + "\nRAW_REF=NONE"
        )
        result = self.run_tool(self.write_draft(mixed), dry_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("RAW_REF=NONE cannot be combined", result.stderr)

    def test_active_dead_ends_are_bounded_to_five(self):
        entries = "\n".join("DEAD_END_%d=approach|FAIL=reason|EV=ref.md" % n for n in range(1, 7))
        content = VALID_HANDOFF.replace("DEAD_ENDS=NONE", "DEAD_ENDS=LISTED\n" + entries)
        result = self.run_tool(self.write_draft(content), dry_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no more than five active DEAD_END entries", result.stderr)

    def test_active_dead_end_shape_and_evidence_reference_are_validated(self):
        malformed = VALID_HANDOFF.replace(
            "DEAD_ENDS=NONE", "DEAD_ENDS=LISTED\nDEAD_END_1=garbage"
        )
        result = self.run_tool(self.write_draft(malformed), dry_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be approach|FAIL=reason|EV=ref", result.stderr)

        missing_ref = VALID_HANDOFF.replace(
            "DEAD_ENDS=NONE",
            "DEAD_ENDS=LISTED\nDEAD_END_1=probe|FAIL=reason|EV=missing.md",
        )
        result = self.run_tool(self.write_draft(missing_ref), dry_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required reference does not exist", result.stderr)

        valid = VALID_HANDOFF.replace(
            "DEAD_ENDS=NONE",
            "DEAD_ENDS=LISTED\nDEAD_END_1=probe|FAIL=reason|EV=ref.md",
        )
        self.assertEqual(self.run_tool(self.write_draft(valid), dry_run=True).returncode, 0)

    def test_verify_detects_stale_projection_then_repairs_without_history_edits(self):
        filename = self.publish_valid_handoff()
        timestamped_path = os.path.join(self.handoffs_dir, filename)
        with open(timestamped_path, "rb") as fh:
            history_before = fh.read()
        with open(self.index_path, "rb") as fh:
            index_before = fh.read()
        with open(self.current_path, "rb") as fh:
            current_before = fh.read()

        self.write_pointer("TASK=stale_projection\nNEXT=outdated\n")
        stale = self.run_verify()
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("not a non-authoritative pointer to CURRENT", stale.stdout)
        with open(self.current_path, "rb") as fh:
            self.assertEqual(fh.read(), current_before)

        self.write_pointer("\n- Status: stale\n")
        markdown_stale = self.run_verify()
        self.assertNotEqual(markdown_stale.returncode, 0)
        self.assertIn("not a non-authoritative pointer to CURRENT", markdown_stale.stdout)

        self.write_pointer()
        repaired = self.run_verify()
        self.assertEqual(repaired.returncode, 0, repaired.stdout + repaired.stderr)
        self.assertIn("VERIFY: PASS", repaired.stdout)
        with open(timestamped_path, "rb") as fh:
            self.assertEqual(fh.read(), history_before)
        with open(self.index_path, "rb") as fh:
            self.assertEqual(fh.read(), index_before)

    def test_verify_detects_stale_current_and_latest_snapshot_wins(self):
        filename = self.publish_valid_handoff()
        timestamped_path = os.path.join(self.handoffs_dir, filename)
        with open(timestamped_path, "rb") as fh:
            newest = fh.read()
        with open(self.current_path, "wb") as fh:
            fh.write(b"stale snapshot\n")
        stale = self.run_verify()
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("CURRENT_HANDOFF.md does not match", stale.stdout)

        with open(self.current_path, "wb") as fh:
            fh.write(newest)
        repaired = self.run_verify()
        self.assertEqual(repaired.returncode, 0, repaired.stdout + repaired.stderr)

    def test_trailing_spaces_tab_and_whitespace_only_lines_are_rejected(self):
        cases = (
            (VALID_HANDOFF.replace("schema check.", "schema check.   "), "draft contains trailing whitespace"),
            (VALID_HANDOFF.replace("schema check.", "schema check.\t"), "draft contains trailing tab"),
            (VALID_HANDOFF.replace("schema check.", "schema check.\n    \n"), "whitespace-only line"),
        )
        for content, expected in cases:
            with self.subTest(expected=expected):
                result = self.run_tool(self.write_draft(content), dry_run=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stderr)


if __name__ == "__main__":
    unittest.main()
