# Patch 5 final cross-screen comparison

BEFORE_HEAD=28c8a486d73b71da9dc64cebdee71a432dc27bda
AFTER_PRODUCTION_SOURCE=UNCHANGED
CAPTURE_APPEARANCE=DARK_AQUA
NOMINAL=1120x760 points;2240x1520 pixels
MINIMUM=900x660 points;1800x1320 pixels
MATCHED_PAIRS=20
BYTE_IDENTICAL_PAIRS=20

The native app reads as one system across the three tabs: the accepted FST
shell, semantic palette, compact native controls, and fixed operational footer
remain consistent. Transfer uses a denser operational hierarchy; Notification
and Technical Log use their accepted surface intros and grouped sections. The
different title and surface treatments follow each screen's role and do not
create a material visual-only mismatch.

The terminal captures show separate color, icon, text, and action treatments
for Transfer Complete, Safe to Eject, Manual Check Required, Transfer Error,
and Cancelled. In particular, copy-only completion stays blue and says
verification was disabled; only the verified success state is green and says
Safe to Eject. Error and cancellation keep unavailable progress/ETA/speed
blank rather than showing a success-like value.

At 900x660, Source, Destination, capacity facts, active actions, and terminal
state surfaces remain inspectable. The Transfer document is 602pt high inside
a 565pt viewport, so its final 37pt is reached by scrolling. Notification is
702pt high inside the same 565pt viewport; scrolling 137pt reveals the final
event rows, both option controls, and the full preview. The Technical Log keeps
its toolbar, feed, activity summary, metadata, update control, and fixed app
footer visible together. These are native scroll behavior and do not hide a
critical state or action.

All corresponding BEFORE/AFTER PNGs are byte-identical, and no production file
changed in this pass. The complete per-region classifications are in
`PATCH5_COMPARE_A.md`; source references and accepted distinctions are in
`FINAL_CROSS_SCREEN_GAP_MATRIX.md`.
