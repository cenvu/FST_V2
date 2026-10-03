# c248 Source-Level Behavior Review

C248_IMPLEMENTATION_UNCHANGED=YES
TRANSFER_START_CALLBACK=PASS; `Button(action: handleActionButton)` remains bound to the existing handler; idle handler still calls `viewModel.startTransfer()`.
TRANSFER_START_ENABLED_GATING=PASS; `.disabled(!isActionButtonEnabled)` remains on the button.
SOURCE_PICKER_CALLBACK=PASS; existing `FolderPicker.chooseFolder()` and `viewModel.selectSourceFolder(url)` callback retained.
DESTINATION_PICKER_CALLBACK=PASS; existing `FolderPicker.chooseFolder()` and `viewModel.selectDestinationFolder(url)` callback retained.
BANDWIDTH_VALUES=PASS; `RsyncBandwidthLimit.presetMegabytesPerSecond` remains the source; the same `Int?` binding is used and `Unlimited` maps to `nil`.
VERIFICATION_VALUES=PASS; same `VerificationMode.none`, `.random33`, and `.full` values remain bound to `viewModel.verificationMode`.
CUSTOM_DROPDOWN_PRESENTATION=PASS; both controls use `TransferDropdownField` with the existing option values.
LANGUAGE_FLAG=PASS; English shows 🇬🇧 and Vietnamese shows 🇻🇳.
LANGUAGE_PERSISTENCE=PASS; `toggleLanguage()` delegates to `select(_:)`; key remains `fst.app.language`.
LANGUAGE_SWITCH_RESETS_VIEWMODEL=NO; `ContentView` retains its `@StateObject` TransferViewModel; the app environment injects preference and locale.
TRANSFER_OR_SAFETY_LOGIC_CHANGED_BY_C248=NO
VERIFIER_PRODUCTION_SOURCE_EDITS=NO

Source references:

- `FishSockTransfer/FishSockTransfer/Views/TransferControlsView.swift`: custom field, existing state binding, action callback and enable gate.
- `FishSockTransfer/FishSockTransfer/Views/SourceCardView.swift` and `DestinationCardView.swift`: folder picker callbacks.
- `FishSockTransfer/FishSockTransfer/Models/RsyncBandwidthLimit.swift`: existing preset/value conversion semantics.
- `FishSockTransfer/FishSockTransfer/Models/VerificationMode.swift`: unchanged enum cases.
- `FishSockTransfer/FishSockTransfer/Localization/AppLanguage.swift`: persistence key and toggle implementation.
- `FishSockTransfer/FishSockTransfer/FishSockTransferApp.swift` and `Views/ContentView.swift`: one preference instance, locale environment, stable TransferViewModel identity.

The c248 commit contains only app entry/language/UI control files, a focused localization test, memory, and handoff/evidence paths. It does not modify transfer coordinators/view models, verification or capacity engines, notification services, log storage, or SAFE TO EJECT logic. Previous committed runtime evidence shows bidirectional EN/VI flag and presentation changes; see `handoffs/evidence/transfer-controls-language-toggle/VISUAL_QA.md` and the flag PNGs in its `EVIDENCE_INDEX.md`.
