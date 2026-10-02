# FST EN/VI Localization L1 Inventory

TASK=FST_EN_VI_LOCALIZATION_L1_TRANSFER_AND_SETTINGS
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
BASE=6f1c6050ff00d4cfc72b17d3419ae8d046431b21
AUDIT=BEFORE_PRODUCTION_MUTATION
CODEGRAPH=UNAVAILABLE;DIRECT_SOURCE_INSPECTION

This inventory classifies the existing candidate strings before any production
localization edits. String Catalog lookup is the presentation mechanism.
English remains the source language. Dynamic values are resolved only after
state/classification decisions; raw backend text and path components remain
unchanged.

## App shell

| Source | Candidate string(s) | Classification | L1 handling |
|---|---|---|---|
| `FishSockTransferApp.swift` | No operator-facing strings; app/window identity comes from the product metadata. | `PRESERVE_TECHNICAL_IDENTIFIER` | Keep bundle/product identity unchanged. |
| `ContentView.swift` | `FST`; `CenVu D.I.T Tools` | `PRESERVE_TECHNICAL_IDENTIFIER` | Brand/product name remains as authored. |
| `ContentView.swift` | `TRANSFER`; `NOTIFICATION`; `TECHNICAL LOG` (tab labels only) | `LOCALIZE_UI` | `TRANSFER` → `SAO CHÉP`; `NOTIFICATION` → `THÔNG BÁO`; `TECHNICAL LOG` → `NHẬT KÝ KỸ THUẬT`. |
| `ContentView.swift` | `Source protection · Read-only` | `LOCALIZE_UI` | Localize the shell safety note; no safety meaning changes. |
| `ContentView.swift` | `Technical Log`; `Operational runtime log · Diagnostics optional`; `Show Diagnostics`; `Auto-scroll active`; visible/total entry count; `Filtering does not change the complete log.` | `L2_TECHNICAL_LOG` | Screen contents stay English in L1. |
| `ContentView.swift` | Version, bundled rsync, license badge labels; update check/status/action text | `LOCALIZE_UI` | Outside L1 Transfer/Settings scope; deferred to L2. Product/version/rsync identifiers remain intact. |
| `ContentView.swift` | Update and social-link help/accessibility phrases; social brand names | `LOCALIZE_ACCESSIBILITY` | Remaining app-facing accessibility/help audit is queued for L2; brand names remain unchanged. |

## Source and destination cards

| Source | Candidate string(s) | Classification | L1 handling |
|---|---|---|---|
| `SourceCardView.swift` | `Source`; `TOTAL SIZE`; `FILES`; `FOLDERS` | `LOCALIZE_UI` | `Nguồn`; `TỔNG DUNG LƯỢNG`; `TỆP`; `THƯ MỤC`. |
| `SourceCardView.swift` | `Select Source`; `Drop folder here`; `Choose…`; `Change…` | `LOCALIZE_UI` | `Chọn nguồn`; `Thả thư mục vào đây`; `Chọn…`; `Đổi…`. |
| `SourceCardView.swift` | `Analyzing source metadata…`; `Source metadata unavailable.` | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | `Đang phân tích thông tin nguồn…`; `Không đọc được thông tin nguồn.` |
| `SourceCardView.swift` | `Choose Source Folder`; `Clear Source Folder`; clear-selection safety explanation | `LOCALIZE_ACCESSIBILITY` | Localize labels/help while retaining the guarantee that FST only clears its selection and does not change the on-disk folder. |
| `SourceCardView.swift` | `Source path: ` prefix and selected source path | `LOCALIZE_ACCESSIBILITY` for prefix; `PRESERVE_PATH_OR_FILENAME` for path | Localize only the spoken prefix; keep the path byte-for-byte. |
| `SourceCardView.swift` | Selected folder name, path, byte/count values | `PRESERVE_PATH_OR_FILENAME` for folder/path; `PRESERVE_TECHNICAL_IDENTIFIER` for values/units | Keep names, path components, numbers, and byte values unchanged. |
| `DestinationCardView.swift` | `Destination`; `FILESYSTEM`; `FREE SPACE`; `WRITABLE`; `YES`; `NO` | `LOCALIZE_UI` | `Đích`; `HỆ TỆP`; `DUNG LƯỢNG TRỐNG`; `CÓ THỂ GHI`; `CÓ`; `KHÔNG`. |
| `DestinationCardView.swift` | `Select Destination`; `Drop folder here`; `Choose…`; `Change…` | `LOCALIZE_UI` | `Chọn đích`; `Thả thư mục vào đây`; `Chọn…`; `Đổi…`. |
| `DestinationCardView.swift` | `Analyzing destination metadata…`; `Destination metadata unavailable.` | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | `Đang phân tích thông tin đích…`; `Không đọc được thông tin đích.` |
| `DestinationCardView.swift` | `Choose Destination Folder`; `Clear Destination Folder`; clear-selection safety explanation | `LOCALIZE_ACCESSIBILITY` | Localize labels/help and preserve the statement that the destination is never deleted or modified by clearing the FST selection. |
| `DestinationCardView.swift` | `Destination path: ` and `Destination target preview: ` prefixes | `LOCALIZE_ACCESSIBILITY` | Localize spoken labels only. |
| `DestinationCardView.swift` | `Will create: ` preview prefix | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Localize the presentation prefix only; preserve the destination/source name suffix. |
| `DestinationCardView.swift` | Filesystem name, selected folder, path, destination/source components in preview, capacity values | `PRESERVE_PATH_OR_FILENAME` and `PRESERVE_TECHNICAL_IDENTIFIER` | Keep names, filesystem identifiers, paths, and values unchanged. |

## Capacity presentation

| Source | Candidate string(s) | Classification | L1 handling |
|---|---|---|---|
| `StorageAnalysisView.swift` | `Select source and destination.`; `Analyzing storage…`; `CAPACITY PRECHECK PASSED`; `INSUFFICIENT DESTINATION SPACE`; `DESTINATION NOT WRITABLE` | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Localize visible status wording only; keep the same branches and admission behavior. |
| `StorageAnalysisView.swift` | `Capacity is a snapshot, not a reservation. Transfer preflight remains authoritative.` | `LOCALIZE_ACCESSIBILITY` | Translate the safety help without weakening either statement. |
| `StorageMetadata.swift` → `DestinationCapacityAssessment.supportingText` | APFS allocation-floor/overhead explanation; unvalidated allocation-overhead explanation | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Translate faithfully; retain snapshot, validated APFS floor where applicable, overhead/other writers, and no-guarantee language. |
| `StorageAnalysisView.swift` | `Payload`; `Admission Floor`; `Available`; `Margin Above Floor` | `LOCALIZE_UI` | `Dữ liệu`; `Mức tối thiểu cần có`; `Khả dụng`; `Phần dư trên mức tối thiểu`. |
| `StorageAnalysisView.swift` / `TransferViewModel.swift` | `capacityAssessmentError`, service/preflight error text, `storageWarningMessage`, dynamic start-block reason | `PRESERVE_RAW_BACKEND_MESSAGE` | Keep exact runtime/service text in L1 unless it is a separately identified stable presentation key. Never rewrite the model value. |
| `DestinationStorageMetadata` and capacity presentation | Filesystem identifiers, allocation units, byte counts and derived values | `PRESERVE_TECHNICAL_IDENTIFIER` | No unit, formula, policy, or value changes. |

## Transfer setup, status, and actions

| Source | Candidate string(s) | Classification | L1 handling |
|---|---|---|---|
| `TransferControlsView.swift` | `Bandwidth`; `Bandwidth Limit`; `Unlimited`; `Copy speed cap` | `LOCALIZE_UI` | `Giới hạn tốc độ`; `Giới hạn tốc độ`; `Không giới hạn`; `Giới hạn tốc độ sao chép`. |
| `TransferControlsView.swift` / `VerificationMode` | `COPY ONLY — Fastest`; `SAMPLE 33% — Balanced`; `FULL 100% — Maximum confidence`; verification descriptions | `LOCALIZE_UI` | Translate labels/descriptions, retaining coverage and hash semantics. |
| `VerificationMode.swift` | Raw cases `none`, `random33`, `full`; `SHA256`; `xxHash64`; report/operator algorithm labels | `PRESERVE_PROTOCOL_OR_ALGORITHM` | Keep enum/state values and algorithm names unchanged. |
| `TransferControlsView.swift` | `Cancel Transfer?`; `Cancel Transfer`; `Continue Transfer`; cancellation explanation | `LOCALIZE_UI` | `Hủy quá trình sao chép?`; `Hủy sao chép`; `Tiếp tục sao chép`; faithfully state that the current transfer stops while selections remain available. |
| `TransferControlsView.swift` | `Open Technical Log`; `Technical Details` | `LOCALIZE_UI` | `Mở nhật ký kỹ thuật`; `Chi tiết kỹ thuật`. |
| `TransferControlsView.swift` / presentation helpers | `START TRANSFER`; `PREPARING TRANSFER`; `CANCEL`; `TRANSFER COMPLETE`; `SAFE TO EJECT`; `TRANSFER ERROR`; `RETRY`; `START NEW TRANSFER` | `LOCALIZE_UI` | `BẮT ĐẦU SAO CHÉP`; `ĐANG CHUẨN BỊ SAO CHÉP`; `HỦY`; `SAO CHÉP HOÀN TẤT`; `CÓ THỂ THÁO Ổ AN TOÀN`; `LỖI SAO CHÉP`; `THỬ LẠI`; `SAO CHÉP MỚI`. |
| `TransferControlsView.swift` / presentation helpers | `READY`; `SETUP REQUIRED`; `PREPARING`; `COPYING`; `VERIFYING`; `CANCELLED`; `MANUAL CHECK REQUIRED` | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | `SẴN SÀNG`; `CẦN THIẾT LẬP`; `ĐANG CHUẨN BỊ`; `ĐANG SAO CHÉP`; `ĐANG XÁC MINH`; `ĐÃ HỦY`; `CẦN KIỂM TRA THỦ CÔNG`. Apply after canonical `TransferState`/manual-check classification. |
| `TransferControlsView.swift` | `Job Status`; copy/verify progress, ETA, elapsed/speed labels; `AVERAGE COPY SPEED`; `COPY ELAPSED`; `COPIED`; `FILES`; current-file labels | `LOCALIZE_UI` | Localize labels only. Numeric percentages, durations, `MB/s`, `GB`, and file values remain unchanged. |
| `TransferControlsView.swift` | `Finalizing…`; `Estimating…`; `remaining`; stable waiting/preparing/CinemaDNG presentation notices | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Translate known presentation wrappers/status text; preserve time/value/path suffixes and the `CinemaDNG` identifier. |
| `TransferControlsView.swift` / helpers | `Ready to transfer`; setup, scanning, copy/verify in-progress, completion, cancellation, and error fallback summaries | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Translate exact stable summaries only; keep all state/action selection unchanged. |
| `TransferControlsView.swift` / helpers | `MANUAL CHECK REQUIRED` backend marker and `errorMessage` classification input | `PRESERVE_RAW_BACKEND_MESSAGE` | Recognition remains on the canonical English marker. Only the already-classified visible title is localized. |
| `TransferControlsView.swift` / helpers | Unknown `errorMessage`, workflow phase title/message, technical details and raw diagnostics | `PRESERVE_RAW_BACKEND_MESSAGE` | Display unknown/runtime details exactly as received; no machine translation or backend mutation. |
| `TransferControlsView.swift` / helpers | Current file/path, report path and report-warning reason suffix | `PRESERVE_PATH_OR_FILENAME` / `PRESERVE_RAW_BACKEND_MESSAGE` | Localize known report wrappers only; keep file/path and reason suffixes exact. |
| `TransferControlsView.swift` | `Report saved: `, stable report-skipped summary, `Report warning: ` | `LOCALIZE_KNOWN_PRESENTATION_STATUS` | Localize known wrappers/status while preserving report path and warning detail. Existing report-status recognition remains on the original string. |
| `TransferControlsView.swift` | Percent/ETA/accessibility values, duration, `MB/s`, byte and file counts | `PRESERVE_TECHNICAL_IDENTIFIER` | Keep displayed values and metric formatting; localize surrounding known accessibility wording only. |

## Explicit L2 boundary

| Source | Candidate string(s) | Classification | Handling |
|---|---|---|---|
| `NotificationTabView.swift` | All screen copy, controls, help, accessibility, validation/status text | `L2_NOTIFICATION` | Not localized in L1. |
| `TerminalLogsView.swift` and `ContentView.swift` log composition | Technical Log screen text, log categories/lines, diagnostics controls and raw entries | `L2_TECHNICAL_LOG` | Not localized in L1. |
| App metadata/update UI and remaining app-wide accessibility/help | Version/update badges, update statuses/actions, social-link help, other out-of-Transfer strings | `L2_TECHNICAL_LOG` | Queued as remaining L2 app presentation/untranslated-string audit. |

## Classification guardrails

- Literal SwiftUI text is a String Catalog candidate and follows the SwiftUI
  environment `Locale`.
- Computed presentation strings require explicit locale-aware String Catalog
  lookup against a bounded set of known keys. Unknown runtime text is returned
  unchanged.
- Transfer-state transitions, manual-check recognition, capacity branches,
  verification outcomes, report parsing, and transfer configuration remain
  based on their existing canonical values.
- Path/name suffixes, numeric values, filesystem and algorithm identifiers,
  and raw technical/backend detail are not translated.
