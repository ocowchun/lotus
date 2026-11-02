import CoreGraphics
import Foundation

@MainActor
struct PreviewCache {
    private struct Entry {
        let image: CGImage
        let cost: Int
    }

    let countLimit: Int
    let byteLimit: Int
    private var entries: [URL: Entry] = [:]
    private var recency: [URL] = []
    private(set) var totalCost = 0

    init(countLimit: Int = 6, byteLimit: Int = 64 * 1024 * 1024) {
        self.countLimit = countLimit
        self.byteLimit = byteLimit
    }

    var count: Int { entries.count }

    func contains(_ url: URL) -> Bool {
        entries[url] != nil
    }

    mutating func image(for url: URL) -> CGImage? {
        guard let entry = entries[url] else { return nil }
        recency.removeAll { $0 == url }
        recency.append(url)
        return entry.image
    }

    mutating func insert(_ image: CGImage, for url: URL, protecting selectedURL: URL?) {
        let cost = image.bytesPerRow * image.height
        guard countLimit > 0, cost <= byteLimit else { return }

        remove(url)
        while entries.count >= countLimit || totalCost + cost > byteLimit {
            guard let victim = recency.first(where: { $0 != selectedURL }) else { return }
            remove(victim)
        }

        entries[url] = Entry(image: image, cost: cost)
        recency.append(url)
        totalCost += cost
    }

    mutating func removeAll() {
        entries.removeAll()
        recency.removeAll()
        totalCost = 0
    }

    private mutating func remove(_ url: URL) {
        if let entry = entries.removeValue(forKey: url) {
            totalCost -= entry.cost
        }
        recency.removeAll { $0 == url }
    }
}

@MainActor
final class PreviewLoader {
    typealias Decode = @Sendable (URL) async throws -> CGImage

    private struct Load {
        let url: URL
        let generation: Int
    }

    private(set) var cache: PreviewCache
    private let decode: Decode
    private var generation = 0
    private var selectedURL: URL?
    private var desiredURLs: Set<URL> = []
    private var queue: [URL] = []
    private var activeLoad: Load?
    private var onReady: ((CGImage?) -> Void)?

    init(cache: PreviewCache? = nil, decode: @escaping Decode = { url in
        try PhotoPipeline().makePreview(for: url)
    }) {
        self.cache = cache ?? PreviewCache()
        self.decode = decode
    }

    static func neighbors(in urls: [URL], around selectedURL: URL) -> [URL] {
        guard let index = urls.firstIndex(of: selectedURL) else { return [] }
        return [index + 1, index + 2, index - 1].compactMap {
            urls.indices.contains($0) ? urls[$0] : nil
        }
    }

    func select(_ url: URL, neighbors: [URL], onReady: @escaping (CGImage?) -> Void) {
        selectedURL = url
        self.onReady = onReady
        let ordered = [url] + neighbors
        desiredURLs = Set(ordered)
        var seen: Set<URL> = []
        queue = ordered.filter {
            seen.insert($0).inserted && !cache.contains($0)
                && !(activeLoad?.url == $0 && activeLoad?.generation == generation)
        }

        if let image = cache.image(for: url) {
            onReady(image)
        }
        startNextIfNeeded()
    }

    func clear() {
        generation += 1
        selectedURL = nil
        desiredURLs = []
        queue = []
        onReady = nil
        cache.removeAll()
        // An ImageIO decode cannot be interrupted. Keep its slot until it finishes.
    }

    private func startNextIfNeeded() {
        guard activeLoad == nil else { return }
        while let url = queue.first {
            queue.removeFirst()
            guard !cache.contains(url) else { continue }

            let load = Load(url: url, generation: generation)
            activeLoad = load
            let decode = decode
            let priority: TaskPriority = url == selectedURL ? .userInitiated : .utility
            let work = Task.detached(priority: priority) {
                try? await decode(url)
            }
            Task(priority: priority) { [weak self] in
                let image = await work.value
                self?.finish(load, image: image)
            }
            return
        }
    }

    private func finish(_ load: Load, image: CGImage?) {
        activeLoad = nil
        if load.generation == generation, desiredURLs.contains(load.url) {
            if let image {
                cache.insert(image, for: load.url, protecting: selectedURL)
            }
            if selectedURL == load.url {
                onReady?(image)
            }
        }
        startNextIfNeeded()
    }
}
