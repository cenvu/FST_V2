<!-- FST / CenVu | (+84) 842 841 222 -->

# FST — V1 Worklog Archived

Version: Archived  
Source: FishSock Transfer (FST) v.1.md  
Status: Historical Reference Only

---

## 1. Purpose

This file preserves useful V1 history without acting as current project authority.

Current authority is:

1. PRD.md
2. Project_Master_Guideline.md
3. ARCHITECTURE.md
4. AI_Engineering_System_Prompt.md
5. AI_Coding_Agent_Guide.md

---

## 2. V1 Completed

- Product design established
- Google AI Studio prototype completed
- SwiftUI migration approach defined
- Xcode macOS project created
- Initial dashboard launched
- Basic UI structure built
- Core development workflow validated

---

## 3. V1 Lessons

AI Studio is useful for:

- Product design
- UI exploration
- Architecture drafting
- Rapid prototype thinking

AI Studio output is not production macOS code.

Validated workflow:

```text
Product idea -> AI Studio prototype -> Architecture -> Codex -> SwiftUI -> Xcode -> Review -> Git
```

---

## 4. Superseded V1 Assumptions

These are no longer current rules:

- Production use of `/usr/bin/rsync`
- MVVM-only architecture
- Queue engine before MVP safety completion
- Multi-destination before MVP safety completion
- Database/history before TXT report completion
- APFS analysis as higher priority than transfer safety

Current project uses:

- Bundled rsync 3.4.4
- MVVM + Coordinator + Engine + Service
- Single source
- Single destination
- Single job
- TXT report only

---

## 5. Current Phase

Current phase is not V1.1 feature expansion.

Current phase:

```text
TRANSFER PIPELINE AUDIT + RELIABILITY FIXES
```

Priority:

1. Bundled rsync detection/version
2. App version vs rsync version separation
3. Speed limiter correctness
4. .DS_Store hang investigation
5. Progress accuracy
6. Cancellation safety
7. Verification engine
8. SAFE TO FORMAT enforcement

---

## 6. Archived Roadmap Notes

Items still valid for MVP:

- Source picker
- Destination picker
- Drag/drop
- Real-time logs
- Transfer cancel
- Progress tracking
- Verification
- TXT report

Items postponed:

- Queue engine
- Multi-destination copy
- History database
- Media validation suite
- Workflow templates

---

## 7. Merge Decision

This document should not remain as a Codex guide.

Use it only as historical context.

The actionable content has been merged into `ARCHITECTURE.md` section:

```text
25. V1 Worklog Integration
```
