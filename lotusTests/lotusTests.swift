//
//  lotusTests.swift
//  lotusTests
//
//  Created by ocowchun on 2026/3/16.
//

import Foundation
import Testing
@testable import lotus

struct lotusTests {

    @Test func filterMatchesExpectedDecisionStates() {
        #expect(ReviewFilter.all.matches(.keep))
        #expect(ReviewFilter.keep.matches(.keep))
        #expect(!ReviewFilter.keep.matches(.reject))
        #expect(ReviewFilter.undecided.matches(.undecided))
    }

    @Test func shortcutConflictDetectionFindsExistingAssignments() {
        let shortcuts = ReviewShortcuts()
        let conflict = shortcuts.conflict(for: .keep, key: .d)

        #expect(conflict == .reject)
    }

    @Test func reviewSummaryCountsEachDecision() {
        let placeholderMetadata = PhotoMetadata(
            captureTime: "Now",
            captureTimeShort: "Now",
            dimensions: "100 × 100",
            fileSize: "1 MB",
            focalLength: "35 mm",
            shutterSpeed: "1/125 s",
            aperture: "f/2.8",
            iso: "ISO 100"
        )

        let photos = [
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/a.jpg"),
                filename: "a.jpg",
                metadata: placeholderMetadata,
                decision: .keep,
                analysis: .pending,
                thumbnail: nil
            ),
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/b.jpg"),
                filename: "b.jpg",
                metadata: placeholderMetadata,
                decision: .reject,
                analysis: .pending,
                thumbnail: nil
            ),
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/c.jpg"),
                filename: "c.jpg",
                metadata: placeholderMetadata,
                decision: .undecided,
                analysis: .pending,
                thumbnail: nil
            )
        ]

        let summary = ReviewSummary.make(from: photos)

        #expect(summary.keepCount == 1)
        #expect(summary.rejectCount == 1)
        #expect(summary.undecidedCount == 1)
    }

    @Test func conciseMetadataEntriesShowOnlyPrimaryExposureFields() {
        let metadata = PhotoMetadata(
            captureTime: "Now",
            captureTimeShort: "Now",
            dimensions: "100 × 100",
            fileSize: "1 MB",
            focalLength: "35 mm",
            shutterSpeed: "1/125 s",
            aperture: "f/2.8",
            iso: "ISO 100"
        )

        #expect(metadata.conciseEntries.map(\.label) == ["Focal Length", "Shutter", "Aperture", "ISO"])
        #expect(metadata.allEntries.count == 7)
    }

    @MainActor
    @Test func metadataModeToggleSwitchesBetweenConciseAndFull() {
        let shortcutStore = ShortcutStore()
        let store = ReviewStore(shortcutStore: shortcutStore)

        #expect(store.metadataMode == .concise)

        store.toggleMetadataMode()
        #expect(store.metadataMode == .full)

        store.toggleMetadataMode()
        #expect(store.metadataMode == .concise)
    }

}
