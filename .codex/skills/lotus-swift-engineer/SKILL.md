---
name: lotus-swift-engineer
description: Swift engineer workflow for the Lotus macOS app. Use when implementing or reviewing Swift, SwiftUI, image scanning, local photo scoring, batch-performance work, file deletion safety, and test structure in this repo.
---

# Lotus Swift Engineer

Use this skill for code changes in `lotus`. It translates the repo's product constraints into implementation defaults.

## Core Defaults

- Build for `macOS` only unless the user asks otherwise.
- Prefer native Apple frameworks and standard Swift tooling.
- Keep everything local-first. Do not add cloud, backend, or remote analysis.
- Keep dependencies minimal. If a non-trivial dependency would help, discuss it before adding it.
- Optimize for folders with a few hundred photos, not for a single-image demo path.

## Product Translation

When making technical choices, optimize for:
- Fast time-to-review after folder selection.
- Explainable scoring with named reasons, not just a single opaque number.
- User trust around keep/reject decisions and final deletion.
- Responsive UI while scanning and scoring run in the background.

Reject or challenge approaches that:
- Load full-resolution images eagerly for the whole folder.
- Couple scanning, scoring, and UI state tightly together.
- Delete files before an explicit commit flow.
- Trade product simplicity for speculative architecture.

## Architecture Guidance

Prefer separating these concerns:
- Folder scanning and file discovery.
- Image metadata loading and thumbnail preparation.
- Photo scoring and score-reason generation.
- Review state such as keep, reject, undecided, and commit readiness.
- File operation execution for the final commit step.

Prefer lightweight services or plain Swift types with explicit boundaries over large view models or premature abstraction.

## SwiftUI Guidance

- Keep views focused on presentation and interaction orchestration.
- Prefer small dedicated subviews when screens grow.
- Keep expensive work out of `body`.
- Preserve responsiveness while large batches are being scanned or scored.
- Be careful with image grids: stable identity, bounded thumbnail sizes, and incremental loading matter.

If a task is specifically about SwiftUI cleanup or performance, also consider the local skills:
- `swiftui-view-refactor`
- `swiftui-performance-audit`

## Image and Performance Guidance

- Prefer metadata inspection, thumbnails, and downsampled images over full decode whenever possible.
- Avoid retaining many large image objects at once.
- Design scoring so it can run incrementally and report partial progress.
- Make cancellation and restart behavior reasonable when the user picks a new folder.
- Treat loading, caching, and batch throughput as first-class concerns, not polish work.

## Scoring Guidance

- Prefer deterministic and explainable heuristics for Day 1.
- Return separate reasons where possible, such as blur, exposure issues, or horizon tilt.
- Keep scoring outputs inspectable in tests.
- If scoring quality depends on subjective product decisions or thresholds, surface that uncertainty instead of hard-coding arbitrary behavior silently.

## File Safety Guidance

- Deletion or destructive file operations must remain behind explicit user confirmation.
- Keep review decisions separate from commit execution.
- Favor implementations that make it easy to add a safer delete strategy later if needed.

## Testing Guidance

- Prefer `Testing` for new tests unless the repo direction changes.
- Add focused tests for deterministic logic such as file filtering, score calculation, thresholding, and decision-state transitions.
- For performance-sensitive code, prefer designs that can be benchmarked or exercised with fixtures without needing the full UI.

## When To Pause And Clarify

Pause and ask before proceeding if the change would introduce:
- A new dependency or framework outside standard Apple APIs.
- ML or Vision as a core scoring dependency.
- A new persistence layer or major architectural pattern.
- A changed deletion safety model.
- A significant UI workflow shift.
