# **UI\_GUIDELINES.md**

# **FST — User Interface Guidelines**

Version: 1.0

Status: Locked

---

# **1\. Design Philosophy**

FST is not a media management application.

FST is a transfer verification tool.

The interface should feel:

* Calm  
* Focused  
* Trustworthy  
* Predictable

The user should never feel overwhelmed.

If a screen requires explanation:

The screen is too complicated.

---

# **2\. Design Inspiration**

Primary Inspiration:

* Hedge  
* OffShoot

Secondary Inspiration:

* YoYotta

Do NOT imitate:

* Adobe Premiere  
* DaVinci Resolve  
* Finder  
* Asset Management Systems

FST is not a creative tool.

FST is an operational tool.

---

# **3\. User Attention Hierarchy**

At any moment, the user should immediately understand:

1. What is being copied  
2. Where it is being copied  
3. Current status  
4. Whether media is safe

Everything else is secondary.

---

# **4\. Single Screen Principle**

The entire workflow should fit inside one primary window.

No modal workflows.

No wizard workflows.

No multi-step setup screens.

The user should never navigate between pages to complete a transfer.

---

# **5\. Main Window Layout**

┌─────────────────────────────────────┐  
│                                     │  
│  SOURCE                             │  
│                                     │  
├─────────────────────────────────────┤  
│                                     │  
│  DESTINATION                        │  
│                                     │  
├─────────────────────────────────────┤  
│                                     │  
│  BANDWIDTH                          │  
│  VERIFY MODE                        │  
│                                     │  
├─────────────────────────────────────┤  
│                                     │  
│  STATUS                             │  
│                                     │  
├─────────────────────────────────────┤  
│                                     │  
│  REAL-TIME LOGS                     │  
│                                     │  
├─────────────────────────────────────┤  
│ START  STOP  EXPORT REPORT          │  
└─────────────────────────────────────┘

No sidebar.

No inspector panel.

No floating windows.

---

# **6\. Window Requirements**

Default Size:

1200 × 800

Minimum Size:

1000 × 700

Resizable:

Yes

Fullscreen:

Supported

---

# **7\. Visual Style**

Style:

Professional Utility

Not:

Consumer App

Not:

Creative Software

Not:

Gaming Interface

Visual language should resemble professional production tools.

---

# **8\. Color Philosophy**

Most UI should remain neutral.

Gray

Black

White

Use color only for status communication.

---

# **9\. Status Colors**

READY

Gray

COPYING

Blue

VERIFYING

Orange

SAFE TO FORMAT

Green

ERROR

Red

CANCELLED

Yellow

Status colors must remain consistent throughout the application.

---

# **10\. Source Card**

Purpose:

Display source folder.

Contents:

* Folder Name  
* Full Path  
* Folder Size  
* File Count

Actions:

* Drag & Drop  
* Browse

Visual State:

Empty:

Dashed Border

Selected:

Solid Border

---

# **11\. Destination Card**

Purpose:

Display destination folder.

Contents:

* Folder Name  
* Full Path  
* Free Space  
* Remaining Space After Copy

Actions:

* Drag & Drop  
* Browse

Visual State:

Empty:

Dashed Border

Selected:

Solid Border

---

# **12\. Bandwidth Section**

Purpose:

Control transfer speed.

Display:

Slider

Preset Buttons:

50 MB/s

120 MB/s

240 MB/s

Unlimited

Current Selection:

Clearly visible.

Avoid hidden settings.

---

# **13\. Verification Section**

Display:

Segmented Control

Options:

None

33%

100%

Default:

33%

Selection must always be visible.

No dropdown menus.

---

# **14\. Status Panel**

This is the most important section during transfer.

Must display:

Current State

Progress

Current Speed

Average Speed

ETA

Current File

Example:

COPYING

Progress: 48%

Current Speed: 118 MB/s

Average Speed: 112 MB/s

ETA: 12m 32s

Current File:  
A001\_C004\_0614AB.mov

---

# **15\. Progress Bar**

Single Progress Bar.

No nested progress bars.

No animated gimmicks.

Requirements:

* Smooth updates  
* Percentage visible  
* High contrast

---

# **16\. SAFE TO FORMAT Screen**

This is the highest value screen.

Visual Priority:

Maximum

Layout:

SAFE TO FORMAT

Copy Completed

Verification Passed

Errors: 0

Transfer Time: 00:42:11

Must be instantly recognizable.

---

# **17\. Error Screen**

Must explain:

What happened

Why it happened

What the operator should do

Bad:

Exit Code 23

Good:

Destination drive disconnected.

Reconnect the drive and restart the transfer.

---

# **18\. Log Viewer**

Purpose:

Operational transparency.

Features:

* Auto Scroll  
* Pause Scroll  
* Copy Selected Text  
* Export TXT

Font:

Monospaced

Recommended:

SF Mono

---

# **19\. Buttons**

Primary Action:

START

Secondary Actions:

STOP

EXPORT REPORT

Only one primary action button per screen.

---

# **20\. Start Button Rules**

Enabled only when:

* Source exists  
* Destination exists  
* Validation passes

Disabled otherwise.

Never allow invalid transfers to start.

---

# **21\. Stop Button Rules**

Visible only while:

* Copying  
* Verifying

Must require confirmation.

Example:

Cancel Transfer?

Yes

No

---

# **22\. Typography**

Primary Font:

SF Pro

Log Font:

SF Mono

Avoid custom fonts.

---

# **23\. Animations**

Minimal.

Purpose:

Communicate state changes.

Avoid:

* Bouncing  
* Floating  
* Decorative effects

The application is a tool.

Not entertainment software.

---

# **24\. Notifications**

Display notification when:

Transfer Completed

Verification Failed

Transfer Cancelled

Notification content must be concise.

---

# **25\. Accessibility**

Support:

* Dark Mode  
* Light Mode  
* Dynamic Text  
* Keyboard Navigation

Required contrast ratio:

WCAG compliant

---

# **26\. User Experience Rule**

A DIT should understand the current state of the transfer from 3 meters away.

If the operator must walk closer to inspect details:

The interface is not communicating effectively.

---

# **27\. Final Design Principle**

At every stage the application must answer one question:

"Can I safely erase the source media?"

The entire UI exists to communicate that answer.

