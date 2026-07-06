# FST v1.3.4 - Detailed TXT Report V1 Hardening

## Highlights
- Hardened Detailed TXT Report V1 sections for clearer operator review.
- Added a bilingual disclaimer near the top of generated reports.
- Removed obsolete safety wording from active report output.
- Clarified final verified success wording as SAFE TO EJECT DESTINATION.
- Updated report filenames and job IDs so they no longer use the source name.
- Reduced operator-facing rsync detail to rsync 3.4.4.
- Added a technical log sharing note to report output.
- Updated report wording safety tests.

## Safety
- FST reports copy and verification results only. Decisions to erase, format, or reuse source media remain the user's responsibility.
- SAFE TO EJECT applies to destination eject safety evidence only.
- Random33 remains sample verification and must not be described as full verification.
- No transfer engine changes.
- No verify/hash logic changes.
- No rsync behavior changes.
- No Telegram behavior changes.
- No update-check behavior changes.
- No UI overhaul.

## Technical
- Builds continue to use bundled rsync 3.4.4 only.
- App version metadata is prepared for v1.3.4 display version with build 20260706.
- The package remains a local owner-side ad-hoc build unless separately signed and notarized.

## Known Limitations
- This release is not Developer ID signed and not notarized unless a later packaging step proves otherwise.
- Runtime QA on real production media is still required before declaring production readiness.
- FST does not format, erase, reuse, or eject source media.
