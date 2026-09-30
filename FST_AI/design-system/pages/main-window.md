<!-- FST / CenVu | (+84) 842 841 222 -->

# Design System Page Override: Main Window

## Purpose

The main window is the operator command center.

It must answer these questions immediately:

1. What source is selected?
2. What destination is selected?
3. What phase is the job in?
4. How much is complete?
5. How much time remains for the whole job?
6. Is there any warning or error?
7. Is it SAFE TO EJECT?
8. Is report evidence available?

## Layout Priority

MAIN INFORMATION FLOW:
1. HEADER + EXISTING THREE TABS
2. SOURCE
3. DESTINATION
4. TRANSFER SETUP
5. CONTROL BAR
6. WHOLE-JOB STATUS
7. INLINE WARNING/ERROR WHEN PRESENT
8. SECONDARY RUNTIME INFORMATION

## Main Window Rules

- Avoid landing-page style hero sections.
- Avoid oversized decorative branding.
- Keep operational state above the fold.
- Keep source/destination visible during active job.
- Keep SAFE TO EJECT visible at final state.
- Do not hide warnings/errors behind tabs.
- A dedicated compact Control Bar owns the primary operational action/presentation (START TRANSFER, CANCEL, RETRY).
- The three primary hero metrics have equal hierarchy: PROGRESS, WHOLE-JOB ETA, CURRENT SPEED.

## Review Checklist

- [ ] Source and destination are visible.
- [ ] Current phase is visible.
- [ ] Main progress is visible.
- [ ] SAFE TO EJECT status is visible.
- [ ] Operator can understand the job state within 3 seconds.
- [ ] Error/warning state is not visually subtle.

