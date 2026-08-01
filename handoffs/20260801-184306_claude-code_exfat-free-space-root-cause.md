# FST Agent Handoff

## 1. Handoff Identity

- Handoff ID: 20260801-184306_claude-code_exfat-free-space-root-cause
- Created At: 2026-08-01T18:43:06+07:00
- Handoff Type: VERIFICATION
- Corrects Handoff: NONE
- Previous Handoff: 20260801-181901_antigravity-ide_push-verifyengine-cancellation-contract-commit.md

## 2. Task and Phase

- Task: Prompt 1/5 of the approved exFAT free-space fix plan — reproduce the destination-free-space bug using disposable exFAT and APFS disk images, trace the complete code path, identify the exact root cause with evidence, define the Prompt 2/5 fix surface.
- Phase: Prompt 1/5 — reproduction and root-cause investigation only
- GitHub Issue: NONE
- Sprint Mode: YES
- Lean Mode: YES
- Task Status: COMPLETE

## 3. Agent and Model

- Agent Host: Claude Code
- Provider: Anthropic
- Model: Claude Sonnet 5
- CLI or IDE Version: UNVERIFIED
- Execution Mode: interactive

## 4. Repository Snapshot

- Repository: /Users/cenvu/DEV/FST_V2
- Branch: main
- Starting Commit: 9bce869b0a6cd7fae7281b808cccb0cf128c93dc
- Ending Commit: 9bce869b0a6cd7fae7281b808cccb0cf128c93dc; not committed
- Working Tree Before: no staged files, no production/test diff, expected handoff/session/cache exclusions
- Working Tree After: same, plus publisher-owned CURRENT/INDEX updates and this new handoff
- Related PR: NONE
- Related Commit: NONE

## 5. Starting Context

- Authority files read: AGENTS.md, handoffs/CURRENT_HANDOFF.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md, docs/00_AI_AGENT_START_HERE.md, FST_AI/memory/TASK_REGISTRY.md, FST_AI/memory/WORK_HISTORY.md, docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md, docs/03_PROJECT_MASTER_GUIDELINE.md, CLAUDE.md, FST_AI/memory/CODEGRAPH_OPERATING_RULES.md, FST_AI/memory/CODEGRAPH_INDEX_STATUS.md
- Previous handoff read: 20260801-181901_antigravity-ide_push-verifyengine-cancellation-contract-commit.md
- Task request: Prompt 1/5 of a fixed five-prompt plan — reproduce, trace, root-cause, define Prompt 2 scope, publish one handoff, stop. Do not fix, do not modify production/test code, do not commit/push.
- Known blockers: NONE
- Relevant task history: no prior TASK_REGISTRY/WORK_HISTORY entry mentions exFAT or destination free-space — new investigation, not a repeat.
- Relevant GitHub Issue: NONE (queue confirmed empty)

## 6. Work Completed

- CONFIRMED repository baseline matched expected exactly (HEAD/origin/main both 9bce869, divergence 0 0, no staged files, no production/test diff).
- CONFIRMED via direct source inspection the complete code path from drag/drop and FolderPicker selection through `TransferViewModel.selectDestinationFolder` -> `refreshDestinationMetadata` -> `DriveService.destinationMetadata(for:)` -> `DriveService.calculateFreeSpace(at:)` -> published `destinationMetadata` -> `DestinationCardView` display and `TransferViewModel.hasInsufficientDestinationSpace`/`canStartTransfer` gating; also traced the separate backend preflight path through `TransferCoordinator.runWorkflow` -> `DriveService.calculateReliableFreeSpace(at:)` -> `TransferPreflightValidator.validate`.
- CONFIRMED `BookmarkService` and any `startAccessingSecurityScopedResource`/`stopAccessingSecurityScopedResource` call are entirely absent from this chain (repository-wide grep) — the sandboxed app relies on transient user-selected-URL entitlement only.
- CONFIRMED (repository-wide grep + read) no existing canonical XCTest exercises `DriveService.calculateFreeSpace`/`calculateReliableFreeSpace` against a real mounted filesystem; all existing free-space tests inject a synthetic `Int64` directly into `TransferPreflightValidator.validate`.
- CONFIRMED via two disposable disk images under `/tmp` (`FST_EXFAT_REPRO_20260801183235.dmg`, `FST_APFS_CONTROL_20260801183235.dmg`; exFAT volume label capped at 11 chars by `newfs_exfat`, discovered by bisection) that `URLResourceValues.volumeAvailableCapacityForImportantUsage` returns a real, non-nil `Int64` `0` on both a disposable exFAT volume and a disposable APFS disk-image volume, while `volumeAvailableCapacity` correctly reports true free space (733,642,752 B exFAT; 730,906,624 B APFS-image) in both cases, cross-checked against `diskutil info`, `df`/`statfs`, and `FileManager.attributesOfFileSystem` (all agree with `volumeAvailableCapacity`).
- CONFIRMED via a control query on the real, physical, internal boot APFS volume that `volumeAvailableCapacityForImportantUsage` returns a correct, large, non-zero value there (32,094,195,645 B) — the defect is specific to disk-image-backed volumes in this environment, not universal.
- CONFIRMED via a compiled `/tmp` probe built from byte-identical (diff-verified) unmodified copies of the actual `DriveService.swift`/`StorageMetadata.swift`/`TransferFileExclusionPolicy.swift`/`TransferEvent.swift` (Method 2 of the required method order; Method 1 unavailable, no repository file modified) that the real production code returns `freeSpaceBytes = 0` for exFAT root, exFAT nested, APFS-image root, and APFS-image nested alike, that `ByteCountFormatter` renders this as "Zero KB", and that the actual `TransferViewModel` eligibility formula (simulated with the real 4 MB fixture) evaluates to Start BLOCKED in all four cases — an exact reproduction of the user's reported symptom.
- CONFIRMED via direct before/during/after queries that toggling `startAccessingSecurityScopedResource`/`stopAccessingSecurityScopedResource` around the query has zero effect on the returned value (0 in all three queries) — `SECURITY_SCOPE_TIMING` ruled out with direct evidence.
- CONFIRMED root vs nested destination folder produced identical results on both filesystems in every case — `VOLUME_ROOT_RESOLUTION` ruled out.
- CONFIRMED via CodeGraph advisory queries (serial, no forced reindex): `DriveService`/`StorageMetadata`/`BookmarkService` symbol locations MATCH direct source; `codegraph_get_callers` on `calculateFreeSpace` is INCORRECT/PARTIAL (misses the real production caller `destinationMetadata(for:)`, known Swift call-edge limitation); Start-eligibility/drag-drop logic in `TransferViewModel.swift` is BLOCKED (file unparseable, pre-existing documented limitation, not investigated further).
- CONFIRMED existing targeted canonical test class (`MetadataOnlySourceSafetyXCTests`, 24 tests, the only class mentioning `DriveService`/free space) passes 24/24 at `/tmp/FST-EXFAT-FreeSpace-Investigation` — baseline unaffected by this Sprint.
- CONFIRMED full cleanup: both disposable disk images detached (`hdiutil detach`, both reported ejected) and their `/tmp` `.dmg` files removed; `mount`/`diskutil list` confirm no test volume remains; no real/physical/internal disk was ever touched, formatted, erased, or ejected.
- Root cause classified: `OPTIONAL_OR_ERROR_COLLAPSED_TO_ZERO` — `DriveService.calculateFreeSpace(at:)` (and identically, via its `>= 0` guard, `calculateReliableFreeSpace(at:)`) trusts `volumeAvailableCapacityForImportantUsage` whenever it is non-nil, including when it is a real-but-misleading `0`, instead of cross-validating against the reliably correct `volumeAvailableCapacity` key.

## 7. Files Changed

| Path | Change Type | Reason | Production Behavior Changed |
|---|---|---|---|
| (none in repository) | review-only | investigation Sprint; no repository source/test edits | NO |

Files inspected but not changed: DriveService.swift, BookmarkService.swift, StorageMetadata.swift, TransferViewModel.swift, TransferCoordinator.swift, DestinationCardView.swift, FolderPicker.swift, StorageAnalysisView.swift, TransferControlsView.swift, TransferEvent.swift, TransferFileExclusionPolicy.swift, FishSockTransfer.entitlements, MetadataOnlySourceSafetyXCTests.swift, Tests/UnitTests/Services/DriveServiceTests.swift (found stale/orphaned, not part of the canonical target).

Non-repository artifacts created and left for reviewer inspection under `/tmp/FST-EXFAT-FreeSpace-Investigation/probe/` (byte-identical source copies + compiled probe binaries + probe source `.swift` drivers); disk images and mounted volumes were fully cleaned up (see Cleanup Evidence in the full report).

## 8. Verification Evidence

- Exact commands: `hdiutil create`/`attach`/`detach`, `diskutil info`/`list`, `mount`, `df -h`, `swiftc -O -parse-as-library ... -o fst_probe` against diff-verified unmodified copies of repository source, the compiled probe itself, a security-scope timing probe, a `ByteCountFormatter` probe, and `xcodebuild test -only-testing:FishSockTransferTests/MetadataOnlySourceSafetyXCTests` at `/tmp/FST-EXFAT-FreeSpace-Investigation`.
- Targeted test result: PASS 24/24, 0 failed (MetadataOnlySourceSafetyXCTests, the only class touching DriveService/free-space).
- Full test result: not run (read-only investigation Sprint per instructions; no source/test changed).
- Exit codes: all commands exited 0 except the two initial exFAT `hdiutil create` attempts, which failed with a diagnosed and resolved volume-label-length issue unrelated to the bug under investigation.
- Manual verification: probe output cross-checked against `diskutil info`, `df`, `statfs`, `FileManager.attributesOfFileSystem` for internal consistency (all four independent mechanisms agreed on true free space in every case).
- Tests not run and the reason: full canonical suite not run — Lean Mode, read-only Sprint, no source/test file changed.

## 9. Git and GitHub Evidence

- Branch: main
- Status: unchanged before/after — `M handoffs/CURRENT_HANDOFF.md`, `M handoffs/INDEX.md`, plus pre-existing untracked handoffs/session-context/pycache exclusions.
- Diff summary: no production or XCTest diff.
- Commit: NONE
- Pull request: NONE
- Issue: NONE
- Uncommitted files: none newly introduced by this Sprint (repository-scoped).
- Does repository state confirm the claimed work? YES — `git status`/`git diff --check` before and after this Sprint are identical apart from publisher-owned handoff files.

## 10. CodeGraph Evidence

- CodeGraph version: `@astudioplus/codegraph-mcp@0.19.1`, profile `all`.
- Index commit: 6c35cad1 (documented snapshot; HEAD has since advanced to 9bce869, not reindexed — no forced reindex performed, per instructions).
- Queries used: `codegraph_symbol_search` ("DriveService calculateFreeSpace destination free space"), `codegraph_get_callers` (calculateFreeSpace, depth 2), `codegraph_symbol_search` ("Start eligibility canStartTransfer destination drop BookmarkService"), `codegraph_symbol_search` ("destination drop dropDestination selectDestinationFolder").
- Result: PARTIAL — symbol search for `DriveService`/`StorageMetadata`/`BookmarkService` returned MATCH (correct file/line locations, direct-source-verified); `get_callers` on `calculateFreeSpace` returned INCORRECT/PARTIAL (missed the actual production caller `destinationMetadata(for:)`); Start-eligibility/drag-drop logic (`TransferViewModel.swift`) is BLOCKED — that file is one of the four documented unparseable files.
- Symbols found: DriveService, calculateFreeSpace, calculateReliableFreeSpace, destinationMetadata, DestinationStorageMetadata, BookmarkService (saveBookmark/restoreBookmark), DestinationCardView.
- Impact analysis result: not run (investigation-only Sprint; no production edit planned in this Prompt).
- Direct-source confirmation: YES — every claim in this handoff traces to a direct `Read`/`grep`/disk-image/probe command executed in this session, not to CodeGraph output.
- Parser limitations relevant to the task: `TransferViewModel.swift` (contains `selectDestinationFolder`, `refreshDestinationMetadata`, `hasInsufficientDestinationSpace`, `canStartTransfer`) is one of the four documented unparseable files; not investigated or repaired, per instructions ("this bug is not an MCP bug").

CodeGraph is advisory and did not replace direct source inspection.

## 11. Remaining Risks and Unknowns

- P1: Real physical external exFAT drive behavior was not directly tested (safety rules forbid touching real hardware in a read-only Sprint). The disposable-image reproduction plus the `fskit`-mount evidence (the exFAT disk image mounts via macOS's newer FileSystem Kit user-space provider, not the legacy exfat kext) make it highly likely the real drive behaves identically, but this is a well-supported inference, not a direct physical-drive measurement.
- P2: Real physical external APFS drive behavior is untested and unknown — the user has not tested APFS at all, and this Sprint's APFS evidence comes from a disk image (which reproduced the bug), not physical media. Prompt 2 should not assume real external APFS drives are unaffected.
- P2: Whether other FSKit-migrated filesystem types (FAT32, NTFS) exhibit the same behavior is unknown and out of scope.
- P3: The macOS/SDK version in this environment (host 15.7.7, SDK MacOSX26.2) is newer than FST's stated macOS 13.5+ minimum; whether `volumeAvailableCapacityForImportantUsage` behaves the same way (real zero, not nil) on macOS 13.5-14.x is unknown. Prompt 2's fix should handle both `nil` and `0` defensively rather than assuming this exact OS behavior.

## 12. Safety Invariants

- Source media read-only: PRESERVED — only disposable `/tmp`-created disk images and a `/tmp` source fixture were used; no real/physical/internal disk was touched, formatted, erased, or ejected.
- Coordinator-only TransferState ownership: PRESERVED — no Coordinator or state code touched.
- SAFE TO EJECT gate: PRESERVED — unrelated to this investigation; no code changed.
- Verification none never SAFE TO EJECT: PRESERVED — unrelated.
- Bundled rsync 3.4.4 only: PRESERVED — unrelated.
- Observer/Telegram/update-check isolation: PRESERVED — unrelated.
- Cancellation cannot produce success: PRESERVED — unrelated.
- Reports cannot overstate safety: PRESERVED — no report/UI code touched.

## 13. Single Next Action

- Action: Execute Prompt 2/5 only — implement the smallest exFAT destination free-space fix and its regression tests within the exact approved files, run targeted and required full verification, publish one handoff, and stop without committing.
- Reason: Root cause is confirmed with direct, reproducible evidence on both disposable exFAT and disposable APFS volumes; the fix surface is narrowly scoped to `DriveService.swift`'s two free-space functions.
- Exact Files: FishSockTransfer/FishSockTransfer/Services/DriveService.swift (production fix), FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift or a new focused XCTest file (regression tests)
- Exact Symbols: DriveService.calculateFreeSpace(at:), DriveService.calculateReliableFreeSpace(at:)
- Acceptance Evidence: corrected functions return the true `volumeAvailableCapacity`-backed value (not 0) when `volumeAvailableCapacityForImportantUsage` is a misleading zero or nil, while still throwing `unableToDetermineDestinationFreeSpace` when no signal is available; new deterministic XCTests cover importantUsage==0, importantUsage==nil, importantUsage genuinely positive, and both-absent cases; canonical suite passes; a disposable exFAT/APFS disk-image rerun confirms correct non-zero free space end to end.
- Stop Condition: after the fix and its tests are implemented and verified — do not proceed to Prompt 3 (independent review), do not commit, do not push.

## 14. Resume Prompt

```text
Continue FST from /Users/cenvu/DEV/FST_V2 on main at HEAD 9bce869b0a6cd7fae7281b808cccb0cf128c93dc with origin/main identical and divergence 0 0. Read AGENTS.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md, docs/00_AI_AGENT_START_HERE.md, FST_AI/memory/TASK_REGISTRY.md, FST_AI/memory/WORK_HISTORY.md, then handoffs/CURRENT_HANDOFF.md and the full Prompt 1/5 report referenced there. Check git status and the current commit. Check GitHub Issues read-only (queue expected NONE). This is Prompt 2/5 of the approved fixed five-prompt exFAT free-space plan: root cause is confirmed as OPTIONAL_OR_ERROR_COLLAPSED_TO_ZERO in DriveService.calculateFreeSpace(at:)/calculateReliableFreeSpace(at:) — both trust a real-but-misleading zero from volumeAvailableCapacityForImportantUsage instead of cross-validating against the reliably correct volumeAvailableCapacity key. Perform only this Single Next Action: implement the smallest fix in FishSockTransfer/FishSockTransfer/Services/DriveService.swift, add deterministic regression tests (no new disk-image dependency should be required for the canonical suite; extract the two-key decision into a pure testable helper if needed), run targeted and full canonical verification, and if practical re-verify against a disposable exFAT/APFS disk image using the same safe /tmp-only methodology as Prompt 1 (never touch real/physical/internal disks). Publish one handoff and stop without committing or pushing. Do not proceed to Prompt 3 (independent review) or Prompt 5 (commit/push) in this Sprint.
```

## 15. References

- Prior handoffs: 20260801-180431_claude-code_verify-cancellation-final-review.md, 20260801-181355_claude-code_standalone-verifyengine-cancellation-contract-co.md, 20260801-181901_antigravity-ide_push-verifyengine-cancellation-contract-commit.md
- GitHub Issues: NONE
- Commits: NONE
- Pull requests: NONE
- Authority documents: AGENTS.md, CLAUDE.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md, docs/00_AI_AGENT_START_HERE.md, docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md, docs/03_PROJECT_MASTER_GUIDELINE.md, FST_AI/memory/TASK_REGISTRY.md, FST_AI/memory/WORK_HISTORY.md, FST_AI/memory/CODEGRAPH_OPERATING_RULES.md, FST_AI/memory/CODEGRAPH_INDEX_STATUS.md
- Reports: /tmp/FST_EXFAT_FREE_SPACE_ROOT_CAUSE.md
- Logs: /tmp/FST-EXFAT-FreeSpace-Investigation/ (probe sources/binaries, targeted-test DerivedData)