# Lotus Scoring Spec: Day 1

## Summary

This document defines the Day 1 scoring model for Lotus.

The Day 1 scoring system is designed to help users make keep/reject decisions faster during photo review. It should provide useful, explainable technical signals without pretending to replace human judgment.

The scoring model is split into two lanes:

- technical quality
- similarity grouping

These two lanes must remain separate in both the scoring logic and the UI.

## Scoring Principles

- The score is a triage aid, not a final verdict.
- The score should help the user notice likely weak photos faster.
- The score should remain explainable.
- The score should not try to infer artistic quality in Day 1.
- Similarity is not the same as low quality and must not be collapsed into the technical score.

## Day 1 Scoring Lanes

### 1. Technical Quality Lane

The technical quality lane evaluates whether a photo appears to be a weak keep candidate for technical reasons.

The Day 1 technical score should be:

- numeric
- higher-is-better
- shown as something like `78 / 100`
- paired with a simple label such as `Good`, `Warning`, or `Poor`

The score should be driven primarily by penalties for clear weaknesses, rather than rewards for artistic or subjective strengths.

### 2. Similarity Lane

The similarity lane identifies photos that are visually similar or belong to a likely burst or close-timestamp group.

This lane should:

- identify similar sets of 2 or more photos
- use both visual similarity and burst or close-timestamp cues
- suggest a best shot within a similar set
- remain separate from the technical quality score

Similarity should be treated as a review aid, not as evidence that a photo is technically bad.

## Technical Quality Signals

Day 1 technical quality should focus on a small set of high-value signals.

### Highest Priority Signals

- blur or camera shake
- focus quality or local sharpness
- major exposure failures

These should carry the highest weight because they are strong reject drivers in typical culling workflows.

### Medium Priority Signals

- tilted horizon
- crooked verticals

These are useful and explainable, but generally less severe than blur or major exposure problems.

### Lower Priority Signals

- noise
- low contrast
- other secondary technical weakness

These can help identify weaker images, but should weigh less than the primary failure modes.

## Technical Score Construction

Day 1 scoring should mostly detect penalties for obvious technical weaknesses.

Recommended approach:

- start from a strong default score
- subtract weighted penalties for technical weaknesses
- normalize to a `0-100` score
- map to a human-friendly label such as `Good`, `Warning`, or `Poor`

This keeps the model more reliable than trying to infer overall beauty or excellence.

## Similarity Grouping

### Group Detection

A similar set should be formed when photos are judged to be related based on:

- visually similar image content
- same burst or close timestamp

Any group of 2 or more photos should qualify as a similar set in Day 1.

### Best Shot Recommendation

Within a similar set, Lotus should suggest a best shot.

The Day 1 recommendation should be based primarily on technical quality score. In practice, this means the best shot is likely the sharpest, best-exposed, and least technically flawed image in the group.

This recommendation must remain advisory. It is not an automatic keep decision.

## Compact UI Presentation

The default score UI should remain concise.

The compact score area should show:

- overall technical score, such as `78 / 100`
- technical label, such as `Good`, `Warning`, or `Poor`
- top warning reasons only

The compact view should mostly emphasize negative or cautionary reasons, because those are more actionable during culling.

Example warning reasons:

- blur detected
- likely missed focus
- overexposed highlights
- tilted horizon

## Expanded Detail UI

The score area should provide a `More` action to reveal more detail.

Day 1 behavior:

- `More` expands inline in the left panel
- keyboard shortcut: `M`

The expanded detail view should include:

- technical score breakdown
- key penalties or warning signals
- similar-set membership
- similar-set size
- recommended best shot, if applicable

This gives transparency without making the default view noisy.

## List-Level Presentation

In the right-side list, the score should remain secondary to:

- thumbnail
- filename
- decision state

The list may include:

- a compact score indicator
- a subtle similar-set indicator
- a lightweight marker for a recommended best shot within a similar set

The main list should remain alphabetical in Day 1. Scoring and similarity should not change row ordering.

## What Day 1 Should Not Do

Day 1 should not:

- mix duplicate or similar-set status into the technical score
- auto-reject photos because they are duplicates
- auto-keep the recommended best shot
- sort the main review list by score
- attempt face-specific analysis
- attempt artistic or aesthetic scoring

## Deferred To Day 2+

The following are explicitly deferred:

- face-aware checks such as eyes closed
- facial sharpness or portrait-specific signals
- more advanced best-shot ranking logic
- score-based sort or alternate review modes for similar sets
- richer duplicate comparison workflows

## Open Questions

The following still need later refinement before implementation:

- exact signal heuristics
- exact thresholds and weighting values
- final label thresholds for `Good`, `Warning`, and `Poor`
- exact UI treatment for similar-set and best-shot indicators
