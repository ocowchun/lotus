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
    private static let placeholderMetadata = PhotoMetadata(
        captureTime: "Now",
        captureTimeShort: "Now",
        dimensions: "100 × 100",
        fileSize: "1 MB",
        focalLength: "35 mm",
        shutterSpeed: "1/125 s",
        aperture: "f/2.8",
        iso: "ISO 100"
    )

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
        let photos = [
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/a.jpg"),
                filename: "a.jpg",
                metadata: Self.placeholderMetadata,
                decision: .keep,
                analysis: .pending,
                thumbnail: nil
            ),
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/b.jpg"),
                filename: "b.jpg",
                metadata: Self.placeholderMetadata,
                decision: .reject,
                analysis: .pending,
                thumbnail: nil
            ),
            PhotoRecord(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/c.jpg"),
                filename: "c.jpg",
                metadata: Self.placeholderMetadata,
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

    @MainActor
    @Test func finalDecisionCancelKeepsReviewOpen() {
        let shortcutStore = ShortcutStore()
        let store = ReviewStore(
            shortcutStore: shortcutStore,
            confirmMoveRejectedToTrash: { _ in false },
            moveRejectedToTrash: { _ in Issue.record("Should not move to trash when user cancels"); return 0 }
        )

        let photos = [
            Self.makePhoto(filename: "a.jpg", decision: .undecided),
            Self.makePhoto(filename: "b.jpg", decision: .reject)
        ]

        store.loadFixturePhotos(photos, folderName: "Trip")
        store.selectPhoto(id: photos[0].id)
        store.setDecision(.keep)

        #expect(store.completion == nil)
        #expect(store.photos.count == 2)
        #expect(store.summary.undecidedCount == 0)
    }

    @MainActor
    @Test func finalDecisionConfirmMovesRejectedAndShowsCompletion() {
        let shortcutStore = ShortcutStore()
        var movedURLs: [URL] = []
        let store = ReviewStore(
            shortcutStore: shortcutStore,
            confirmMoveRejectedToTrash: { summary in
                #expect(summary.rejectCount == 1)
                return true
            },
            moveRejectedToTrash: { urls in
                movedURLs = urls
                return urls.count
            }
        )

        let photos = [
            Self.makePhoto(filename: "a.jpg", decision: .undecided),
            Self.makePhoto(filename: "b.jpg", decision: .reject)
        ]

        store.loadFixturePhotos(photos, folderName: "Trip")
        store.selectPhoto(id: photos[0].id)
        store.setDecision(.keep)

        #expect(movedURLs.map(\.lastPathComponent) == ["b.jpg"])
        #expect(store.photos.isEmpty)
        #expect(store.completion?.folderName == "Trip")
        #expect(store.completion?.keepCount == 1)
        #expect(store.completion?.trashedCount == 1)
    }

    @MainActor
    @Test func allKeepReviewCompletesWithoutTrashPrompt() {
        let shortcutStore = ShortcutStore()
        let store = ReviewStore(
            shortcutStore: shortcutStore,
            confirmMoveRejectedToTrash: { _ in Issue.record("Should not ask to trash when there are no rejected photos"); return false },
            moveRejectedToTrash: { _ in Issue.record("Should not move any files to trash"); return 0 }
        )

        let photos = [
            Self.makePhoto(filename: "a.jpg", decision: .undecided)
        ]

        store.loadFixturePhotos(photos, folderName: "Trip")
        store.selectPhoto(id: photos[0].id)
        store.setDecision(.keep)

        #expect(store.completion?.trashedCount == 0)
        #expect(store.completion?.keepCount == 1)
    }

    @Test func completionHeadlineUsesOutcomeBucketMessages() {
        let keepHeavy = ReviewCompletion.make(folderName: "Trip", keepCount: 5, trashedCount: 1)
        let rejectHeavy = ReviewCompletion.make(folderName: "Trip", keepCount: 1, trashedCount: 4)
        let mixed = ReviewCompletion.make(folderName: "Trip", keepCount: 3, trashedCount: 3)

        #expect([
            "You pulled together a strong set.",
            "Nice pass. The keepers held up well.",
            "That review paid off. You kept the best of the batch."
        ].contains(keepHeavy.title))

        #expect([
            "Strong call. You cleared out the weaker shots.",
            "Good review. You made room for the images that matter.",
            "That was a solid cleanup pass."
        ].contains(rejectHeavy.title))

        #expect([
            "Nice work. That was a thoughtful review pass.",
            "Solid progress. You gave this set a clean edit.",
            "Well done. You made clear decisions across the set."
        ].contains(mixed.title))
    }

    @MainActor
    private static func makePhoto(filename: String, decision: PhotoDecision) -> PhotoRecord {
        PhotoRecord(
            id: UUID(),
            url: URL(fileURLWithPath: "/tmp/\(filename)"),
            filename: filename,
            metadata: placeholderMetadata,
            decision: decision,
            analysis: .pending,
            thumbnail: nil
        )
    }

}
