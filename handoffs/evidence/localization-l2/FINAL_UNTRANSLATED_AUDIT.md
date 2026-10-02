# FST EN/VI Localization L2 — Final Untranslated Audit

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
BASE=e4fa800902478899930d04c85a144c6b8d9147ab
OPERATOR_UI_LOCALIZATION_COVERAGE=COMPLETE
CATALOG_TOTAL_KEYS=195
CATALOG_VI_TRANSLATED_KEYS=195
MISSED_UI_STRING_COUNT=0

## Audit method and result

Reviewed production SwiftUI text/control/accessibility/help sites, computed
presentation call sites, the full L2 source inventory, existing L1 transfer
presentation keys, and the single String Catalog. Literal operator UI keys
resolve through `Localizable.xcstrings`; computed L1/L2 values use their
bounded allowlists. Unknown runtime text remains unchanged. `Text(verbatim:)`
language endonyms are deliberately stable.

The catalog JSON reports English source language, 195 entries, and 195
translated Vietnamese entries. All 68 `L2PresentationKey` allowlist entries
have Vietnamese translations. The focused XCTest suite verifies the L2
catalog values, including dynamic status, metadata, social accessibility, and
the app-settings strings. The built app contains a valid
`vi.lproj/Localizable.strings` resource.

No remaining localizable operator-facing UI string was found. The English
material below is intentionally preserved by source/data boundary. This is
not a claim that raw logs, generated reports, legal values, or outbound
Telegram messages have been translated.

## Intentional English classification

Count basis: distinct stable brand/identifier values or dynamic data-surface
families, with one primary class per item. Duplicate uses and individual
runtime values are not counted repeatedly.

| Classification | Count | Preserved English-looking values or surfaces |
|---|---:|---|
| `BRAND` | 7 | CenVu, FST, Facebook, Instagram, WhatsApp, Telegram, GitHub. Social tooltips remain brand names; names in localized accessibility labels remain intact. |
| `TECHNICAL_IDENTIFIER` | 11 | Bot Token; Chat ID; rsync; APFS; SHA256; xxHash64; CinemaDNG; MB/s; GB; app version `v1.3.5`; bundled rsync version `3.4.4`. |
| `RAW_RUNTIME` | 5 | Unlisted notification `lastMessageStatus` values; `lastErrorSummary`; timestamp/level/category/message fields in actual `LogEntry` output; service/runtime diagnostic log lines; structured TXT report output. |
| `PATH_FILENAME_URL` | 5 | Source and destination paths/components; selected/current file and folder names; report path/filename; release/download URLs; `README.md` filename references in help. |
| `OUTBOUND_TELEGRAM_MESSAGE` | 1 | The production `NotificationMessageFactory` message/preview surface, including event headers, field labels, failure safety text, and durations. |
| `DEVELOPER_INTERNAL` | 0 | No remaining developer-only string is presented as operator UI. Service diagnostics visible in the Technical Log are classified as raw runtime. |
| `INTENTIONALLY_ENGLISH_LEGAL_VALUE` | 1 | `Source Available / Non-Commercial`. |
| `MISSED_UI_STRING` | **0** | PASS. |

## Specific preservation decisions

- Telegram delivery status values outside the exact allowlist (for example,
  `Skipped: Telegram notification disabled`, `Telegram send failed`, and
  `Sent … at …`) pass through unchanged. `lastErrorSummary` is displayed
  verbatim under the localized `Last error` label.
- Actual Terminal Log timestamps, levels, categories, messages, paths,
  stdout/stderr, and diagnostics remain canonical/raw. The populated EN/VI
  captures use the same synthetic raw lines.
- The Telegram preview remains the exact English production factory payload.
  `NotificationMessageFactory.message(...)` is not locale-aware.
- Version numbers, legal text, technical identifiers, paths, filenames, and
  URLs are not rewritten.

## Coverage conclusion

`OPERATOR_UI_LOCALIZATION_COVERAGE=COMPLETE` because every localizable
operator-facing UI string is covered in the existing English-source catalog
with Vietnamese text. The raw and intentionally-English surfaces above remain
English by explicit boundary, so this must not be reported as “100% translated.”
