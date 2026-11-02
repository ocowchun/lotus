# Silent Review Shortcuts Implementation Plan

**Goal:** Prevent the macOS alert sound after handled review shortcuts, especially S and D.

**Approved design:** Preserve a keyboard handler's `nil` result so AppKit consumes the event. Return the original event only when no handler exists. Keep shortcut assignments and review actions unchanged; add no sound preference.

**Architecture:** Update the existing local event monitor in `lotus/App/Shortcuts.swift`. Unwrap the handler before invoking it rather than coalescing its optional return value.

**Tech stack:** Swift, AppKit, SwiftUI, Xcode.

- [x] Replace `self?.handler?(event) ?? event` with `guard let handler = self?.handler else { return event }` followed by `return handler(event)`.
- [x] Exercise the actual monitor closure with consumed, forwarded, missing-handler, and released-owner cases using a temporary Swift harness. All four cases passed.
- [x] Run the existing unit tests with `xcodebuild -scheme lotus -destination 'platform=macOS' -derivedDataPath /tmp/lotus-silent-shortcuts -only-testing:lotusTests test`. Build and all nine tests passed.
- [x] Update `docs/PROGRESS.md` and review the final diff. Audible confirmation remains a manual check in the running app.
