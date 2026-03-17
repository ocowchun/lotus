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

## Done

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
