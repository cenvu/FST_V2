<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-brain-return-finalizer
description: At the end of a completed or failed BRAIN-routed FST Worker task, verify and publish its handoff, commit/push/fetch-check when mutating, then export the single 03_FST_BRAIN.md return.
---

# Skill: fst-brain-return-finalizer

## Purpose

Give Hùng one predictable file to drag into ChatGPT Web BRAIN while keeping all canonical artifacts inside the FST repository.

## When to Use

Use at the end of every meaningful Worker prompt that originated from BRAIN / ChatGPT Web, whether the Worker result is PASS or FAIL.

## Authority

- Repository/GitHub truth wins.
- Worker handoff/model output is evidence, not canonical truth.
- `handoffs/CURRENT_HANDOFF.md` is the current project snapshot and operational continuation record; it is not repository truth or a journal.
- `~/Desktop/03_FST_BRAIN.md` is a non-canonical transport projection only.
- BRAIN role and routing behavior come from `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`.
- The Worker may propose one next decision only. BRAIN owns acceptance,
  classification, review, and active-next state.

## Single Desktop Rule

The only FST path an Agent may create, write, export, copy, or replace on Desktop is:

```text
~/Desktop/03_FST_BRAIN.md
```

Do not create alternate Desktop reports, RAW files, handoff copies, prompts, screenshots, packets, or convenience filenames. Do not enumerate or clean Desktop. Repository artifacts remain in repository-authorized locations.

## V2.1 Packet Contract

`03_FST_BRAIN.md` begins with `PACKET=FST_BRAIN_RETURN_V2_1` and contains machine-dense key/value fields:

- all V2 repository, branch, HEAD, upstream, sync, worktree, result, gate, handoff, explicit-fact, RAW manifest, and Desktop pointer fields;
- canonical handoff and BRAIN Operator paths plus SHA256;
- handoff verification, gate failures, and a sorted RAW manifest (repo-relative path, byte size, SHA256);
- NOT_EXECUTED and BLOCKER values only when explicitly keyed in the handoff, with no semantic inference;
- the exact UTF-8 bytes of `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`, delimited by `BRAIN_OPERATOR_BEGIN` and `BRAIN_OPERATOR_END`, with byte length and validation status.

The compact operator snapshot is a standalone fallback only. Its SHA256 must equal both the canonical repository file hash and the embedded snapshot hash. A missing, unreadable, non-UTF-8, or unhashable operator file downgrades requested PASS to FAIL. There is no arbitrary byte ceiling on this operator snapshot. Full CURRENT handoff/report bodies, historical handoffs, raw evidence bodies, and full Command Center/Work History/Task Registry bodies remain excluded. The packet is M2M-dense; Hùng reads only BRAIN's Vietnamese review. GitHub/repository state remains canonical.

## Finalization Flow

For mutating work:

```text
MUTATE
-> TEST
-> PUBLISH HANDOFF
-> COMMIT
-> PUSH
-> FETCH / VERIFY UPSTREAM
-> EXPORT 03_FST_BRAIN.md
-> COMPACT RETURN
-> STOP
```

For read-only work, preserve zero mutation, publish the required handoff when the investigation is meaningful, verify repo identity, then export the bundle.

## Export Command

Normal PASS candidate:

```bash
python3 FST_AI/tools/export_brain_return.py \
  --task "<task>" \
  --result PASS
```

Optional repo-local RAW evidence (metadata only):

```bash
python3 FST_AI/tools/export_brain_return.py \
  --task "<task>" \
  --result PASS \
  --raw handoffs/evidence/<artifact>.md
```

Failed or blocked Worker result:

```bash
python3 FST_AI/tools/export_brain_return.py \
  --task "<task>" \
  --result FAIL
```

PASS is fail-closed. The exporter downgrades PASS to FAIL when:

- `publish_handoff.py --verify` fails;
- the worktree is not clean;
- local HEAD does not equal the configured upstream;
- required Git observations fail;
- the canonical BRAIN Operator snapshot is missing, unreadable, invalid UTF-8, or cannot be hashed.

FAIL remains exportable so BRAIN receives evidence and can adjudicate it.

The publisher validates schema and deterministic ownership, freshness, and
reference fields. It cannot authenticate a BRAIN decision from ChatGPT Web.
Keep BRAIN review pending unless an explicitly authorized later task provides
canonical provenance; do not simulate post-BRAIN acceptance in a Worker report.

## Worker User-Visible Return

Do not paste the full report or RAW evidence into terminal/chat. Normal final output is exactly the compact five lines produced by the exporter:

```text
RESULT: PASS|FAIL
TASK: <task>
HANDOFF: <repo-relative full report>
BRAIN_FILE: ~/Desktop/03_FST_BRAIN.md
SEND TO BRAIN: ~/Desktop/03_FST_BRAIN.md
```

The final line is the Owner action. Stop after it; do not auto-start the next task.

## Safety / Scope

This skill is control-plane only. It must not change copy, verify, rsync, report safety semantics, TransferState, SAFE TO EJECT, source-media behavior, or app runtime behavior.
