# Figure Drawing App: Phased Plan

Date: 2026-02-06
Owner: Jess
Project: Local macOS desktop app for timed gesture drawing sessions (SwiftUI)

## Purpose
Deliver a local macOS desktop app that loads a folder of gesture photos, lets the user curate the set, and runs timed drawing sessions with simple controls and accurate tracking.

## Execution Plan (Current)
Step 1: Make the app runnable (SwiftUI)
- Create a SwiftUI app scaffold that builds and launches.
- Add placeholder Setup/Session/Summary screens.

Step 2: Port the approved mockup into SwiftUI
- Match layout, spacing, and black/white styling.
- Keep the same flow and controls.

Step 3: Wire real data + persistence
- Folder picker and recursive image scan.
- Metadata persistence for omit/draw counts.
- Session engine uses real images.

Step 4: Polish pass (current)
- Add keyboard shortcuts in session view.
- Add fullscreen toggle shortcut.
- Confirm buttons/controls remain minimal and distraction-free.

## How We Will Coordinate “Sub-Agents”
These are simulated roles to keep context clear and parallelize thinking. All work will be executed sequentially here, but scoped by role boundaries.

1. UI Agent
- Owns layout, interaction flows, and visual hierarchy.
- Inputs: requirements, data models.
- Outputs: component structure, styles, state interactions.

2. Session Engine Agent
- Owns timing, session progression, skip/back logic.
- Inputs: session settings, curated image list.
- Outputs: deterministic session state transitions and controls.

3. Data & Persistence Agent
- Owns metadata storage and image indexing.
- Inputs: folder selection, image list, omit flags, draw counts.
- Outputs: data model, persistence file format, update rules.

4. Platform Agent
- Owns Electron main process, filesystem access, IPC.
- Inputs: app requirements, file access needs.
- Outputs: main process scaffolding, IPC handlers, safe file access.

## Phase 0: Project Definition
Goal: Lock scope and assumptions to reduce churn.

Deliverables:
- Feature list and non-goals
- Data ownership decisions
- Tech stack selection

Inputs:
- User requirements and preferences

Outputs:
- Confirmed scope
- Implementation constraints

Risks:
- Over-scoping before a working baseline

Checklist:
- Confirm macOS desktop target
- Confirm image formats and folder handling
- Confirm local persistence strategy

## Phase 1: Project Scaffold
Goal: Create a running SwiftUI app shell.

Deliverables:
- Buildable SwiftUI app
- Basic screen navigation

Inputs:
- Tech stack decision

Outputs:
- Base project structure
- App launches in Xcode or via SwiftPM

Risks:
- Tooling friction

Checklist:
- App builds with SwiftPM/Xcode
- Window launches with placeholder screens
- Navigation between Setup/Session/Summary works

## Phase 2: Data Indexing & Persistence
Goal: Load images from folder, store metadata, and maintain omit/draw counts.

Deliverables:
- Folder selection
- Image discovery and list
- Persisted metadata

Inputs:
- Folder path
- Supported file extensions

Outputs:
- Indexed images list
- JSON persistence in app userData

Risks:
- File access permissions
- Large folders impacting performance

Checklist:
- Can read folder and subfolders
- Can omit images and persist
- Can increment draw counts

## Phase 3: Session Engine
Goal: Implement timing and progression logic for sessions.

Deliverables:
- Session start/stop/pause
- Next/previous/skip
- Image count targets including infinite mode

Inputs:
- Session settings
- Curated image list

Outputs:
- Deterministic session state machine
- UI control bindings

Risks:
- Timer drift
- Skip/back edge cases

Checklist:
- Timer accurate
- Skip does not count toward total
- Back uses history

## Phase 4: UI/UX for Setup
Goal: Build the setup screen for folder selection, image curation, and settings.

Deliverables:
- Folder picker
- Image grid with omit toggles and draw counters
- Settings panel

Inputs:
- Image list and metadata
- Session settings schema

Outputs:
- Usable setup screen

Risks:
- Large image grids are slow without lazy loading

Checklist:
- Image grid scrollable
- Omit toggles work
- Settings are validated

## Phase 5: Session View
Goal: Fullscreen-friendly session view focused on the image.

Deliverables:
- Large image display (no cropping)
- Timer overlay
- Minimal controls

Inputs:
- Active image
- Session state

Outputs:
- Session screen

Risks:
- Layout issues across display sizes

Checklist:
- Image letterboxed correctly
- Timer visible but subtle
- Controls responsive

## Phase 6: Polish & Packaging
Goal: Improve usability and prepare for distribution.

Deliverables:
- Keyboard shortcuts
- Performance tuning
- App icon and basic packaging

Inputs:
- Working app

Outputs:
- Ready-to-run local app

Risks:
- Packaging complexity

Checklist:
- Shortcuts documented
- App stable over long sessions
- Packaging plan defined

## Phase Execution Notes
- Each phase will close with a brief summary of changes and next steps.
- If scope shifts, we update this document first to keep context stable.
