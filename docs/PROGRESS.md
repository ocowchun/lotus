# Lotus Progress

## TODO

- Add a direct way to jump back to unresolved (`undecided`) photos from the review flow.
- Add clear UI messaging that Day 1 does not modify or delete files on disk.
- Add visible mouse-accessible decision controls for `keep`, `reject`, and `undecided`.
- Improve unsupported-file reporting beyond the current generic partial-failure message.
- Make the metadata panel adapt more gracefully to narrower window sizes and different image aspect ratios.

## WIP

- Refine the review UI layout, especially the metadata/evaluation panel density and responsiveness.
- Continue validating the Day 1 review workflow against [PRD-day1.md](/Users/ocowchun/projects/swift/lotus/docs/PRD-day1.md).
- Incrementally migrate app state to SwiftUI's newer Observation model.

## Done

- Added a preview cache capped at six images and 64 MiB of decoded pixels, with preloading two photos ahead and one behind in filtered review order. Preview decoding runs off the main actor one image at a time; cached navigation is immediate, and replacing/completing a review clears the cache. All 19 unit tests passed, including 300-photo cache bounds and review integration checks. The six demo JPEGs occupied 49.44 MiB; a standalone loader check measured about 226 ms for the first preview and under 0.04 ms for warmed image delivery. End-to-end screen rendering and total process memory remain manual checks.
- Review shortcuts preserve consumed keyboard events, preventing handled keys such as S/D from reaching macOS and triggering its alert sound. Verified event forwarding behavior and all nine unit tests; listening in the running app remains a manual check.
- Folder selection for a single local directory.
- Non-recursive scan of supported still-image formats.
- Alphabetical photo ordering.
- Incremental metadata loading, thumbnail loading, and score enrichment.
- In-memory review state with `keep`, `reject`, and `undecided`.
- Auto-advance after `keep` and `reject`.
- Previous/next navigation and photo reselection.
- Filters for `all`, `undecided`, `keep`, and `reject`.
- Review summary counts in the header.
- Keyboard shortcuts for navigation and review actions.
- Explainable heuristic scoring with top reasons and technical breakdown.
- Warning before replacing the current in-memory review when switching folders.
- Concise and full metadata panel modes with `M` toggle.
- Automatic finalization when all photo decisions are complete.
- Confirmation flow to move rejected photos to macOS Trash.
- Read-write access for user-selected folders so the trash flow can modify files after confirmation.
- Completion summary screen after the trash action finishes.
- Outcome-based encouraging completion messages with warm tone variants.
- Top-level README with a simple product introduction and current scope.
- `ReviewStore` migrated from `ObservableObject` to the `@Observable` macro.
- `ShortcutStore` migrated from `ObservableObject` to the `@Observable` macro and typed `@Environment` injection.
- `ContentView` and the metadata/evaluation UI were split into dedicated review section files, with a stable top-level container instead of root-level branch swapping.
- Swift source files were reorganized into `App`, `Review`, `Review/Views`, and `Support` folders to make app flow and ownership easier to navigate.
- The app icon was redesigned around a minimal monochrome Aperture-inspired mark, with iterative drafts kept under `misc/app-icon/`.
- A reusable `scripts/build-release.sh` flow now produces a universal macOS tester build under `build/share/`.
