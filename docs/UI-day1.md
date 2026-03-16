# Lotus UI Spec: Day 1 Review and Keyboard Model

## Summary

This document defines the Day 1 UI and keyboard interaction model for Lotus.

The Day 1 experience is a fast, keyboard-first, review-only workflow for a folder of photos. The UI should help the user move quickly through a few hundred photos, understand score signals at a glance, and make keep/reject decisions with minimal friction.

## Design Goals

- Optimize for full review by keyboard.
- Keep the current photo and current decision state obvious at all times.
- Minimize cognitive load during repetitive review.
- Make scoring useful without letting it dominate the interface.
- Preserve responsiveness during scanning, thumbnail loading, and scoring.

## Layout

### Overall Structure

The main review screen uses a 2-column layout:

- Left column: at least 60% of the available width
- Right column: remaining width

The left side is the primary review context. The right side is the list and navigation context.

### Top Review Header

A compact header should remain visible during review and show:

- folder name
- current position, such as `37 / 248`
- count of `keep`
- count of `reject`
- count of `undecided`

This header should stay lightweight and not consume excessive vertical space.

## Left Column

### Purpose

The left column is the main review surface for the currently selected photo.

### Required Content

The left column should contain:

- the current photo
- metadata
- score
- score reasons

### Metadata Shown

Day 1 metadata should include:

- filename
- capture time
- image dimensions
- file size
- focal length
- shutter speed
- aperture
- ISO

### Image Presentation

- The photo should preserve aspect ratio.
- Portrait and landscape images should fit within a stable preview frame.
- The layout should not shift dramatically based on image orientation.

### Loading Behavior

If the selected image preview is still loading:

- row selection should update immediately
- metadata should update as soon as available
- the preview area should show a loading placeholder or progressive preview state

If score analysis is still in progress:

- the photo remains fully reviewable
- the score area shows `analyzing...`
- score and reasons appear asynchronously when ready

### Score Presentation

The left panel should show:

- one overall score
- top 2-4 reasons only

Reasons should be compact and scannable. Day 1 should avoid deep diagnostic output in the main review flow.

## Right Column

### Purpose

The right column is the photo list and selection surface.

### Row Content

Each row should contain:

- thumbnail
- filename
- state icon
- optional compact score signal

The row should prioritize scanability over detail density.

### Selection State

The currently selected row should have a strong, clean selection treatment across the full row so the user can always tell where they are in the sequence.

### Decision State

Rows should visually distinguish:

- `keep`
- `reject`
- `undecided`

The treatment should be lightweight. Compact icons and subtle row styling are preferred over large badges or loud color blocks.

When a photo is marked `reject`:

- the row state should update immediately
- the top summary counts should update immediately
- the photo should remain visible unless the current filter hides it

## Selection Model

Day 1 should use a single global review focus model.

- The selected row in the right column and the active photo in the left column must always stay in sync.
- Keyboard shortcuts act on the selected photo.
- The user should not need to manage separate focus between the list and the preview panel.

### Mouse Behavior

- Single-click on a row selects that photo.
- Double-click on a row opens zoom mode for that photo.
- Clicking a row does not directly change keep/reject state.

## Keyboard Model

### Focus

After the user selects a folder and the first photo appears, the review context should be ready for keyboard use immediately.

The user should not need to click into the interface before using review shortcuts.

### Default Shortcuts

Day 1 default keyboard shortcuts:

- `Up Arrow`: previous photo
- `K`: previous photo
- `Down Arrow`: next photo
- `J`: next photo
- `S`: mark keep
- `D`: mark reject
- `Space`: enter or toggle zoom mode

`Undecided` should also be supported by shortcut, but the exact default key can remain configurable if not finalized yet.

### Decision Behavior

When the user presses `S` or `D`:

- apply the decision immediately
- update the row state immediately
- update summary counts immediately
- auto-advance to the next photo

The user must always be able to move back and revise a previous decision.

### Rapid Navigation

If the user presses and holds navigation keys:

- row selection should move immediately
- the right list should remain responsive
- preview and score updates may trail slightly, but the UI should continue to feel fluid

## Filtering

### Day 1 Filters

The Day 1 filter set is:

- `all`
- `undecided`
- `keep`
- `reject`

The filter control should be a compact segmented control near the top of the right column.

### Filter Behavior

- Filtering constrains the list contents.
- Next and previous navigation should operate within the currently filtered set.
- If a filter hides the currently selected photo, selection should automatically move to the nearest visible item.

## Zoom Mode

### Purpose

Zoom mode exists to let users inspect detail such as sharpness without breaking review flow.

### Behavior

- Zoom mode should be temporary and in-window.
- It should not open a separate window in Day 1.
- It should preserve the current selection and review context.
- It should support quick entry and exit from keyboard.

`Space` should toggle this mode by default.

## Hotkey Customization

### Goal

Users should be able to customize core review shortcuts.

### Scope

Day 1 customization should be limited to a small fixed set of actions:

- next photo
- previous photo
- keep
- reject
- undecided

### Settings Model

- Customization should live in a simple settings screen.
- The UI should show the currently active bindings.
- Menus, labels, or help surfaces should reflect customized shortcuts.

### Conflict Handling

If a user tries to assign a shortcut that conflicts with another defined review action:

- detect the conflict immediately
- block the save
- show which action already uses that shortcut

## Help and Discoverability

The app should provide a lightweight way to discover the current shortcut map, especially once customization exists.

Day 1 can satisfy this with a simple help panel, cheat sheet, or menu-based shortcut display.

## Interaction Principles

- Scoring should support decisions, not interrupt them.
- Navigation should always feel faster than manual file browsing.
- The interface should communicate state changes immediately.
- No interaction should create ambiguity about whether the app changed files on disk.

## Open UI Questions

- Final visual design of state icons
- Exact visual treatment of score indicators in the right-side list
- Default key for `undecided`
- Exact zoom interaction details beyond basic toggle behavior
