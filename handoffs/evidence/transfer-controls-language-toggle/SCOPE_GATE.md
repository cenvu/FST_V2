# Scope gate — transfer controls and language toggle

AUTHORIZED_PRODUCTION_PATHS=FishSockTransferApp.swift;AppLanguage.swift;ContentView.swift;PanelStyle.swift;SourceCardView.swift;DestinationCardView.swift;TransferControlsView.swift;LocalizationPresentationXCTests.swift
PRODUCTION_TRANSLATION_CATALOG_CHANGED=NO
TRANSFER_OR_VERIFICATION_SEMANTICS_CHANGED=NO
NOTIFICATION_DELIVERY_CHANGED=NO
LOG_STORAGE_OR_CLASSIFICATION_CHANGED=NO
UPDATER_NETWORK_CHANGED=NO
CAPACITY_OR_SAFE_TO_EJECT_CHANGED=NO

The catalog was not needed for new UI copy: the flag reuses the existing
`Application Language` accessibility/tooltip key, and dropdown option labels
use existing bounded Transfer localization. Button styles are local to the
requested controls.

CodeGraph was not available in this session. The OpenDesign MCP tool was
present but returned `Transport closed`; checked-in owner source/screenshots
were used for the comparison. Direct source and test inspection was completed.

PREEXISTING_DIRTY_PATH=FishSockTransfer/FishSockTransfer/Localizable.xcstrings
PREEXISTING_DIRTY_PATH_TOUCHED_BY_TASK=NO
PREEXISTING_DIRTY_PATH_MUST_REMAIN_UNCOMMITTED=YES
PASS_CLEAN_WORKTREE_GATE=NOT_POSSIBLE_WITHOUT_OWNER_CHANGE
