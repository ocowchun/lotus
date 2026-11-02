import CoreGraphics
import Foundation
import Testing
@testable import lotus

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PreviewLoaderTests {
    @Test func cacheEvictsLeastRecentlyUsedAndProtectsSelection() throws {
        let image = try makeImage()
        let urls = makeURLs(4)
        var cache = PreviewCache(countLimit: 3)
        for url in urls.prefix(3) {
            cache.insert(image, for: url, protecting: urls[0])
        }
        _ = cache.image(for: urls[1])
        cache.insert(image, for: urls[3], protecting: urls[0])

        #expect(cache.count == 3)
        #expect(cache.contains(urls[0]))
        #expect(cache.contains(urls[1]))
        #expect(!cache.contains(urls[2]))
        #expect(cache.contains(urls[3]))
    }

    @Test func byteLimitUsesActualBitmapCostAndRejectsOversizedImages() throws {
        let image = try makeImage()
        let cost = image.bytesPerRow * image.height
        let urls = makeURLs(3)
        var cache = PreviewCache(countLimit: 6, byteLimit: cost * 2)
        for url in urls {
            cache.insert(image, for: url, protecting: urls[0])
        }
        #expect(cache.count == 2)
        #expect(cache.totalCost == cost * 2)
        #expect(cache.contains(urls[0]))
        #expect(!cache.contains(urls[1]))

        let oversized = try makeImage(width: 200, height: 200)
        cache.insert(oversized, for: urls[1], protecting: urls[0])
        #expect(cache.totalCost == cost * 2)
        #expect(!cache.contains(urls[1]))

        cache.removeAll()
        #expect(cache.count == 0)
        #expect(cache.totalCost == 0)
    }

    @Test func cacheStaysBoundedAcrossThreeHundredPhotos() throws {
        let image = try makeImage(width: 1800, height: 1200)
        var cache = PreviewCache()
        for url in makeURLs(300) {
            cache.insert(image, for: url, protecting: url)
            #expect(cache.count <= 6)
            #expect(cache.totalCost <= 64 * 1024 * 1024)
        }
        #expect(cache.count == 6)
        #expect(cache.totalCost == 6 * image.bytesPerRow * image.height)
    }

    @Test func neighborhoodFollowsProvidedOrderAndHandlesEdges() {
        let urls = makeURLs(6)
        #expect(PreviewLoader.neighbors(in: urls, around: urls[0]) == [urls[1], urls[2]])
        #expect(PreviewLoader.neighbors(in: urls, around: urls[2]) == [urls[3], urls[4], urls[1]])
        #expect(PreviewLoader.neighbors(in: urls, around: urls[5]) == [urls[4]])
        let filtered = [urls[0], urls[3], urls[5]]
        #expect(PreviewLoader.neighbors(in: filtered, around: urls[3]) == [urls[5], urls[0]])
        #expect(PreviewLoader.neighbors(in: filtered, around: urls[1]).isEmpty)
    }

    @Test func selectingActivePreloadReusesItAndBacktrackingIsSynchronous() async throws {
        let image = try makeImage()
        let urls = makeURLs(3)
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        var requests = decoder.requests.makeAsyncIterator()
        var delivered: [URL] = []

        loader.select(urls[0], neighbors: [urls[1], urls[2]]) { _ in delivered.append(urls[0]) }
        let first = try #require(await requests.next())
        #expect(first.url == urls[0])
        first.result.resume(returning: image)

        let second = try #require(await requests.next())
        #expect(second.url == urls[1])
        loader.select(urls[1], neighbors: [urls[2], urls[0]]) { _ in delivered.append(urls[1]) }
        second.result.resume(returning: image)

        let third = try #require(await requests.next())
        #expect(third.url == urls[2])
        #expect(delivered == [urls[0], urls[1]])
        loader.select(urls[0], neighbors: []) { _ in delivered.append(urls[0]) }
        #expect(delivered == [urls[0], urls[1], urls[0]])
        loader.clear()
        third.result.resume(returning: image)
    }

    @Test func navigationReplacesQueuedWorkAndIgnoresObsoleteResult() async throws {
        let image = try makeImage()
        let urls = makeURLs(5)
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        var requests = decoder.requests.makeAsyncIterator()
        var obsoleteDelivered = false
        let ready = AsyncStream<Bool>.makeStream()
        var results = ready.stream.makeAsyncIterator()

        loader.select(urls[0], neighbors: [urls[1], urls[2]]) { _ in obsoleteDelivered = true }
        let obsolete = try #require(await requests.next())
        loader.select(urls[3], neighbors: [urls[4]]) { ready.continuation.yield($0 != nil) }
        obsolete.result.resume(returning: image)

        let selected = try #require(await requests.next())
        #expect(selected.url == urls[3])
        #expect(!obsoleteDelivered)
        #expect(!loader.cache.contains(urls[0]))
        selected.result.resume(returning: image)
        #expect(await results.next() == true)
        let neighbor = try #require(await requests.next())
        #expect(neighbor.url == urls[4])
        loader.clear()
        neighbor.result.resume(returning: image)
    }

    @Test func clearingRejectsOldSessionEvenWhenURLMatches() async throws {
        let image = try makeImage()
        let url = makeURLs(1)[0]
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        var requests = decoder.requests.makeAsyncIterator()
        var delivered = 0
        let ready = AsyncStream<Bool>.makeStream()
        var results = ready.stream.makeAsyncIterator()

        loader.select(url, neighbors: []) { _ in Issue.record("Old session must not deliver") }
        let obsolete = try #require(await requests.next())
        loader.clear()
        #expect(loader.cache.count == 0)
        loader.select(url, neighbors: []) { image in
            delivered += 1
            ready.continuation.yield(image != nil)
        }
        obsolete.result.resume(returning: image)

        let replacement = try #require(await requests.next())
        #expect(replacement.url == url)
        #expect(delivered == 0)
        #expect(loader.cache.count == 0)
        replacement.result.resume(returning: image)
        #expect(await results.next() == true)
        #expect(delivered == 1)
        #expect(loader.cache.count == 1)
        loader.clear()
    }

    @Test func failedSelectedPreviewFinishesLoadingAndAllowsNextPhoto() async throws {
        let image = try makeImage()
        let urls = makeURLs(2)
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        var requests = decoder.requests.makeAsyncIterator()
        let ready = AsyncStream<Bool>.makeStream()
        var results = ready.stream.makeAsyncIterator()

        loader.select(urls[0], neighbors: [urls[1]]) { ready.continuation.yield($0 != nil) }
        let failed = try #require(await requests.next())
        failed.result.resume(throwing: PhotoPipelineError.unreadableImage)
        #expect(await results.next() == false)
        let next = try #require(await requests.next())
        #expect(next.url == urls[1])
        loader.select(urls[1], neighbors: []) { ready.continuation.yield($0 != nil) }
        next.result.resume(returning: image)
        #expect(await results.next() == true)
        #expect(!loader.cache.contains(urls[0]))
        #expect(loader.cache.contains(urls[1]))
        loader.clear()
    }

    @Test func reviewStorePreloadsFilteredOrderAndClearsEmptySelection() async throws {
        let image = try makeImage()
        let photos = makePhotos([.undecided, .keep, .undecided, .keep])
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        let store = ReviewStore(shortcutStore: ShortcutStore(), previewLoader: loader)
        var requests = decoder.requests.makeAsyncIterator()
        store.loadFixturePhotos(photos, folderName: "Filtered")
        store.setFilter(.undecided)

        let first = try #require(await requests.next())
        #expect(first.url == photos[0].url)
        first.result.resume(returning: image)
        let neighbor = try #require(await requests.next())
        #expect(neighbor.url == photos[2].url)
        #expect(store.previewImage != nil)
        #expect(!store.isPreviewLoading)

        store.selectPhoto(id: photos[2].id)
        #expect(store.isPreviewLoading)
        store.selectPhoto(id: photos[0].id)
        #expect(store.previewImage != nil)
        #expect(!store.isPreviewLoading)

        store.setFilter(.reject)
        #expect(store.selectedPhotoID == nil)
        #expect(store.previewImage == nil)
        #expect(!store.isPreviewLoading)
        #expect(loader.cache.count == 0)
        neighbor.result.resume(returning: image)
    }

    @Test func reviewAutoAdvanceUsesCachedPreviewAndCompletionClearsCache() async throws {
        let image = try makeImage()
        let photos = makePhotos([.undecided, .undecided, .undecided])
        let decoder = ControlledDecoder()
        let loader = PreviewLoader(decode: { try await decoder.decode($0) })
        let store = ReviewStore(
            shortcutStore: ShortcutStore(),
            confirmMoveRejectedToTrash: { _ in true },
            moveRejectedToTrash: { $0.count },
            previewLoader: loader
        )
        var requests = decoder.requests.makeAsyncIterator()
        store.loadFixturePhotos(photos, folderName: "AutoAdvance")
        store.setFilter(.all)
        let first = try #require(await requests.next())
        first.result.resume(returning: image)
        let second = try #require(await requests.next())
        second.result.resume(returning: image)
        let third = try #require(await requests.next())

        store.setDecision(.keep)
        #expect(store.selectedPhotoID == photos[1].id)
        #expect(store.previewImage != nil)
        #expect(!store.isPreviewLoading)
        store.setDecision(.reject)
        #expect(store.selectedPhotoID == photos[2].id)
        store.setDecision(.keep)
        #expect(store.completion != nil)
        #expect(store.previewImage == nil)
        #expect(loader.cache.count == 0)
        third.result.resume(returning: image)
    }

    private func makePhotos(_ decisions: [PhotoDecision]) -> [PhotoRecord] {
        zip(makeURLs(decisions.count), decisions).map { url, decision in
            PhotoRecord(
                id: UUID(), url: url, filename: url.lastPathComponent,
                metadata: PhotoMetadata(
                    captureTime: "Now", captureTimeShort: "Now", dimensions: "100 × 100",
                    fileSize: "1 MB", focalLength: "35 mm", shutterSpeed: "1/125 s", aperture: "f/2.8", iso: "100"
                ),
                decision: decision, analysis: .pending, thumbnail: nil
            )
        }
    }

    private func makeURLs(_ count: Int) -> [URL] {
        (0..<count).map { URL(fileURLWithPath: "/tmp/preview-\($0).jpg") }
    }

    private func makeImage(width: Int = 100, height: Int = 100) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        return try #require(context.makeImage())
    }
}

@MainActor
private final class ControlledDecoder {
    struct Request {
        let url: URL
        let result: CheckedContinuation<CGImage, Error>
    }

    let requests: AsyncStream<Request>
    private let continuation: AsyncStream<Request>.Continuation

    init() {
        let stream = AsyncStream<Request>.makeStream()
        requests = stream.stream
        continuation = stream.continuation
    }

    func decode(_ url: URL) async throws -> CGImage {
        try await withCheckedThrowingContinuation { result in
            continuation.yield(Request(url: url, result: result))
        }
    }
}
