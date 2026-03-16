# Lotus PRD: Day 1 Review-Only Release

## Summary

Lotus is a macOS photo-culling app for users who import a few hundred photos from a camera onto a Mac and need to decide quickly which photos to keep.

The Day 1 release is a review-only product. Lotus helps the user scan a folder, review photos in a fast keyboard-first workflow, see lightweight quality scores with reasons, and complete a keep/reject pass. It does not delete or modify files on disk.

## Problem

Reviewing a few hundred imported photos is repetitive and mentally expensive. Existing tools often force users into slow manual inspection, provide weak support for fast triage, or make scoring and automation feel opaque.

The user needs a tool that:

- helps them move quickly through a large photo set
- surfaces likely weak shots early
- explains why a photo may be a poor candidate
- keeps the final decision with the user
- feels responsive and safe throughout the process

## Goal

Help a photographer complete a confident keep/reject review of a folder of imported photos faster than manual review in Finder or Photos.

## Non-Goals

Day 1 does not aim to:

- delete files
- persist sessions across app restarts
- recurse into subfolders
- support cloud processing
- introduce heavy ML or complex dependencies
- fully solve professional-grade photo ranking

## Target User

The primary Day 1 user is a hobbyist or prosumer photographer who:

- imports a few hundred photos from a camera onto a Mac
- wants a faster culling workflow than Finder or Photos
- prefers local-native tooling
- does not want the app making irreversible choices automatically

## Product Principles

- Keyboard-first: the review flow should ideally be completable by keyboard alone.
- Human-in-control: the score helps triage attention, but never replaces user judgment.
- Explainable: the app should tell the user why a photo appears weak.
- Fast: the workflow should minimize interruption and repetitive effort.
- Safe: the user should always understand that Day 1 does not alter files on disk.
- Low cognitive load: the UI should emphasize only the information needed for quick review.

## Day 1 Scope

Lotus Day 1 will:

- let the user select a local folder
- scan only that folder
- support common still-image formats
- present photos in alphabetical order
- compute a naive but explainable score for each photo
- show separate reasons behind the score
- let the user mark each photo as `keep`, `reject`, or leave it `undecided`
- keep review state in memory only
- provide lightweight filters and a review summary

## User Flow

1. The user opens Lotus.
2. The user selects a folder.
3. Lotus scans that folder and starts loading photos in alphabetical order.
4. Thumbnails and metadata appear incrementally.
5. Scoring runs incrementally in the same order as the photo list.
6. The user starts reviewing immediately, even if scoring is still in progress.
7. Each photo starts as `undecided`.
8. The user marks each photo as `keep` or `reject`.
9. After a keep/reject action, Lotus automatically advances to the next photo.
10. The user can navigate backward at any time and revise decisions.
11. When the user reaches the end, Lotus shows a summary of `keep`, `reject`, and `undecided`.
12. The user can filter and jump back to unresolved photos.

## UI Requirements

### Overall Layout

The Day 1 interface uses a 2-column layout:

- Left column: at least 60% of the width
- Right column: remaining width

### Left Column

The left column is the primary review area and must contain:

- the currently selected photo
- primary metadata
- current score
- score reasons

Metadata shown in Day 1:

- filename
- capture time
- image dimensions
- file size
- focal length
- shutter speed
- aperture
- ISO

If scoring is not ready yet, the selected photo must still be reviewable and the score area should show an `analyzing...` state.

### Right Column

The right column is a scrollable list of photo rows. Each row should contain:

- thumbnail
- filename
- state indicator
- optional score summary

The row treatment should make `keep`, `reject`, and `undecided` easy to scan quickly without relying on loud or visually heavy badges.

## UX Requirements

### Navigation

Day 1 should optimize for fast keyboard-driven review.

The workflow should support:

- next photo
- previous photo
- mark keep
- mark reject
- mark undecided

The entire review flow should remain usable with mouse or trackpad, but keyboard use is the primary interaction model.

### Decision Flow

- Every photo starts as `undecided`.
- Marking `keep` or `reject` auto-advances to the next photo.
- Users can revise decisions at any time.
- Reaching the last photo should not be a dead end. The app should provide a clear summary and a way to jump to unresolved items.

### Filtering

Day 1 should include only a small set of high-value filters:

- all
- undecided
- keep
- reject

Advanced filtering can come later.

## Scoring Requirements

The score is a triage aid, not a final verdict.

The score should represent:

- likelihood that a photo is a weak candidate to keep

The app should display:

- one overall score
- a short list of top reasons

Examples of reasons:

- blur or camera shake
- tilted horizon
- overexposed
- underexposed

Photos without obvious technical issues should show neutral or positive signals, but still require an explicit user decision.

## Performance Requirements

Lotus should feel responsive on folders containing a few hundred photos.

Day 1 expectations:

- thumbnails appear almost immediately after folder selection
- users can begin review before scoring finishes for the entire folder
- scoring proceeds incrementally in alphabetical order
- the UI remains responsive during scanning and scoring
- memory usage is controlled through thumbnails and downsampled images rather than eager full-resolution loading

## Technical Direction

High-level Day 1 technical decisions:

- macOS-only
- native Swift and SwiftUI
- local-only processing
- Apple frameworks by default
- simple and explainable scoring heuristics
- no backend
- no cloud APIs
- no additional languages
- no heavy ML dependencies

Suggested separation of responsibilities:

- folder scanning
- metadata extraction
- thumbnail loading
- score computation
- review state
- filter and summary state

## Constraints

- Review decisions live in memory only for Day 1.
- Unsupported files should be skipped and may be summarized.
- Folder scanning is non-recursive.
- Lotus must not delete files in Day 1.
- If the user switches folders or closes the app mid-review, Lotus should warn before losing in-memory review state.

## Acceptance Criteria

The Day 1 release is successful if:

- a user can select a folder of a few hundred photos and begin review quickly
- the interface remains responsive during scanning and scoring
- the user can complete most or all of the workflow via keyboard
- the current photo, current state, and overall progress are easy to understand
- the score helps guide attention without making the product feel untrustworthy
- the app clearly communicates that no files were modified on disk

## Risks

- Scoring may be too noisy or too weak to be useful.
- Score explanations may be too opaque and reduce trust.
- A detailed UI may overload the user and slow down decision-making.
- Large folders may expose thumbnail-loading or memory issues.
- If in-memory-only behavior is not communicated clearly, users may misunderstand what the app has saved.

## Open Questions

Primary unresolved area:

- exact scoring model and thresholds
- how to present score confidence and reasons without clutter
- how to balance usefulness with trust

Secondary unresolved areas:

- detailed UI behavior within the 2-column review experience
- caching and loading strategy for smooth performance on larger folders

## Next Milestones After Day 1

- define the detailed scoring heuristic before implementation
- refine the 2-column UI and keyboard map
- evaluate whether session persistence should be added
- design a future safe commit/delete workflow after the review-only version proves useful
