# AGENTS.md

## Product Vision
- `lotus` is a macOS app for photo culling.
- The core job to be done is to help a user move from "I imported a few hundred photos and do not want to inspect each one manually" to "I confidently committed a keep/reject decision set" with minimal friction.
- The product should reduce decision fatigue, speed up repetitive review, and help the user trust that the app is helping rather than taking control away from them.
- Day 1 scope is local-only, macOS-only, and focused on common photo formats. Do not assume cloud services, backend components, or multi-platform support.

## Core User Flow
- The user selects a folder.
- The app scans that folder for supported photos.
- The app computes a photo score and separate quality reasons for each photo.
- The app presents the photos in a review UI where the user decides keep or reject.
- After every photo has a decision, the user can explicitly commit the decision set.
- Only after that explicit commit step does the app remove unwanted photos.

## Product Principles
- The app should help users decide faster, not make irreversible decisions for them.
- Scores must be explainable. If the app flags a photo, the user should be able to understand why.
- The review flow must feel safe. Deletion is the last step, never an automatic side effect of scanning or scoring.
- Quality analysis should be useful enough to guide attention, even if the scoring is imperfect in early versions.
- UX matters because this product is fundamentally about reducing cognitive load during review.

## Day 1 Scope
- Allow the user to select a single folder.
- Scan only that folder. Do not recurse into subfolders unless the user explicitly asks for it later.
- Support common image formats only in the initial version.
- Compute photo quality scores locally on the Mac.
- Show photos in a review experience where the user can decide keep or reject for each photo.
- Require a final explicit commit step before removing rejected photos.

## What The Product Should Help With
- Quickly identifying likely bad photos from issues such as wonky horizon or verticals, blur or camera shake, overexposure, underexposure, and similar obvious technical problems.
- Giving users enough signal to prioritize attention across hundreds of photos.
- Preserving final human judgment for edge cases and subjective choices.

## Non-Goals By Default
- No backend service.
- No cloud API or remote processing.
- No additional programming languages.
- No complex third-party dependencies, including heavy ML stacks, unless discussed and explicitly approved first.
- No automatic deletion during scan or review. Deletion must stay behind an explicit final confirmation flow.

## Success Criteria
- A user can point the app at a folder of a few hundred photos and get to a review-ready state without the app feeling slow or fragile.
- The score helps the user spot likely rejects faster than manual review alone.
- The user understands why a photo was scored poorly.
- The user feels in control of the final deletion step.

## Product Risks To Watch
- A score that is too opaque or too noisy will reduce trust.
- A UI that shows too much analysis detail too early may increase decision fatigue instead of reducing it.
- A slow scan or sluggish grid will make the core workflow fail, even if the scoring is technically correct.
- Unsafe deletion behavior will destroy trust immediately.

## Current Repo Context
- This repo is a native Swift app with SwiftUI.
- Tests currently use Swift `Testing`, so prefer extending that unless there is a clear reason not to.
- The codebase is early-stage. Favor incremental structure over premature abstraction.

## Guardrails For Agents
- Start from the user workflow, not from interesting implementation ideas.
- If a technical proposal improves analysis quality but hurts trust, speed, simplicity, or safety, call out that tradeoff explicitly.
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
- Final review UI and how score explanations should be presented without overloading the user.
- Performance strategy for loading, caching, and scoring a few hundred photos smoothly.

## Change Guidance
- Keep changes focused and reversible.
- Add or update tests when touching logic with deterministic behavior.
- If a proposed solution conflicts with the local-first, minimal-dependency direction, call it out explicitly before implementing it.
