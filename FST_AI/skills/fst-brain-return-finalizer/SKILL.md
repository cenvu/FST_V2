<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-brain-return-finalizer
description: Finalize every BRAIN-routed FST Worker task into the canonical handoff plus the single Desktop 03_FST_BRAIN.md return envelope.
---

# Skill: fst-brain-return-finalizer

## Purpose

Give Hùng one predictable file to drag into ChatGPT Web BRAIN while keeping all canonical artifacts inside the FST repository.

## When to Use

Use at the end of every meaningful Worker prompt that originated from BRAIN / ChatGPT Web, whether the Worker result is PASS or FAIL.

## Authority

- Repository/GitHub truth wins.
- Worker handoff/model output is evidence, not canonical truth.
- `handoffs/CURRENT_HANDOFF.md` remains the canonical operational continuation record.
- `~/Desktop/03_FST_BRAIN.md` is a non-canonical transport projection only.
- BRAIN role and routing behavior come from `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`.

## Single Desktop Rule

The only FST path an Agent may create, write, export, copy, or replace on Desktop is:

```text
~/Desktop/03_FST_BRAIN.md
```

Do not create alternate Desktop reports, RAW files, handoff copies, prompts, screenshots, packets, or convenience filenames. Do not enumerate or clean Desktop. Repository artifacts remain in repository-authorized locations.

## V2 Packet Contract

`03_FST_BRAIN.md` begins with `PACKET=FST_BRAIN_RETURN_V2` and contains machine-dense key/value fields:

- repository, branch, HEAD, upstream, sync and worktree state;
- canonical handoff and BRAIN Operator paths plus SHA256;
- handoff verification, gate failures, and a sorted RAW manifest (repo-relative path, byte size, SHA256);
- NOT_EXECUTED and BLOCKER values only when explicitly keyed in the handoff, with no semantic inference;
- the fixed next-action pointer and Desktop path.

Canonical handoff, RAW, and BRAIN Operator bodies are not embedded by default. The packet is a transport pointer, not a summary or authority; GitHub remains canonical.

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
- required Git observations fail.

FAIL remains exportable so BRAIN receives evidence and can adjudicate it.

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
