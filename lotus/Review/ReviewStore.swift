//
//  ReviewStore.swift
//  lotus
//

import AppKit
import Combine
import Foundation
import Observation

@MainActor
@Observable
final class ReviewStore {
    private enum ImportBatching {
        static let recordBatchSize = 24
        static let enrichmentConcurrency = 4
    }

    private(set) var folderURL: URL?
    private(set) var photos: [PhotoRecord] = []
    var selectedPhotoID: PhotoRecord.ID?
    private(set) var previewImage: NSImage?
    private(set) var isPreviewLoading = false
    private(set) var isImporting = false
    private(set) var errorMessage: String?
    private(set) var filter: ReviewFilter = .all
    var metadataMode: MetadataPanelMode = .concise
    var isZoomed = false
    private(set) var completion: ReviewCompletion?

    private let pipeline = PhotoPipeline()
    private let previewLoader: PreviewLoader
    private let shortcutStore: ShortcutStore
    private let confirmMoveRejectedToTrash: @MainActor (ReviewSummary) -> Bool
    private let moveRejectedToTrash: ([URL]) throws -> Int
    private var importTask: Task<Void, Never>?
    private var isFinalizationInFlight = false

    init(
        shortcutStore: ShortcutStore,
        confirmMoveRejectedToTrash: @escaping @MainActor (ReviewSummary) -> Bool = ReviewStore.defaultConfirmMoveRejectedToTrash,
        moveRejectedToTrash: @escaping ([URL]) throws -> Int = ReviewStore.defaultMoveRejectedToTrash,
        previewLoader: PreviewLoader? = nil
    ) {
        self.shortcutStore = shortcutStore
        self.confirmMoveRejectedToTrash = confirmMoveRejectedToTrash
        self.moveRejectedToTrash = moveRejectedToTrash
        self.previewLoader = previewLoader ?? PreviewLoader()
    }

    var visiblePhotos: [PhotoRecord] {
        photos.filter { filter.matches($0.decision) }
    }

    var currentPhoto: PhotoRecord? {
        guard let selectedPhotoID else { return nil }
        return photos.first(where: { $0.id == selectedPhotoID })
    }

    var currentDisplayImage: NSImage? {
        previewImage ?? currentPhoto?.thumbnail
    }

    var summary: ReviewSummary {
        ReviewSummary.make(from: photos)
    }

    var positionText: String {
        guard
            let selectedPhotoID,
            let position = visiblePhotos.firstIndex(where: { $0.id == selectedPhotoID })
        else {
            return "0 / \(visiblePhotos.count)"
        }

        return "\(position + 1) / \(visiblePhotos.count)"
    }

    func selectFolder() {
        guard confirmDiscardIfNeeded() else { return }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK, let url = panel.url {
            loadFolder(at: url)
        }
    }

    func loadFolder(at url: URL) {
        importTask?.cancel()
        previewLoader.clear()

        folderURL = url
        completion = nil
        photos = []
        selectedPhotoID = nil
        previewImage = nil
        isPreviewLoading = false
        isImporting = true
        errorMessage = nil
        metadataMode = .concise
        isZoomed = false

        importTask = Task { [weak self] in
            guard let self else { return }

            do {
                let urls = try await Task.detached(priority: .userInitiated) {
                    try PhotoPipeline().scanFolder(at: url)
                }.value

                if urls.isEmpty {
                    self.errorMessage = "No supported images were found in that folder."
                    self.isImporting = false
                    return
                }

                let indexedURLs = Array(urls.enumerated())
                for batchStart in stride(from: 0, to: indexedURLs.count, by: ImportBatching.recordBatchSize) {
                    try Task.checkCancellation()
                    let batch = Array(indexedURLs[batchStart..<min(batchStart + ImportBatching.recordBatchSize, indexedURLs.count)])
                    let records = await Task.detached(priority: .userInitiated) {
                        let pipeline = PhotoPipeline()
                        return batch.compactMap { index, fileURL -> IndexedPhotoRecord? in
                            guard let record = try? pipeline.makeRecord(for: fileURL) else { return nil }
                            return IndexedPhotoRecord(index: index, record: record)
                        }
                    }.value

                    self.appendImportedRecords(records)

                    if self.errorMessage == nil, records.count != batch.count {
                        self.errorMessage = "Some images could not be read."
                    }
                }

                try await self.enrichPhotos(urls)

                self.isImporting = false
            } catch is CancellationError {
                self.isImporting = false
            } catch {
                self.errorMessage = "Lotus could not scan the selected folder."
                self.isImporting = false
            }
        }
    }

    func selectPhoto(id: UUID) {
        guard selectedPhotoID != id else { return }
        selectedPhotoID = id
        isZoomed = false
        loadPreview(for: id)
    }

    func moveSelection(forward: Bool) {
        let pool = visiblePhotos
        guard !pool.isEmpty else { return }

        guard
            let selectedPhotoID,
            let currentIndex = pool.firstIndex(where: { $0.id == selectedPhotoID })
        else {
            selectPhoto(id: pool[0].id)
            return
        }

        let delta = forward ? 1 : -1
        let newIndex = min(max(0, currentIndex + delta), pool.count - 1)
        selectPhoto(id: pool[newIndex].id)
    }

    func setDecision(_ decision: PhotoDecision) {
        guard let selectedPhotoID, let index = photos.firstIndex(where: { $0.id == selectedPhotoID }) else { return }

        photos[index].decision = decision
        reconcileSelectionAfterMutation(referenceID: selectedPhotoID)

        let currentSummary = summary
        if currentSummary.undecidedCount == 0 {
            finalizeReviewIfPossible(summary: currentSummary)
            return
        }

        if decision != .undecided {
            moveSelection(forward: true)
        }
    }

    func setFilter(_ filter: ReviewFilter) {
        self.filter = filter
        reconcileSelectionAfterMutation(referenceID: selectedPhotoID)
    }

    func toggleMetadataMode() {
        metadataMode = metadataMode == .concise ? .full : .concise
    }

    func toggleZoom() {
        guard currentDisplayImage != nil else { return }
        isZoomed.toggle()
    }

    func handleShortcut(_ key: ShortcutKey) {
        let shortcuts = shortcutStore.shortcuts

        switch key {
        case shortcuts.previousPrimary, shortcuts.previousSecondary:
            moveSelection(forward: false)
        case shortcuts.nextPrimary, shortcuts.nextSecondary:
            moveSelection(forward: true)
        case shortcuts.keep:
            setDecision(.keep)
        case shortcuts.reject:
            setDecision(.reject)
        case shortcuts.undecided:
            setDecision(.undecided)
        case shortcuts.more:
            toggleMetadataMode()
        case shortcuts.zoom:
            toggleZoom()
        default:
            break
        }
    }

    private func updateAnalysis(for id: UUID, analysis: AnalysisState) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        photos[index].analysis = analysis
    }

    private func updateThumbnail(for id: UUID, thumbnail: NSImage?) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        photos[index].thumbnail = thumbnail
    }

    private func loadPreview(for id: UUID) {
        previewImage = nil
        isPreviewLoading = true

        guard let record = photos.first(where: { $0.id == id }) else {
            previewLoader.clear()
            isPreviewLoading = false
            return
        }

        let neighbors = PreviewLoader.neighbors(in: visiblePhotos.map(\.url), around: record.url)
        previewLoader.select(record.url, neighbors: neighbors) { [weak self] image in
            guard let self, self.selectedPhotoID == id else { return }
            self.previewImage = image.map { NSImage(cgImage: $0, size: .zero) }
            self.isPreviewLoading = false
        }
    }

    private func reconcileSelectionAfterMutation(referenceID: UUID?) {
        let pool = visiblePhotos

        guard !pool.isEmpty else {
            previewLoader.clear()
            selectedPhotoID = nil
            previewImage = nil
            isPreviewLoading = false
            return
        }

        if let selectedPhotoID, pool.contains(where: { $0.id == selectedPhotoID }) {
            loadPreview(for: selectedPhotoID)
            return
        }

        if let referenceID, let referenceIndex = photos.firstIndex(where: { $0.id == referenceID }) {
            let nearest = pool.min(by: { lhs, rhs in
                guard
                    let lhsIndex = photos.firstIndex(where: { $0.id == lhs.id }),
                    let rhsIndex = photos.firstIndex(where: { $0.id == rhs.id })
                else {
                    return false
                }

                return abs(lhsIndex - referenceIndex) < abs(rhsIndex - referenceIndex)
            })

            if let nearest {
                selectPhoto(id: nearest.id)
                return
            }
        }

        if let first = pool.first {
            selectPhoto(id: first.id)
        }
    }

    private func confirmDiscardIfNeeded() -> Bool {
        guard !photos.isEmpty else { return true }

        let alert = NSAlert()
        alert.messageText = "Replace current review?"
        alert.informativeText = "Your in-memory review decisions will be lost."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn
    }

    private func finalizeReviewIfPossible(summary: ReviewSummary) {
        guard !isFinalizationInFlight else { return }
        guard let folderName = folderURL?.lastPathComponent else { return }

        if summary.rejectCount == 0 {
            completeReview(folderName: folderName, keepCount: summary.keepCount, trashedCount: 0)
            return
        }

        let rejectedURLs = photos
            .filter { $0.decision == .reject }
            .map(\.url)

        guard !rejectedURLs.isEmpty else {
            completeReview(folderName: folderName, keepCount: summary.keepCount, trashedCount: 0)
            return
        }

        guard confirmMoveRejectedToTrash(summary) else { return }

        isFinalizationInFlight = true
        defer { isFinalizationInFlight = false }

        do {
            let movedCount = try moveRejectedToTrash(rejectedURLs)
            completeReview(folderName: folderName, keepCount: summary.keepCount, trashedCount: movedCount)
        } catch {
            errorMessage = "Lotus could not move rejected photos to Trash."
        }
    }

    private func completeReview(folderName: String, keepCount: Int, trashedCount: Int) {
        previewLoader.clear()
        completion = ReviewCompletion.make(folderName: folderName, keepCount: keepCount, trashedCount: trashedCount)
        photos = []
        selectedPhotoID = nil
        previewImage = nil
        isPreviewLoading = false
        isZoomed = false
        metadataMode = .concise
        filter = .all
        errorMessage = nil
    }

    private static func defaultConfirmMoveRejectedToTrash(summary: ReviewSummary) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Move rejected photos to Trash?"
        alert.informativeText = "\(summary.rejectCount) rejected photo(s) will be moved to Trash. Kept photos will remain untouched."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move To Trash")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    nonisolated private static func defaultMoveRejectedToTrash(_ urls: [URL]) throws -> Int {
        var movedCount = 0
        for url in urls {
            var trashedURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &trashedURL)
            movedCount += 1
        }
        return movedCount
    }

#if DEBUG
    func loadFixturePhotos(_ fixturePhotos: [PhotoRecord], folderName: String) {
        previewLoader.clear()
        folderURL = URL(fileURLWithPath: "/tmp/\(folderName)")
        completion = nil
        photos = fixturePhotos
        selectedPhotoID = fixturePhotos.first?.id
        previewImage = nil
        isPreviewLoading = false
        isImporting = false
        errorMessage = nil
        filter = .all
        metadataMode = .concise
        isZoomed = false
    }
#endif

    private func appendImportedRecords(_ imported: [IndexedPhotoRecord]) {
        let sortedRecords = imported.sorted { $0.index < $1.index }.map(\.record)
        guard !sortedRecords.isEmpty else { return }

        photos.append(contentsOf: sortedRecords)

        if selectedPhotoID == nil, let first = sortedRecords.first {
            selectedPhotoID = first.id
            loadPreview(for: first.id)
        } else if let selectedPhotoID {
            loadPreview(for: selectedPhotoID)
        }
    }

    private func enrichPhotos(_ urls: [URL]) async throws {
        let indexedURLs = Array(urls.enumerated())

        try await withThrowingTaskGroup(of: EnrichedPhoto.self) { group in
            var nextIndex = 0
            let initialCount = min(ImportBatching.enrichmentConcurrency, indexedURLs.count)

            for _ in 0..<initialCount {
                let pair = indexedURLs[nextIndex]
                nextIndex += 1
                group.addTask {
                    try await Self.processEnrichment(for: pair.offset, fileURL: pair.element)
                }
            }

            while let result = try await group.next() {
                self.applyEnrichment(result)

                if nextIndex < indexedURLs.count {
                    let pair = indexedURLs[nextIndex]
                    nextIndex += 1
                    group.addTask {
                        try await Self.processEnrichment(for: pair.offset, fileURL: pair.element)
                    }
                }
            }
        }
    }

    private func applyEnrichment(_ result: EnrichedPhoto) {
        guard result.index < photos.count else { return }

        let id = photos[result.index].id
        updateThumbnail(for: id, thumbnail: result.thumbnail)
        updateAnalysis(for: id, analysis: result.analysis)
    }

    private static func processEnrichment(for index: Int, fileURL: URL) async throws -> EnrichedPhoto {
        try Task.checkCancellation()

        return await Task.detached(priority: .utility) {
            let pipeline = PhotoPipeline()
            let thumbnail = try? pipeline.makeThumbnail(for: fileURL)
            let analysis: AnalysisState
            do {
                let score = try pipeline.analyze(url: fileURL)
                analysis = .ready(score)
            } catch {
                analysis = .failed
            }

            return EnrichedPhoto(index: index, thumbnail: thumbnail, analysis: analysis)
        }.value
    }
}

private struct IndexedPhotoRecord {
    let index: Int
    let record: PhotoRecord
}

private struct EnrichedPhoto {
    let index: Int
    let thumbnail: NSImage?
    let analysis: AnalysisState
}
