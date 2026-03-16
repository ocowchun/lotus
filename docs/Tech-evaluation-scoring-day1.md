# Lotus Technical Evaluation: Day 1 Scoring Feasibility

## Summary

This document evaluates the feasibility of implementing the Day 1 scoring signals for Lotus using native Apple frameworks.

Conclusion:

- Swift standard library alone is not enough.
- Native Apple frameworks are sufficient for a strong Day 1 implementation.
- External libraries are not required for Day 1.

The recommended Day 1 technical stack is:

- `ImageIO`
- `Core Graphics`
- `Core Image`
- `Accelerate / vImage`
- `Vision`
- `QuickLookThumbnailing` if needed for thumbnail generation convenience

## Overall Recommendation

Lotus should use native Apple frameworks only for Day 1.

This is enough to implement the most important early scoring signals:

- exposure problems
- blur or camera shake
- focus quality
- horizon tilt
- duplicate grouping

The one signal that should be treated as optional or experimental in Day 1 is:

- crooked verticals

## Feasibility Matrix

| Signal | Day 1 Feasible | Native Frameworks | Likely Approach | Risk |
|---|---|---|---|---|
| Exposure problems | Yes | `ImageIO`, `Core Image`, `Accelerate` | Thumbnail luminance histogram and clipping heuristics | Low |
| Blur / camera shake | Yes | `Accelerate`, `Core Image` | Edge energy or Laplacian-style sharpness heuristics on grayscale thumbnails | Medium |
| Focus quality | Yes | `Accelerate`, `Core Image` | Local sharpness map, center-weighted or region-weighted heuristic | Medium |
| Horizon tilt | Yes | `Vision` | Horizon angle detection | Low |
| Crooked verticals | Maybe | `Vision`, `Accelerate`, `Core Image` | Line and edge orientation heuristics | High |
| Duplicate grouping | Yes | `Vision`, `ImageIO` | Feature-print similarity with timestamp proximity | Low to Medium |

## Signal Evaluation

### 1. Exposure Problems

#### Feasibility

High. This is one of the easiest and most reliable Day 1 signals.

#### Native Approach

- Read metadata using `CGImageSourceCopyPropertiesAtIndex`.
- Create a downsampled image using `CGImageSourceCreateThumbnailAtIndex`.
- Compute luminance distribution from the thumbnail.
- Use histogram-based heuristics to estimate:
  - clipped highlights
  - crushed shadows
  - global brightness imbalance

#### Why It Works

- fast on thumbnails
- explainable in UI
- low engineering risk

#### Recommendation

Include in the first scoring iteration.

### 2. Blur / Camera Shake

#### Feasibility

Good. Native APIs are enough, but heuristics will need tuning.

#### Native Approach

- Convert a thumbnail to grayscale.
- Compute edge magnitude or high-frequency energy.
- Estimate global sharpness from the edge distribution.
- Penalize very low edge energy when the image otherwise appears properly exposed.

Possible implementation tools:

- `vImage`
- `Core Image`
- lightweight convolution or edge filters

#### Why It Works

- computationally practical
- useful for culling
- explainable as a penalty signal

#### Risks

- may confuse intentional shallow depth of field with motion blur
- threshold tuning will matter

#### Recommendation

Include in the first scoring iteration.

### 3. Focus Quality

#### Feasibility

Good, but more subjective than exposure or blur.

#### Native Approach

- Start from the same grayscale or edge-based analysis used for blur.
- Measure local sharpness rather than only global sharpness.
- Use a simple center-weighted or region-weighted heuristic for Day 1.
- Express this as a likely missed-focus signal rather than a hard failure.

#### Why It Works

- still possible on thumbnails
- complements blur scoring
- useful within similar-shot groups

#### Risks

- no explicit subject understanding in Day 1
- can produce false positives on compositions where the subject is off-center

#### Recommendation

Include, but treat thresholds conservatively.

### 4. Horizon Tilt

#### Feasibility

High, assuming Vision horizon detection is available on the deployment target.

#### Native Approach

- Use Vision horizon detection to estimate horizon angle.
- Ignore very small tilt.
- Penalize only once the angle exceeds a defined threshold.

#### Why It Works

- highly explainable
- practical for travel, landscape, and casual photography
- strong user-facing signal

#### Recommendation

Include in Day 1 if Vision support is confirmed for the target platform.

### 5. Crooked Verticals

#### Feasibility

Possible, but the weakest Day 1 candidate.

#### Native Approach

- extract edges or dominant lines
- cluster orientation of line-like structures
- estimate whether dominant vertical structures are meaningfully off vertical

This likely requires hand-tuned heuristics rather than a clean built-in detector.

#### Why It Is Harder

- scenes often do not contain clear vertical references
- perspective distortion complicates detection
- false positives may reduce trust quickly

#### Recommendation

Defer from the core Day 1 score unless implementation proves unexpectedly clean and reliable.

### 6. Duplicate Grouping

#### Feasibility

High. This is a strong fit for native Apple APIs.

#### Native Approach

- generate feature-print style embeddings using Vision
- compare visual similarity between photos
- combine with close timestamp or burst adjacency as a grouping hint
- form similar sets of 2 or more photos
- recommend best shot based primarily on technical score

#### Why It Works

- highly aligned with the core product use case
- different from technical quality, but very valuable for culling
- explainable when presented as a similar-set aid rather than a penalty

#### Recommendation

Include in Day 1 as a separate lane from technical scoring.

## Native Framework Assessment

### ImageIO

Use for:

- metadata extraction
- image source inspection
- efficient thumbnail and downsample creation

Why it matters:

- avoids loading full-resolution images unnecessarily
- supports low-memory batch processing

### Core Graphics

Use for:

- image plumbing
- interoperability with other Apple imaging frameworks

### Core Image

Use for:

- histogram-style analysis
- reduction filters
- edge-style preprocessing

Why it matters:

- good fit for lightweight image-analysis pipelines on thumbnails

### Accelerate / vImage

Use for:

- fast pixel processing
- grayscale conversion
- convolution-like analysis
- sharpness heuristics

Why it matters:

- high-performance low-level image operations
- well-suited for batch processing on many photos

### Vision

Use for:

- horizon detection
- feature-print generation for image similarity

Why it matters:

- gives access to higher-level image analysis without external dependencies

### QuickLookThumbnailing

Optional for:

- app-level thumbnail generation convenience

Why it matters:

- may simplify parts of thumbnail handling, but is not required for scoring itself

## External Library Evaluation

### Do We Need OpenCV or Similar Libraries?

Not for Day 1.

External libraries may become attractive later for:

- stronger line detection for vertical analysis
- more advanced classic computer-vision pipelines
- broader experimentation with handcrafted CV methods

### Why Avoid Them in Day 1

- added build and packaging complexity
- larger dependency surface
- more maintenance burden
- less native code path
- unnecessary before validating the Apple-native approach

## Recommended Day 1 Rollout

### Phase 1

Implement first:

- exposure problems
- blur or camera shake
- duplicate grouping

These provide strong product value with relatively low technical risk.

### Phase 2

Add next:

- focus quality
- horizon tilt

These are valuable but slightly more sensitive to threshold tuning or platform capability.

### Phase 3

Evaluate later:

- crooked verticals

Only include if the signal is accurate enough not to damage user trust.

## Main Risks

- blur detection may confuse intentional shallow depth of field with camera shake
- focus quality may be unreliable without subject understanding
- verticals may be too noisy for Day 1
- threshold tuning across mixed photo sets will take iteration
- any unreliable signal can reduce trust in the scoring system quickly

## Final Recommendation

Lotus should proceed with a native Apple-framework implementation for Day 1 scoring.

Use:

- `ImageIO`
- `Core Graphics`
- `Core Image`
- `Accelerate / vImage`
- `Vision`

Do not introduce external computer-vision libraries for Day 1.

Build the first scoring implementation around:

- exposure
- blur
- focus quality
- horizon tilt
- duplicate grouping

Treat crooked verticals as optional until it proves reliable.

## Sources

- Apple Image I/O Guide: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/imageio_source/ikpg_source.html
- `CGImageSourceCopyPropertiesAtIndex`: https://developer.apple.com/documentation/imageio/1464962-cgimagesourcecopypropertiesatind
- `CGImageSourceCreateThumbnailAtIndex`: https://developer.apple.com/documentation/imageio/1464966-cgimagesourcecreatethumbnailati
- Apple machine learning and Vision API overview: https://developer.apple.com/machine-learning/api/
- `DetectHorizonRequest`: https://developer.apple.com/documentation/vision/detecthorizonrequest
- `VNGenerateImageFeaturePrintRequest`: https://developer.apple.com/documentation/vision/vngenerateimagefeatureprintrequest
- Quick Look Thumbnailing: https://developer.apple.com/documentation/quicklookthumbnailing
