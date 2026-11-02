# Bounded Preview Cache Implementation Plan

**Goal:** Display nearby review photos sharply without reloading their previews, with at most six cached previews and 64 MiB of decoded cache pixels.

**Approved design:** Keep the existing 1800-pixel preview resolution. Preload two photos ahead and one behind in filtered review order. Cache by URL with least-recently-used eviction, protect the selected cached image, and account for actual `bytesPerRow * height`. Clear cached images when replacing or completing a review. Temporary decoder and display allocations are outside the cache budget.

**Architecture:** A main-actor `PreviewLoader` owns the cache, selection callback, and replaceable work queue. One background decoder runs at a time; selected uncached work goes first, existing work is reused, and obsolete queued work is discarded. Because ImageIO decoding is synchronous, let an active decode finish rather than starting unbounded replacements. Session generations prevent old results from entering a new review. Decode previews immediately off the main actor; keep thumbnails and scoring unchanged.

**Tech stack:** Swift, AppKit, Core Graphics, ImageIO, Swift Testing. No dependencies.

- [x] Add `PreviewCache` and `PreviewLoader` in `lotus/Support/PreviewLoader.swift`, with injectable decoding for deterministic tests.
- [x] Update `PhotoPipeline.makePreview` to return an eagerly decoded `CGImage`; retain existing thumbnail behavior.
- [x] Integrate the loader with selection, filters, imported batches, empty selections, folder replacement, fixtures, and completion in `ReviewStore`.
- [x] Add targeted tests for strict byte/count limits, eviction and selected-image protection, oversized images, neighborhood boundaries, queue replacement, load reuse, failures, stale results, and cached navigation.
- [x] Run unit tests and build; exercise the loader with the six demo JPEGs and a larger synthetic album; review the diff and update `docs/PROGRESS.md`.

**Verification so far:** `xcodebuild -quiet -scheme lotus -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/lotus-preview-cache -only-testing:lotusTests test` built successfully and passed all 19 tests with no compiler warnings. A standalone harness compiled from production `Models`, `PhotoPipeline`, and `PreviewLoader` sources measured a 226 ms first preview and 0.023–0.031 ms warmed select/callback delivery across the six demo JPEGs; forward and reverse navigation hit the cache, which held 49.438 MiB. A 300-photo synthetic test verified the six-image and 64 MiB limits at every insertion.

**Review:** Independent read-only review found no material correctness issues and confirmed background decoding under the app's MainActor default isolation setting.

**Validation limits:** Decode/cache timing can be measured without UI automation. End-to-end perceived sharpness and total app memory need a running-app check; cache bytes do not represent total process memory.
