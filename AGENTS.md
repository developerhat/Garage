# Garage — Project Guide

## Product Overview

Garage is a native iOS app for tracking vehicles and everything related to ownership.

The goal is to create a polished, useful personal vehicle-management app that can eventually be released on the App Store.

Garage should make it easy to track:

* Vehicles
* Mileage
* Maintenance history
* Modifications
* Expenses
* Photos
* Service reminders
* Notes
* Ownership history

The product should feel simple, modern, and enthusiast-friendly rather than like fleet-management software.

## Current Stage

This project is at the very beginning.

The initial goal is to build a clean MVP while also using the project to develop strong production-level iOS engineering skills.

Avoid overengineering early versions.

## Primary Technology

Use native Apple technologies wherever practical.

Preferred stack:

* Swift
* SwiftUI
* SwiftData
* Swift Concurrency with async/await
* Swift Testing
* Apple-native frameworks before third-party dependencies

Avoid adding external packages unless there is a clear benefit.

## Initial MVP

Version 0.1 should focus on the core Garage experience.

Users should be able to:

1. View a list of their vehicles.
2. Add a vehicle.
3. Open a vehicle detail page.
4. Edit basic vehicle information.
5. Delete a vehicle.
6. Persist vehicle data locally.

Initial vehicle fields:

* Make
* Model
* Year
* Trim
* Nickname
* Current mileage
* VIN
* License plate
* Notes

Do not build authentication, cloud sync, AI features, social features, or a backend until the local MVP works well.

## Future Product Direction

Possible later features include:

* Vehicle photos
* Maintenance records
* Modification tracking
* Fuel expenses
* Insurance and registration records
* Total cost of ownership
* Service reminders
* Mileage history
* Receipt uploads
* Charts and ownership analytics
* VIN decoding
* Cloud sync
* Shared garages
* AI-assisted receipt parsing
* Maintenance recommendations

Treat these as future ideas, not current requirements.

## Engineering Priorities

Prioritize:

1. Correctness
2. Readability
3. Simple architecture
4. Native iOS conventions
5. Maintainability
6. Testability
7. Good user experience

Prefer straightforward code over clever abstractions.

Do not introduce architectural layers until the application actually needs them.

## Code Style

Use idiomatic modern Swift.

Prefer:

* Small focused views
* Clear naming
* Strong types
* Value types where appropriate
* async/await over callback-heavy APIs
* Dependency injection where it meaningfully improves testability
* Reusable components only when duplication actually exists

Avoid:

* Massive views
* Massive view models
* Singleton-heavy architecture
* Premature protocols
* Unnecessary generic abstractions
* Large third-party frameworks for simple functionality

## SwiftUI Guidelines

Keep UI declarative and easy to understand.

Prefer built-in SwiftUI components and navigation APIs.

Views should generally focus on presentation and user interaction rather than owning complicated business logic.

Extract subviews when doing so improves readability, not simply to make files smaller.

## Data Model

Start with a simple `Vehicle` model.

The data model should remain flexible enough to later support related entities such as:

* MaintenanceRecord
* Modification
* Expense
* MileageEntry
* VehiclePhoto
* Reminder

Do not build those models until they are needed.

## UX Direction

Garage should feel:

* Clean
* Premium
* Minimal
* Automotive-focused
* Fast
* Easy to understand

Favor a visually strong vehicle-first experience.

The vehicle itself should feel like the central object in the app.

Avoid cluttered forms and enterprise-style UI.

## Development Workflow

Before making substantial changes:

1. Inspect the existing project.
2. Understand the current implementation.
3. Make the smallest reasonable change.
4. Build the project.
5. Fix compiler errors.
6. Run relevant tests.
7. Explain meaningful architectural changes.

Do not make unrelated refactors while implementing a feature.

## Git

Keep commits focused and understandable.

Good examples:

* `Add Vehicle model`
* `Build garage vehicle list`
* `Add vehicle creation flow`
* `Persist vehicles with SwiftData`

Avoid giant commits that combine unrelated changes.

Never commit:

* Secrets
* API keys
* Credentials
* Build artifacts
* DerivedData
* User-specific Xcode state

## Working With Codex

When implementing a requested feature:

* Inspect relevant files before editing.
* Preserve working behavior unless the requested feature requires changing it.
* Prefer incremental changes.
* Build after meaningful edits.
* Report compiler or test failures clearly.
* Do not silently change product scope.
* Do not add dependencies without explaining why.
* Do not replace native Apple frameworks with third-party libraries without a strong reason.

When multiple implementations are reasonable, favor the simplest native approach.

## Learning Goal

This project is also intended to help the developer become stronger at iOS and product engineering.

When introducing an important Swift or iOS concept, keep the implementation production-quality but make the code understandable.

Important concepts worth reinforcing through the project include:

* Swift types
* Optionals
* Protocols
* Value vs reference semantics
* SwiftUI state management
* Navigation
* SwiftData
* Concurrency
* Networking
* Architecture
* Testing
* Error handling
* App lifecycle
* Performance
* Accessibility

The goal is not merely to generate working code. The goal is to build a good product while developing genuine engineering understanding.
