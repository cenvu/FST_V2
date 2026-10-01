# FST Agent Handoff

## 1. Handoff Identity

- Handoff ID: 20261001-090052_codex-local-worker_storage-preflight-logical-size-safety
- Created At: 2026-10-01T09:00:52+07:00
- Handoff Type: NORMAL
- Corrects Handoff: NONE
- Previous Handoff: 20261001-005243_codex-local-worker_ui-7-final-verification-repair.md

## 2. Task and Phase

TASK=Storage Preflight Logical Size Safety
TASK_ID=STORAGE_PREFLIGHT_LOGICAL_SIZE_SAFETY
PHASE=SAFETY_CORE
STATUS=IMPLEMENTED;BRAIN_INDEPENDENT_REVIEW_PENDING
SPRINT=YES;LEAN=YES;GITHUB_ISSUE=NONE;NO_UI8=YES

## 3. Agent and Model

AGENT_HOST=Codex local Worker
PROVIDER=OpenAI;MODEL=UNVERIFIED;CLI_VERSION=UNVERIFIED
EXECUTION=local_tool_harness;NO_SUBAGENTS

## 4. Repository Snapshot

REPO=cenvu/FST_V2;LOCAL=/Users/cenvu/DEV/FST_V2
ORIGIN=https://github.com/cenvu/FST_V2.git;BRANCH=main
START_HEAD=0d43d789d98904559b18ff0132ac9d34ff16a343
PREFLIGHT=clean;fetch_exit0;ff_only_up_to_date;HEAD_EQ_ORIGIN_MAIN
FINAL_HEAD_AND_CLEAN_SYNC=V2_PACKET_FIELDS_AFTER_COHERENT_COMMIT_PUSH_FETCH
NO_RESET_CLEAN_STASH_REBASE_FORCE=YES;PR_TAG_RELEASE=NONE

## 5. Starting Context

AUTHORITY=AGENTS;BRAIN_OPERATOR_COMPACT;COMMAND_CENTER_HANDOVER;TASK_REGISTRY;WORK_HISTORY;FST_AI_standards_roles;docs00-03;CodeGraph_rules_status;finalizer_skill;CURRENT_HANDOFF
PRIOR_TASK=UI7_native_QA_observed_sparse_undercount;core_repair_not_previously_completed
SOURCE=DriveService.scanFolder;StorageMetadata;TransferPreflightValidator;Coordinator_preflight_and_observer_callers;RsyncEngine.RsyncCommand;StorageAnalysisView;ViewModel_storage_gate;canonical_MetadataOnlySourceSafety_and_Runtime_XCTests
ISSUE_LOOKUP=gh_issue_list_all_100;exit0;[];NO_ISSUE_MUTATION
CODEGRAPH=not_exposed;direct_source_test_caller_inspection_used
NO_PRODUCTION_PATCH_BEFORE_REPRO=CONFIRMED

## 6. Work Completed

RESEARCH_ORDER=canonical_source>Apple_Foundation_docs_and_local_SDK>official_rsync_v3.4.4_tagged_man_source>bounded_local_repro
COMMUNITY_RESEARCH=not_needed;primary_sources_resolved_question
APPLE=fileSize_is_logical_regular_file_content_length;totalFileSize_is_displayable_size_may_include_metadata;totalFileAllocatedSize_is_disk_allocation_may_be_smaller_for_compressed_files
RSYNC=-a_does_not_include_-S_or_-X;sparse_files_default0;write_file_uses_normal_buffered_writes_unless_sparse_enabled;sender_maps_st_size
FILESYSTEM_IMPLICATION=source_holes_or_compression_do_not_define_destination_allocation;allocation_depends_on_destination_FS;APFS_local_repro_proves_current_command_can_need_logical_content_size_and_overhead
DECISION=use_fileSize_not_allocated_or_displayable_size;keep_rsync_args_unchanged
REPAIR=DriveService.scanFolder_sums_logical_regular_file_sizes;nil_or_negative_fileSize_throws_existing_sourceUnavailable;metadata_comment_documents_contract
CONSUMER_PATH=scan>SourceStorageMetadata.totalSizeBytes>Storage_Readiness_Required+VM_Start_gate+TransferPreflightValidator+Coordinator_observer_totalBytes
EXCLUSIONS=unchanged;directory_skip_unchanged;Task.checkCancellation_unchanged
MODEL=comment_only;no_new_fields_or_storage_model_refactor
REPORT=implementation_schema_unchanged;existing_numeric_total_and_average_inherit_corrected_metadata
NO_CHANGED=rsync_flags;verification;SAFE_TO_EJECT;report_logic;Telegram;ETA;progress2;UI;Xcode_project

REPRO_SETUP=temporary_source_destination_only;no_owner_media;actual_BundledRsyncService_verified_repo_binary_v3.4.4;actual_RsyncCommand_used
SPARSE_SETUP=write_4096_bytes_0x5a;seek_1073737728;write_4096_bytes_0x5b;logical1073741824
COMPRESSED_SETUP=8388608_bytes_0x5a;system_ditto_--hfsCompression_to_temp_source
ARGS=-a;-h;--info=name1,progress2;--outbuf=N;--exclude=.DS_Store;--exclude=._*;--exclude=.Spotlight-V100;--exclude=.Trashes;--exclude=.fseventsd;--exclude=.TemporaryItems;TMP/source;TMP/destination/
SPARSE_FLAG=ABSENT;ALL_FOUR_RSYNC_RUNS_EXIT=0;SOURCE_FILESYSTEM=APFS;DESTINATION_FILESYSTEM=APFS

| Repro | Source fileSize/totalFileSize | Source allocated/isSparse | Scan required | Insufficient available/admission | Destination fileSize/allocated/isSparse | Observer copied/total |
|---|---|---|---|---|---|---|
| Before sparse | 1073741824/1073741824 | 32768/true | 32768 | 536870912/ADMITTED | 1073741824/1081344000/true | 32768/32768 |
| After sparse | 1073741824/1073741824 | 32768/true | 1073741824 | 536870912/BLOCKED | 1073741824/1081606144/true | 1073741824/1073741824 |
| Before compressed | 8388608/8388608 | 65536/false | 65536 | 4194304/ADMITTED | 8388608/8388608/false | 65536/65536 |
| After compressed | 8388608/8388608 | 65536/false | 8388608 | 4194304/BLOCKED | 8388608/8388608/false | 8388608/8388608 |

SUFFICIENT_SYNTHETIC_CAPACITY=logical_bytes;ADMITTED_BEFORE_AND_AFTER;POST_FIX_REQUIRED_EQUALS_LOGICAL
SOURCE_UNCHANGED=all4_runs_SHA256+size+allocation+sparse_flag+mtime+permissions_match_before_after
DESTINATION_HASH_MATCH=all4_runs
SPARSE_SHA256=0caeeb1dfe559c345ffb77d982a441927c45ba2baf1572022472e11f2237fe89
COMPRESSED_SHA256=7014ae0f2fc0fee42a440b97859207efb72ffee09d4864f7433f1bf756a17aca
TEMP_REPRO_CLEANUP=all4_roots_removed_and_absence_checked

## 7. Files Changed

| Path | Change | Layer/Reason | App behavior |
|---|---|---|---|
| FishSockTransfer/FishSockTransfer/Services/DriveService.swift | modified | Services; logical scan total, fail-closed missing size | required-byte safety repair |
| FishSockTransfer/FishSockTransfer/Models/StorageMetadata.swift | modified | Models; semantics comment only | no API/logic change |
| FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift | modified | seven direct/preflight/observer/cancellation tests | test only |
| FishSockTransfer/Tests/XCTest/TransferViewModelRuntimeXCTests.swift | modified | logical storage/start/observer integration | test only |
| FST_AI/memory/COMMAND_CENTER_HANDOVER.md | modified | current core repair evidence | control plane |
| FST_AI/memory/TASK_REGISTRY.md | modified | task record | control plane |
| FST_AI/memory/WORK_HISTORY.md | modified | task history | control plane |
| handoffs/CURRENT_HANDOFF.md;INDEX.md;publisher-assigned timestamped file | publisher | one NORMAL canonical handoff | control plane |

PROTECTED_TRACKED_PRODUCTION_PROJECT_FILES=70;BYTE_IDENTICAL_TO_START=YES
HISTORICAL_HANDOFF_EDITS=NONE
RsyncEngine_SHA256=33beda821aaf0f6c640375f6bab37d7a0dd897c60e3aa042985252afbf818aab
ProgressParser_SHA256=0a5123d09bf51b18b5565245a80a5d41a223062fe55bf0fe41fe2b41adc8b9bc
BUNDLED_BINARY_SHA256=bfc558eba53ad8b6ed0dbaec0d76c85f4ff21c6dbd035bed17767b26841ce915

## 8. Verification Evidence

CWD=/Users/cenvu/DEV/FST_V2;HOST=macOS15.7.7_arm64;XCODE=26.3_17C529
DEBUG_COMMAND=xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' build
DEBUG_EXIT=0;RESULT=BUILD_SUCCEEDED
FOCUSED_COMMAND=xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' -parallel-testing-enabled NO -only-testing:FishSockTransferTests/MetadataOnlySourceSafetyXCTests -only-testing:FishSockTransferTests/TransferViewModelRuntimeXCTests -only-testing:FishSockTransferTests/ProgressParserXCTests -resultBundlePath build/storage-logical-safety/focused.xcresult
FOCUSED_EXIT=0;RESULT=TEST_SUCCEEDED;PASSED=145;FAILED=0;SKIPPED=0;XCRESULT_SUMMARY_CONFIRMED=YES
FOCUSED_SUITES=MetadataOnlySourceSafety37;Runtime81;ProgressParser27
FULL_COMMAND=xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS' -parallel-testing-enabled NO -resultBundlePath build/storage-logical-safety/full.xcresult
FULL_EXIT=0;RESULT=TEST_SUCCEEDED;PASSED=255;FAILED=0;SKIPPED=0;XCRESULT_SUMMARY_CONFIRMED=YES
NEW_TESTS=8;DIRECT_DRIVESERVICE=5_PASS;PREFLIGHT=1_PASS;OBSERVER=1_PASS;VIEWMODEL=1_PASS
COVERAGE=sparse1GiB;ordinary64KiB;multi_file_sum_with_empty_file;excluded_files_and_subtree;real_compressed_fixture;logical_insufficient_and_sufficient;partial50percent/full_observer_bounds;cancelled_scan;source_contents_metadata_unchanged
REPRO_COMPILE=all_production_Swift_except_App_entrypoint+LogicalSizeRepro;before_and_after_exit0
REPRO_RUNS=build/storage-logical-safety/repro-before_and_repro-after;each_sparse_and_--compressed;all_exit0
DIFF_CHECK=PASS_EXIT0_BEFORE_HANDOFF
PUBLISH_PROTOCOL=dryrun>diffcheck>publish_once>immediate_diffcheck>verify
FINALIZATION_GATES=recorded_by_git_and_V2_packet_after_publication_commit_push_fetch
NOT_EXECUTED=OTHER_FILESYSTEM_PHYSICAL_REPRO;NATIVE_UI_QA;NIL_FILESIZE_FILESYSTEM_REPRO

## 9. Git and GitHub Evidence

START_MAIN_EQ_FETCHED_ORIGIN_MAIN=YES;START_WORKTREE_CLEAN=YES
SOURCE_TEST_DIFF=two_production_paths+two_XCTest_paths_only
CORE_SCOPE_AUDIT=no_Coordinator_Engine_ViewModel_View_project_report_or_notification_diff
COMMIT_POLICY=one_coherent_repair+memory+canonical_handoff_commit;normal_push;fetch_verify
FINAL_HEAD_UPSTREAM_CLEAN=V2_PACKET_HEAD_UPSTREAM_HEAD_REMOTE_SYNC_WORKTREE_CLEAN
GITHUB_ISSUE=NONE;PR_TAG_RELEASE=NONE

## 10. CodeGraph Evidence

MCP=UNAVAILABLE_IN_SESSION;QUERIES=NONE;NO_GRAPH_CLAIM
FALLBACK=direct_source;all_totalSizeBytes_callers;actual_command_factory;source_and_destination_scanners;canonical_tests;Git_protected_file_comparison
LAYER=Services_scan_owns_file_measurement;Models_comment_only;workflow_ownership_unchanged
CodeGraph is advisory and did not replace direct source inspection.

## 11. Remaining Risks and Unknowns

BLOCKERS=NONE
RISK=logical_content_total_is_payload_floor_not_physical_allocation_upper_bound;APFS_dest_sparse_repro_allocated_more_than_logical_due_to_FS_allocation_overhead;directory_metadata_cluster_rounding_not_budgeted_here
RISK=capacity_is_snapshot_not_reservation;source_growth_or_other_writers_may_change_space_after_preflight;no_new_headroom_or_model_refactor
LIMIT=other_filesystems_not_physically_tested;compressed_XCTest_skips_when_fixture_FS_cannot_compress_but_current_run_skipped0
REVIEW=BRAIN_independent_safety_core_review_pending;no_release_or_UI8_authorized

## 12. Safety Invariants

SOURCE_READ_ONLY=PRESERVED;setup_writes_only_synthetic_temp_fixtures
COORDINATOR_STATE_OWNERSHIP=PRESERVED;SAFE_TO_EJECT=PRESERVED;VERIFY_NONE_COPY_ONLY=PRESERVED
BUNDLED_RSYNC_3.4.4_ONLY=PRESERVED;FLAGS_UNCHANGED;NO_SPARSE_FLAG_ADDED
VERIFY_REPORT_TELEGRAM_ETA_PROGRESS2_LOGIC=PRESERVED;byte_identical
EXCLUSIONS_AND_CANCELLATION=PRESERVED_AND_TESTED
OBSERVER_VISIBILITY_ONLY=PRESERVED;totals_coherent_with_logical_payload
NO_STORAGE_MODEL_REFACTOR=YES;NO_UI8=YES

## 13. Single Next Action

ACTION=RETURN_TO_BRAIN
REASON=independent_safety_core_review_of_canonical_diff_primary_refs_repro_and_tests
ACCEPTANCE=logical_requirement_is_used_consistently;flags_protected_files_unchanged;canonical_test_and_final_repo_packet_gates_verified
STOP=after_compact_exporter_return;no_UI8_or_next_implementation

## 14. Resume Prompt

```text
TASK=STORAGE_PREFLIGHT_LOGICAL_SIZE_SAFETY_REVIEW
READ=AGENTS.md;COMMAND_CENTER_HANDOVER;BRAIN_OPERATOR_COMPACT;TASK_REGISTRY;WORK_HISTORY;handoffs/CURRENT_HANDOFF.md
CHECK=canonical_GitHub_HEAD_and_local_status;relevant_issue;actual_DriveService_scan_and_totalSizeBytes_consumers;Apple_and_rsync_primary_refs;before_after_repro;tests
CODEGRAPH=connect_if_available;advisory;direct_source_wins
ACTION=RETURN_TO_BRAIN;independent_safety_core_review_only
SPRINT=YES;LEAN=YES;NO_UI8
IF_FOLLOWUP_EXPLICITLY_ROUTED=smallest_safe_edit;test;new_immutable_handoff;one_coherent_commit;normal_push;fetch_verify;export_only_~/Desktop/03_FST_BRAIN.md_via_export_brain_return.py;compact_return;stop
HISTORY=never_edit_old_handoffs
```

## 15. References

- [Apple fileSize](https://developer.apple.com/documentation/foundation/urlresourcevalues/filesize)
- [Apple totalFileSize](https://developer.apple.com/documentation/foundation/urlresourcevalues/totalfilesize)
- [Apple totalFileAllocatedSize](https://developer.apple.com/documentation/foundation/urlresourcevalues/totalfileallocatedsize)
- [Apple isSparse](https://developer.apple.com/documentation/foundation/urlresourcevalues/issparse)
- [Rsync v3.4.4 man source](https://github.com/RsyncProject/rsync/blob/v3.4.4/rsync.1.md) sparse1705-1733;archive829;default_local_whole_file1751
- [Rsync v3.4.4 options](https://github.com/RsyncProject/rsync/blob/v3.4.4/options.c) sparse_files_default0;--sparse_sets1
- [Rsync v3.4.4 fileio](https://github.com/RsyncProject/rsync/blob/v3.4.4/fileio.c) write_file_sparse_branch_or_buffered_write
- [Rsync v3.4.4 sender](https://github.com/RsyncProject/rsync/blob/v3.4.4/sender.c) maps_logical_st_size
- APPLE_SDK=MacOSX.sdk/Foundation.framework/Headers/NSURL.h;fileSize290;totalFileSize292;totalFileAllocatedSize293
- PRIOR_HANDOFF=20261001-005243_codex-local-worker_ui-7-final-verification-repair.md
- LOCAL_EVIDENCE=build/storage-logical-safety/{LogicalSizeRepro.swift,repro-before-sparse.log,repro-before-compressed.log,repro-after-sparse.log,repro-after-compressed.log,debug.log,focused.log,focused-summary.json,full.log,full-summary.json};ignored_local_only;durable_facts_above
- CANONICAL=repository_source_and_this_handoff;V2_DESKTOP=~/Desktop/03_FST_BRAIN.md;transport_only;final_command_has_no_raw_payload