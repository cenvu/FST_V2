# Behavior review — transfer controls and language toggle

TRANSFER_START_CALLBACK=UNCHANGED
TRANSFER_START_ENABLED_GATING=UNCHANGED
SOURCE_PICKER_CALLBACK=UNCHANGED
DESTINATION_PICKER_CALLBACK=UNCHANGED
BANDWIDTH_VALUES=UNCHANGED;VIEWMODEL_BINDING_RETAINED;UNLIMITED_NIL_RETAINED
VERIFICATION_VALUES=UNCHANGED;VIEWMODEL_BINDING_RETAINED
LANGUAGE_PREFERENCE_KEY=UNCHANGED;fst.app.language
LANGUAGE_PREFERENCE_PERSISTENCE=EXISTING_APP_LANGUAGE_PREFERENCE
TRANSFER_VIEWMODEL_RESET_ON_LANGUAGE_SWITCH=NO
TRANSFER_OR_VERIFICATION_STARTED_DURING_QA=NO
NOTIFICATION_SEND_OR_DELIVERY_SEMANTICS_CHANGED=NO
UPDATE_NETWORK_BEHAVIOR_CHANGED=NO
CAPACITY_OR_SAFE_TO_EJECT_LOGIC_CHANGED=NO

`TransferControlsLabelTests` passed against the actual bandwidth option table
and existing action/state contracts. The menu capture fixture selected
`50 MB/s` and `VerificationMode.full` through accessibility presses and checked
the bound values. `AppLanguagePreference.toggleLanguage()` delegates to the
existing `select(_:)` persistence path; the localization XCTest and EN/VI
runtime captures cover both directions.

Production edits are limited to the app language preference toggle, app
environment injection, header, panel button styles, the two folder buttons,
and the bandwidth/verification presentation controls. No transfer engine,
preflight, verification, notification, log-storage, or safety code changed.
