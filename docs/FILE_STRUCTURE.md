# **FILE\_STRUCTURE.md**

# **FST — Project File Structure**

Version: 1.0

Status: Locked

Applies To:

* Human Developers  
* Claude  
* Codex  
* Future Contributors

---

# **1\. Objective**

This document defines the official folder structure for FST.

Goals:

* Predictable navigation  
* Easy onboarding  
* Consistent code organization  
* AI-friendly code generation  
* Long-term maintainability

Every source file must belong to a clearly defined architectural layer.

---

# **2\. Root Project Structure**

FST/

├── App/  
├── Views/  
├── ViewModels/  
├── Coordinators/  
├── Engines/  
├── Services/  
├── Models/  
├── Utilities/  
├── Resources/  
├── Extensions/  
├── Tests/  
└── Documentation/

No additional top-level folders should be created without approval.

---

# **3\. App Folder**

Purpose:

Application entry point.

Contents:

App/

└── FSTApp.swift

Responsibilities:

* App lifecycle  
* Window configuration  
* Dependency creation

Must NOT contain:

* Business logic  
* rsync logic  
* Verification logic

---

# **4\. Views Folder**

Purpose:

SwiftUI presentation layer.

Structure:

Views/

├── Main/  
│  
├── Components/  
│  
├── Source/  
│  
├── Destination/  
│  
├── Status/  
│  
├── Logs/  
│  
└── Settings/

---

# **5\. Main Views**

Views/Main/

├── ContentView.swift  
└── MainWindowView.swift

Purpose:

Compose screen layout.

Only responsible for:

* Layout  
* Navigation  
* View composition

---

# **6\. Reusable Components**

Views/Components/

├── FSTButton.swift  
├── FSTCard.swift  
├── ProgressBarView.swift  
├── StatusBadge.swift  
└── SectionHeader.swift

Purpose:

Reusable UI elements.

Must contain:

* No business logic  
* No filesystem access

---

# **7\. Source Views**

Views/Source/

├── SourceCardView.swift  
└── SourceDropZoneView.swift

Responsibilities:

* Display source folder  
* Handle drag and drop

---

# **8\. Destination Views**

Views/Destination/

├── DestinationCardView.swift  
└── DestinationDropZoneView.swift

Responsibilities:

* Display destination folder  
* Handle drag and drop

---

# **9\. Status Views**

Views/Status/

├── TransferStatusView.swift  
├── ProgressView.swift  
└── SafeToFormatView.swift

Responsibilities:

* Display transfer state  
* Display progress  
* Display final result

---

# **10\. Log Views**

Views/Logs/

├── LogsView.swift  
└── LogRowView.swift

Responsibilities:

* Render log output  
* Auto-scroll behavior

---

# **11\. ViewModels Folder**

Purpose:

Expose state to SwiftUI.

Structure:

ViewModels/

└── TransferViewModel.swift

Future:

ViewModels/

├── TransferViewModel.swift  
├── LogsViewModel.swift  
└── SettingsViewModel.swift

Rule:

One ViewModel per feature area.

---

# **12\. Coordinators Folder**

Purpose:

Workflow orchestration.

Structure:

Coordinators/

└── TransferCoordinator.swift

Responsibilities:

* Validation  
* State transitions  
* Workflow execution

This is the application's brain.

---

# **13\. Engines Folder**

Purpose:

Core business logic.

Structure:

Engines/

├── RsyncEngine.swift  
├── VerifyEngine.swift  
└── ReportEngine.swift

---

# **14\. Rsync Engine**

Engines/

└── RsyncEngine.swift

Responsibilities:

* Build rsync commands  
* Launch process  
* Parse output  
* Track progress

No UI dependencies.

---

# **15\. Verify Engine**

Engines/

└── VerifyEngine.swift

Responsibilities:

* File scanning  
* Sampling  
* xxHash verification

No rsync dependencies.

---

# **16\. Report Engine**

Engines/

└── ReportEngine.swift

Responsibilities:

* Generate TXT reports  
* Build report models

---

# **17\. Services Folder**

Purpose:

System integration layer.

Structure:

Services/

├── DriveService.swift  
├── ShellService.swift  
├── LoggerService.swift  
├── BookmarkService.swift  
└── NotificationService.swift

---

# **18\. Drive Service**

Responsibilities:

* Disk space calculation  
* File validation  
* Folder size calculation

---

# **19\. Shell Service**

Responsibilities:

* Process creation  
* Pipe management  
* Output streaming

Used only by:

* RsyncEngine

---

# **20\. Logger Service**

Responsibilities:

* Log storage  
* Log formatting  
* TXT export

---

# **21\. Bookmark Service**

Responsibilities:

* Security Scoped Bookmarks  
* Save access  
* Restore access

---

# **22\. Notification Service**

Responsibilities:

* User notifications  
* Transfer completion alerts  
* Verification failure alerts

---

# **23\. Models Folder**

Purpose:

Application data models.

Structure:

Models/

├── TransferRequest.swift  
├── TransferResult.swift  
├── VerificationRequest.swift  
├── VerificationResult.swift  
├── TransferState.swift  
├── VerificationMode.swift  
├── LogEntry.swift  
└── TransferReport.swift

Models must remain lightweight.

No business logic.

---

# **24\. Transfer Models**

TransferRequest.swift

Contains:

* sourceURL  
* destinationURL  
* bandwidthLimit

---

TransferResult.swift

Contains:

* status  
* duration  
* speed  
* transferredBytes

---

# **25\. Verification Models**

VerificationRequest.swift  
VerificationResult.swift

Contains:

* mode  
* sampledFiles  
* passedFiles  
* failedFiles

---

# **26\. Utilities Folder**

Purpose:

Shared helpers.

Structure:

Utilities/

├── Constants.swift  
├── Formatters.swift  
├── FileSizeFormatter.swift  
├── DurationFormatter.swift  
└── DateFormatterProvider.swift

Rules:

No business logic.

No application state.

---

# **27\. Extensions Folder**

Purpose:

Safe extensions only.

Structure:

Extensions/

├── URL+Extensions.swift  
├── String+Extensions.swift  
├── Process+Extensions.swift  
└── FileManager+Extensions.swift

Rules:

Extensions must remain small.

Never hide complex logic inside extensions.

---

# **28\. Resources Folder**

Purpose:

Static resources.

Structure:

Resources/

├── Assets.xcassets  
├── Localizable.strings  
└── SampleReports/

---

# **29\. Tests Folder**

Structure:

Tests/

├── UnitTests/  
│  
├── IntegrationTests/  
│  
└── TestData/

---

# **30\. Unit Tests**

Tests/UnitTests/

├── RsyncParserTests.swift  
├── VerifyEngineTests.swift  
├── TransferCoordinatorTests.swift  
└── LoggerServiceTests.swift

Coverage Target:

70%+

---

# **31\. Integration Tests**

Tests/IntegrationTests/

├── TransferWorkflowTests.swift  
├── VerificationWorkflowTests.swift  
└── ReportGenerationTests.swift

Purpose:

Validate complete workflows.

---

# **32\. Documentation Folder**

Structure:

Documentation/

├── PRD.md  
├── ARCHITECTURE.md  
├── CODING\_STANDARDS.md  
├── FILE\_STRUCTURE.md  
├── UI\_GUIDELINES.md  
├── STATE\_MACHINE.md  
├── RSYNC\_ENGINE\_SPEC.md  
└── TEST\_PLAN.md

Documentation lives inside the repository.

Documentation is version controlled.

---

# **33\. File Naming Rules**

Good:

TransferCoordinator.swift

VerifyEngine.swift

SourceCardView.swift

Bad:

Manager.swift

Helper.swift

Utils.swift

NewFile.swift

Names must describe responsibility.

---

# **34\. Folder Ownership Rules**

Views

May depend on:

* ViewModels

Only.

---

ViewModels

May depend on:

* Coordinators  
* Models

Only.

---

Coordinators

May depend on:

* Engines  
* Services  
* Models

Only.

---

Engines

May depend on:

* Services  
* Models

Only.

---

Services

May depend on:

* Foundation  
* System APIs

Only.

---

# **35\. Final Rule**

When adding a new file:

Ask:

"Which architectural layer owns this responsibility?"

If the answer is unclear:

The design is unclear.

Clarify the architecture before writing code.

