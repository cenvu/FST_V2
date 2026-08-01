<!-- FST Handoff Template — copy this file, fill every section, then publish
     with FST_AI/tools/publish_handoff.py. This template is NOT a published
     handoff and is NEVER added to handoffs/INDEX.md. Timestamped handoffs
     are immutable after publication; corrections are new handoffs. -->

# FST Agent Handoff

## 1. Handoff Identity

- Handoff ID: <!-- publisher fills (timestamped filename) or <your ID> -->
- Created At: <!-- publisher fills (YYYY-MM-DDTHH:MM:SS+07:00) or <your ISO time> -->
- Handoff Type: NORMAL | CORRECTION | VERIFICATION | BLOCKED <!-- choose one -->
- Corrects Handoff: NONE | <historical-filename.md>
- Previous Handoff: NONE | <previous-filename.md>

## 2. Task and Phase

- Task: <one-line task statement>
- Phase: <phase name, e.g. "Infrastructure setup">
- GitHub Issue: <issue URL or number> | NONE
- Sprint Mode: YES
- Lean Mode: YES
- Task Status: <COMPLETE | BLOCKED | PARTIAL>

## 3. Agent and Model

- Agent Host: <Claude Code | Codex CLI | Antigravity IDE | other>
- Provider: <provider or UNVERIFIED>
- Model: <model or UNVERIFIED — never guess>
- CLI or IDE Version: <version or UNVERIFIED>
- Execution Mode: <interactive | non-interactive | harness | other>

## 4. Repository Snapshot

- Repository: /Users/cenvu/DEV/FST_V2
- Branch: <branch>
- Starting Commit: <full or short SHA>
- Ending Commit: <full or short SHA, or "not committed">
- Working Tree Before: <clean | changes summary>
- Working Tree After: <clean | changes summary>
- Related PR: <URL or number> | NONE
- Related Commit: <SHA> | NONE

## 5. Starting Context

- Authority files read: <list>
- Previous handoff read: <filename | NONE>
- Task request: <the actual request>
- Known blockers: <list | NONE>
- Relevant task history: <TASK_REGISTRY/WORK_HISTORY entries>
- Relevant GitHub Issue: <summary | NONE>

## 6. Work Completed

Describe only work actually completed. Mark confidence:

- <CONFIRMED | INFERRED | UNVERIFIED | BLOCKED> <statement of work done>

Do not claim a fix when only investigation was performed.

## 7. Files Changed

| Path | Change Type | Reason | Production Behavior Changed |
|---|---|---|---|
| <path> | <created/modified/deleted> | <reason> | YES | NO |

Files inspected but not changed (important for continuation): <list | NONE>

## 8. Verification Evidence

- Exact commands: <commands with working directory>
- Exit codes: <code per command>
- Targeted test result: <passed/failed/not run + names>
- Full test result: <passed/failed/not run + counts>
- Syntax or integration checks: <result>
- Manual verification: <result>
- Tests not run and the reason: <list | NONE>

Never claim tests passed when they did not complete.

## 9. Git and GitHub Evidence

- Branch: <branch>
- Status: <git status --short summary>
- Diff summary: <git diff --stat summary>
- Commit: <SHA | NONE>
- Pull request: <URL | NONE>
- Issue: <URL | NONE>
- Uncommitted files: <list | NONE>
- Does repository state confirm the claimed work? <YES | NO | PARTIAL — explain>

GitHub Issues are the task queue. Git, tests, commits, pull requests, and
actual source are the final confirmation sources.

## 10. CodeGraph Evidence

- CodeGraph version: <version>
- Index commit: <commit the index was built at>
- Queries used: <tool names + targets>
- Result: MATCH | PARTIAL | STALE | INCORRECT | BLOCKED
- Symbols found: <list>
- Impact analysis result: <summary>
- Direct-source confirmation: <YES | NO — describe>
- Parser limitations relevant to the task: <list | NONE>

State explicitly:

CodeGraph is advisory and did not replace direct source inspection.

## 11. Remaining Risks and Unknowns

- <P0|P1|P2|P3> <concrete risk or unknown>

Only concrete remaining risks. No generic advice.

## 12. Safety Invariants

List the FST safety rules relevant to this task and state whether each
remains preserved:

- Source media read-only: PRESERVED | AFFECTED — <explain>
- Coordinator-only TransferState ownership: PRESERVED | AFFECTED
- SAFE TO EJECT gate: PRESERVED | AFFECTED
- Verification none never SAFE TO EJECT: PRESERVED | AFFECTED
- Bundled rsync 3.4.4 only: PRESERVED | AFFECTED
- Observer/Telegram/update-check isolation: PRESERVED | AFFECTED
- Cancellation cannot produce success: PRESERVED | AFFECTED
- Reports cannot overstate safety: PRESERVED | AFFECTED

## 13. Single Next Action

Exactly one primary next action:

- Action: <one sentence>
- Reason: <why>
- Exact Files: <paths>
- Exact Symbols: <type.method names>
- Acceptance Evidence: <what proves it done>
- Stop Condition: <when to stop and publish a handoff>

## 14. Resume Prompt

```text
<Self-contained prompt for the next agent. Must instruct the next agent to:
1. read authority documents (AGENTS.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md,
   docs/00_AI_AGENT_START_HERE.md, FST_AI/memory/TASK_REGISTRY.md,
   FST_AI/memory/WORK_HISTORY.md);
2. read handoffs/CURRENT_HANDOFF.md;
3. check Git status and the current commit;
4. check the relevant GitHub Issue;
5. connect fst-codegraph;
6. inspect direct source before editing;
7. perform only the Single Next Action;
8. work in Sprint Mode and Lean Mode;
9. publish a new handoff when done;
10. never edit an old handoff.>
```

## 15. References

- Prior handoffs: <list | NONE>
- GitHub Issues: <list | NONE>
- Commits: <list | NONE>
- Pull requests: <list | NONE>
- Authority documents: <list>
- Reports: <list | NONE>
- Logs: <list | NONE>
