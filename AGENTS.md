# AGENTS.md

## Project Overview
- `lotus` is a macOS photo selection app for users who import a few hundred photos from a camera to a laptop and need to quickly decide which photos to keep.
- The app scans a user-selected folder, finds supported photos in that folder, computes quality scores and reasons, shows the photos in a review UI, lets the user decide keep vs reject, and only removes unwanted photos after an explicit commit step.
- Day 1 scope is local-only, macOS-only, and focused on common photo formats. Do not assume cloud services, backend components, or multi-platform support.

## Product Goals
- Help users make fast keep/reject decisions across hundreds of photos.
- Surface actionable scoring reasons such as horizon tilt, blur or camera shake, overexposure, underexposure, and similar quality problems.
- Preserve user trust with a safe review flow before any deletion happens.
- Keep the implementation simple, native, and testable.

## Day 1 Scope
- Allow the user to select a single folder.
- Scan only that folder. Do not recurse into subfolders unless the user explicitly asks for it later.
- Support common image formats only in the initial version.
- Compute photo quality scores locally on the Mac.
- Show photos in a review experience where the user can decide keep or reject for each photo.
- Require a final explicit commit step before removing rejected photos.

## Non-Goals By Default
- No backend service.
- No cloud API or remote processing.
- No additional programming languages.
- No complex third-party dependencies, including heavy ML stacks, unless discussed and explicitly approved first.
- No automatic deletion during scan or review. Deletion must stay behind an explicit final confirmation flow.

## Technical Preferences
- Prefer native Apple frameworks and standard Swift tooling.
- Keep architecture simple and easy to evolve.
- Optimize for batch performance on folders containing a few hundred photos.
- Maintain good testability for scoring, scan logic, and decision state.
- Treat polished UX as important, but do not make major UI assumptions without discussion because the review experience is still open.

## Current Repo Context
- This repo is a native Swift app with SwiftUI.
- Tests currently use Swift `Testing`, so prefer extending that unless there is a clear reason not to.
- The codebase is early-stage. Favor incremental structure over premature abstraction.

## Guardrails For Agents
- Before introducing any non-trivial dependency, architectural layer, or framework beyond standard Apple APIs, discuss it first.
- Before introducing ML-based scoring or Vision-heavy analysis, discuss it first. Day 1 should bias toward simple heuristics and native APIs.
- Before changing file-deletion behavior, discuss the safety model first.
- Before redesigning the UI substantially, discuss the workflow because the review UX is not finalized.
- If a task touches product assumptions that are still unclear, stop and clarify rather than guessing.

## Expected Engineering Direction
- Separate scanning, scoring, and review-state logic so each can be tested independently.
- Favor asynchronous or incremental processing so the app remains responsive while evaluating many photos.
- Be deliberate about memory use when handling a few hundred images. Avoid loading full-resolution images into memory unnecessarily.
- Prefer deterministic, explainable scoring outputs over opaque scoring.
- When possible, return both an overall score and a set of named reasons that explain why the photo may be rejected.

## Open Questions To Clarify Before Major Implementation
- Exact scoring model and thresholds.
- Final review UI and how score explanations should be presented.
- Performance strategy for loading, caching, and scoring a few hundred photos smoothly.

## Change Guidance
- Keep changes focused and reversible.
- Add or update tests when touching logic with deterministic behavior.
- If a proposed solution conflicts with the local-first, minimal-dependency direction, call it out explicitly before implementing it.
