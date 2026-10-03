# Visual QA — transfer controls and language toggle

RESULT=PASS;SYNTHETIC_DARK_AQUA_FIXTURES

- At 1120×760pt, the READY CTA is a text-only blue control with a compact
  4pt radius and target-like horizontal padding. Its original button action
  and enabled state remain in place.
- Source and destination Choose/Change controls use the same compact raised
  gray surface, subtle outline, and 4pt radius.
- Bandwidth and Verification are custom dark fields with a right chevron.
  Their open popovers use dark surfaces, visible selected-row treatment, and
  a checkmark. EN and VI screenshots show the selected value and option list.
- The header flag sits immediately after the FST wordmark. Accessibility
  actions show EN→VI→EN and VI→EN→VI; screenshots show the flag and transfer
  presentation changing together.
- At 900×660pt, EN and VI retain readable controls, header, state panel, and
  operational footer. No critical clipping was observed; the content region
  scrolls where needed.
- The synthetic VERIFYING capture shows locked selection controls and the
  existing Cancel treatment, without invoking transfer or verification.

## Evidence

See the PNG references in `EVIDENCE_INDEX.md`. The four open-menu PNGs are
cropped to the popover content so the custom dark surface and selected row are
clear. READY screenshots show the full app content and footer.
