# **FishSock Transfer (FST)**

# **V1 Worklog & V1.1 Development Roadmap**

Version: 1.0 Review Document

Date: June 2026

Author: Cen \+ AI Development Workflow

---

# **1\. PROJECT OVERVIEW**

FishSock Transfer (FST) là ứng dụng native macOS được xây dựng nhằm hỗ trợ DIT, Data Wrangler, Assistant Editor và Production Crew thực hiện việc sao chép dữ liệu an toàn thông qua rsync.

Mục tiêu của dự án:

* Thay thế workflow Terminal thủ công  
* Tăng tính trực quan khi offload dữ liệu  
* Cung cấp realtime logs  
* Kiểm soát tốc độ copy  
* Hỗ trợ workflow DIT hiện trường

---

# **2\. TECHNOLOGY STACK**

Target OS:

* macOS 13 Ventura+

Language:

* Swift 6

UI:

* SwiftUI

Architecture:

* MVVM

Transfer Engine:

* Foundation Process()  
* /usr/bin/rsync

Build:

* Universal Binary  
* Intel \+ Apple Silicon

Development Tools:

* Google AI Studio  
* Claude Opus  
* Codex  
* VSCode  
* Xcode 16

---

# **3\. DEVELOPMENT WORKFLOW ESTABLISHED**

Product Design

↓

Google AI Studio

↓

Architecture Design

↓

React Prototype

↓

SwiftUI Migration Design

↓

Codex Code Generation

↓

Xcode Build

↓

Claude Review

↓

Git Commit

---

# **4\. DOCUMENTATION CREATED**

Completed Documents:

* PRD.md  
* ARCHITECTURE.md  
* FILE\_INVENTORY.md  
* SWIFT\_MIGRATION.md  
* UI Guidelines  
* Folder Structure Specification  
* State Machine Specification  
* RSYNC Engine Specification  
* Verification Engine Specification  
* Codex Code Guide

---

# **5\. ARCHITECTURE DECISIONS**

Chosen Architecture:

MVVM

Core Layers:

* Models  
* Services  
* Engines  
* ViewModels  
* Views  
* Components

Primary Services:

* DriveService  
* ShellService

Primary Engine:

* RsyncEngine

Primary ViewModel:

* TransferViewModel

---

# **6\. USER INTERFACE DECISIONS**

Visual Direction:

* Professional DIT Utility  
* Dark Theme  
* Offload Dashboard Style  
* Apple Human Interface Guidelines

Core Sections:

1. Header  
2. Source Card  
3. Destination Card  
4. APFS Analysis Card  
5. Bandwidth Control  
6. Start Transfer Button  
7. Realtime Terminal Logs

---

# **7\. GOOGLE AI STUDIO PROTOTYPE**

Completed:

* React Prototype  
* TypeScript Architecture  
* Component Tree  
* Data Flow  
* UI Validation

Result:

Prototype successfully rendered and tested inside Google AI Studio.

Status:

COMPLETED

---

# **8\. SWIFTUI MIGRATION**

Migration Strategy Defined:

React Component

↓

SwiftUI View

TypeScript State

↓

ObservableObject

React State Hooks

↓

@Published

Result:

Migration Blueprint completed.

Status:

COMPLETED

---

# **9\. XCODE PROJECT**

Project Name:

FishSock Transfer

Target:

macOS 13+

Language:

Swift 6

Build Status:

BUILD SUCCEEDED

Output:

FST.app

Status:

COMPLETED

---

# **10\. V1 CURRENT STATUS**

Completed:

✓ Architecture Design

✓ SwiftUI Migration Plan

✓ Buildable macOS Project

✓ Initial Dashboard UI

✓ FST.app Launches

✓ UI Layout Working

✓ Theme Working

✓ Core Structure Working

Not Yet Implemented:

✗ App Icon

✗ Source File Picker

✗ Destination File Picker

✗ Drag & Drop

✗ Real Drive Detection

✗ APFS Storage Analysis

✗ Realtime Mounted Volume Monitoring

✗ Rsync Engine Integration

✗ Progress Parser

✗ Cancel Transfer

✗ Transfer Verification

---

# **11\. LESSONS LEARNED DURING V1**

Key Discovery:

Google AI Studio is excellent for:

* Product Design  
* Architecture  
* UI Design  
* Rapid Prototyping

However:

Google AI Studio prototype ≠ Native macOS Application

Migration layer is required.

Workflow established:

AI Studio  
↓  
Architecture  
↓  
Codex  
↓  
SwiftUI  
↓  
Xcode

This workflow is now validated.

---

# **12\. V1.1 DEVELOPMENT GOALS**

Priority Order:

1. App Icon  
2. Source File Picker  
3. Destination File Picker  
4. Drag & Drop  
5. Real Drive Detection  
6. Mounted Volume Monitoring  
7. APFS Analysis  
8. Storage Validation  
9. Realtime Logs  
10. Rsync Integration  
11. Progress Tracking  
12. Transfer Cancel

---

# **13\. V1.1 FEATURE SPECIFICATION**

## **Feature 01**

App Icon

Goal:

Replace default Xcode icon.

Status:

Planned

---

## **Feature 02**

Source Picker

Requirements:

* Folder Selection  
* Mounted Drive Selection  
* NSOpenPanel

Status:

Planned

---

## **Feature 03**

Destination Picker

Requirements:

* Folder Selection  
* Mounted Drive Selection

Status:

Planned

---

## **Feature 04**

Drag & Drop

Requirements:

Accept:

* Volumes  
* Folders

Drop Targets:

* Source Card  
* Destination Card

Status:

Planned

---

## **Feature 05**

Drive Detection

Requirements:

Use:

FileManager.default.mountedVolumeURLs

Display:

* Name  
* Capacity  
* Free Space  
* Filesystem

Status:

Planned

---

## **Feature 06**

APFS Analysis

Requirements:

Compare:

Source Size

vs

Destination Free Space

Output:

* Safe  
* Warning  
* Error

Status:

Planned

---

## **Feature 07**

Rsync Engine

Requirements:

Launch:

/usr/bin/rsync

Using:

Process()

Pipe()

Realtime Parsing

Status:

Planned

---

## **Feature 08**

Progress Tracking

Display:

* Percentage  
* Speed  
* ETA  
* Current File

Status:

Planned

---

## **Feature 09**

Transfer Cancellation

Requirements:

process.terminate()

Status:

Planned

---

# **14\. V1.1 SUCCESS CRITERIA**

FishSock Transfer V1.1 is considered successful when:

✓ App Icon exists

✓ Source Picker works

✓ Destination Picker works

✓ Drag & Drop works

✓ Real Drives detected

✓ APFS Analysis updates

✓ Mounted Volumes refresh automatically

✓ Start Transfer launches rsync

✓ Logs display in realtime

✓ Build succeeds without warnings

---

# **15\. LONG TERM ROADMAP**

V1.2

* Checksum Engine  
* xxHash Verification

V1.3

* Transfer Reports  
* History Database

V1.4

* Queue Engine  
* Multi Destination Copy

V2.0

* Professional DIT Verification Suite  
* Media Validation  
* Presets  
* Workflow Templates

---

# **PROJECT STATUS**

FishSock Transfer V1

Architecture Complete

Prototype Complete

Migration Complete

Initial Native Build Complete

Current Phase:

BEGINNING V1.1 IMPLEMENTATION

