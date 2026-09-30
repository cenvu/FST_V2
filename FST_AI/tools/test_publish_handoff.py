import unittest
import os
import tempfile
import subprocess
import shutil

REAL_TOOL = os.path.join(os.path.dirname(__file__), "publish_handoff.py")

VALID_HANDOFF = """# FST Agent Handoff
## 1. Handoff Identity
- Handoff ID: draft
- Created At: 2026
- Handoff Type: NORMAL
- Corrects Handoff: NONE
- Previous Handoff: NONE
## 2. Task and Phase
## 3. Agent and Model
## 4. Repository Snapshot
## 5. Starting Context
## 6. Work Completed
## 7. Files Changed
## 8. Verification Evidence
## 9. Git and GitHub Evidence
## 10. CodeGraph Evidence
## 11. Remaining Risks and Unknowns
## 12. Safety Invariants
## 13. Single Next Action
This is the single next action that is long enough.
## 14. Resume Prompt
```
This is the resume prompt that is also long enough to pass.
```
## 15. References
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
        
        with open(os.path.join(self.tmpdir, "AGENTS.md"), "w") as f:
            f.write("repo root")
            
        self.index_path = os.path.join(self.handoffs_dir, "INDEX.md")
        self.current_path = os.path.join(self.handoffs_dir, "CURRENT_HANDOFF.md")
        
        with open(self.index_path, "w") as f:
            f.write("index_content\\n")
        with open(self.current_path, "w") as f:
            f.write("current_content\\n")

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def write_draft(self, content):
        path = os.path.join(self.tmpdir, "draft.md")
        with open(path, "w") as f:
            f.write(content)
        return path

    def run_tool(self, draft_path, dry_run=False):
        cmd = ["python3", self.tool_path, "--draft", draft_path]
        if dry_run:
            cmd.append("--dry-run")
        return subprocess.run(cmd, capture_output=True, text=True, cwd=self.tmpdir)

    def get_timestamped_files(self):
        return [f for f in os.listdir(self.handoffs_dir) if f.endswith(".md") and f not in ("INDEX.md", "CURRENT_HANDOFF.md")]

    def test_case_A_valid_handoff(self):
        # Validation PASS. Dry-run succeeds.
        draft = self.write_draft(VALID_HANDOFF)
        res_dry = self.run_tool(draft, dry_run=True)
        self.assertEqual(res_dry.returncode, 0)
        self.assertIn("DRY-RUN: would publish", res_dry.stdout)

        res = self.run_tool(draft)
        self.assertEqual(res.returncode, 0)
        self.assertEqual(len(self.get_timestamped_files()), 1)

    def test_case_B_trailing_spaces(self):
        # One body line ends with spaces.
        draft = self.write_draft(VALID_HANDOFF.replace("long enough.", "long enough.   "))
        res = self.run_tool(draft)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("draft contains trailing whitespace", res.stderr)
        
        # Dry-run should also fail
        res_dry = self.run_tool(draft, dry_run=True)
        self.assertNotEqual(res_dry.returncode, 0)
        self.assertIn("draft contains trailing whitespace", res_dry.stderr)

    def test_case_C_trailing_tab(self):
        draft = self.write_draft(VALID_HANDOFF.replace("long enough.", "long enough.\t"))
        res = self.run_tool(draft)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("draft contains trailing tab", res.stderr)

    def test_case_D_whitespace_only_line(self):
        draft = self.write_draft(VALID_HANDOFF.replace("long enough.", "long enough.\n    \n"))
        res = self.run_tool(draft)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("draft contains whitespace-only line", res.stderr)

    def test_case_E_leading_spaces_only(self):
        draft = self.write_draft(VALID_HANDOFF.replace("This is the single", "    This is the single"))
        res = self.run_tool(draft)
        self.assertEqual(res.returncode, 0)

    def test_case_F_valid_final_identity_replacement(self):
        # Provided by test_case_A_valid_handoff as it goes through fill_identity and final validation
        draft = self.write_draft(VALID_HANDOFF)
        res = self.run_tool(draft)
        self.assertEqual(res.returncode, 0)

    def test_case_G_atomicity(self):
        draft = self.write_draft(VALID_HANDOFF.replace("long enough.", "long enough. "))
        res = self.run_tool(draft)
        self.assertNotEqual(res.returncode, 0)
        
        self.assertEqual(len(self.get_timestamped_files()), 0)
        
        with open(self.index_path, "r") as f:
            self.assertEqual(f.read(), "index_content\\n")
            
        with open(self.current_path, "r") as f:
            self.assertEqual(f.read(), "current_content\\n")

    def test_case_H_raw_rsync_output(self):
        # Reproduce the actual failure shape: a code-fenced output line ending with two spaces.
        bad_handoff = VALID_HANDOFF.replace("```\nThis is the resume", "```\nThis is the resume  \n")
        draft = self.write_draft(bad_handoff)
        res = self.run_tool(draft)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("draft contains trailing whitespace", res.stderr)

if __name__ == "__main__":
    unittest.main()
