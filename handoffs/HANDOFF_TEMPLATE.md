<!-- FST Handoff Markdown schema v1. Copy only for a task that needs a new
     handoff. The publisher replaces publisher-assigned identity fields. -->

# FST Agent Handoff

## HOT

HMD_SCHEMA=HANDOFF_MARKDOWN
HMD_VERSION=1
WORKSTREAM_ID=<UPPERCASE_WORKSTREAM_ID>
HANDOFF_ID=PUBLISHER_ASSIGNED
HANDOFF_TYPE=NORMAL
REPO=<owner/name>
BRANCH=<branch>
REPO_HEAD=<40-character-sha-or-UNKNOWN>
REMOTE_HEAD=<40-character-sha-or-UNKNOWN>
HANDOFF_AT_HEAD=YES|NO|UNKNOWN
LAST_VERIFIED_AT=<ISO-8601-with-timezone-or-UNKNOWN>
AUTH=REPO_GITHUB_CANONICAL
STATE=IN_PROGRESS|WORKER_REPORT_COMPLETE|WORKER_BLOCKED
GATE=WORKER_EVIDENCE_INCOMPLETE|WORKER_RETURN_READY
BLOCKER=NONE|<STABLE_BLOCKER_KEY>
NEXT_DECISION=ACTION(<one-action>)|WAIT(<one-gate>)|DONE|NO_WORK_NEEDED|OWNER_DECISION|STOP

## COMPACT_REFS

REF=AGENTS.md
REF=handoffs/CURRENT_HANDOFF.md

## CURRENT_STATE

TASK=<task id and name>
PHASE=<phase>
WORKER_STATUS=<completed, blocked, or partial evidence state>
PRODUCTION_BYTES=<UNCHANGED|CHANGED_WITHIN_AUTHORIZED_SCOPE>
DEAD_ENDS=NONE

## REVIEW

BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET

## RAW_REFS

RAW_REF=NONE

## REPORT

Record bounded evidence, exact verification commands/results, changed paths,
risks and unknowns. Put references before detail. Do not claim BRAIN acceptance,
classification, or active-next authority.

## NEXTSTEP

WORKER_NEXT=PROPOSAL_ONLY
ACTIVE_NEXT=NONE
