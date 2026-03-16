//
//  PhotoPipeline.swift
//  lotus
//

import AppKit
import CoreGraphics
import Foundation
import ImageIO

enum PhotoPipelineError: Error {
    case unreadableImage
}

struct PhotoPipeline: Sendable {
    nonisolated static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff"
    ]

    nonisolated init() {}

    nonisolated func scanFolder(at folderURL: URL) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )

        return try urls
            .filter { url in
                let values = try url.resourceValues(forKeys: Set(keys))
                guard values.isRegularFile == true else { return false }
                return Self.supportedExtensions.contains(url.pathExtension.lowercased())
            }
            .sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    nonisolated func makeRecord(for url: URL) throws -> PhotoRecord {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PhotoPipelineError.unreadableImage
        }

        let metadata = makeMetadata(from: source, url: url)

        return PhotoRecord(
            id: UUID(),
            url: url,
            filename: url.lastPathComponent,
            metadata: metadata,
            decision: .undecided,
            analysis: .pending,
            thumbnail: nil
        )
    }

    nonisolated func makeThumbnail(for url: URL) throws -> NSImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = makeImage(from: source, maxPixelSize: 240) else {
            throw PhotoPipelineError.unreadableImage
        }

        return image
    }

    nonisolated func makePreview(for url: URL) throws -> NSImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = makeImage(from: source, maxPixelSize: 1800) else {
            throw PhotoPipelineError.unreadableImage
        }

        return image
    }

    nonisolated func analyze(url: URL) throws -> PhotoScore {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = makeCGImage(from: source, maxPixelSize: 320) else {
            throw PhotoPipelineError.unreadableImage
        }

        let analysis = PixelAnalyzer().analyze(image)
        let reasons = Array(analysis.reasons.prefix(3))
        let score = max(0, min(100, Int(round(analysis.score))))

        let label: ScoreLabel
        switch score {
        case 75...100: label = .good
        case 45..<75: label = .warning
        default: label = .poor
        }

        let breakdown = [
            ScoreBreakdown(title: "Average Brightness", value: analysis.averageBrightness.formattedPercent),
            ScoreBreakdown(title: "Contrast", value: analysis.contrast.formattedPercent),
            ScoreBreakdown(title: "Edge Detail", value: analysis.edgeEnergy.formattedPercent),
            ScoreBreakdown(title: "Evaluation Style", value: "Workflow-first heuristic")
        ]

        return PhotoScore(
            value: score,
            label: label,
            reasons: reasons.isEmpty ? ["No obvious issues detected"] : reasons,
            breakdown: breakdown
        )
    }

    nonisolated private func makeMetadata(from source: CGImageSource, url: URL) -> PhotoMetadata {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        let exif = properties?[kCGImagePropertyExifDictionary] as? [CFString: Any]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let shortFormatter = DateFormatter()
        shortFormatter.dateStyle = .none
        shortFormatter.timeStyle = .short

        let capturedDate = (exif?[kCGImagePropertyExifDateTimeOriginal] as? String)
            .flatMap(Self.parseExifDate)

        let captureTime = capturedDate.map { dateFormatter.string(from: $0) } ?? "Unknown"
        let captureTimeShort = capturedDate.map { shortFormatter.string(from: $0) } ?? "--"

        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
            .map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) } ?? "Unknown"

        let focalLength = Self.formattedExifNumber(exif?[kCGImagePropertyExifFocalLength], suffix: " mm")
        let iso = Self.formattedISO(exif?[kCGImagePropertyExifISOSpeedRatings])
        let aperture = Self.formattedExifNumber(exif?[kCGImagePropertyExifFNumber], prefix: "f/")
        let shutterSpeed = Self.formattedShutter(exif?[kCGImagePropertyExifExposureTime])

        return PhotoMetadata(
            captureTime: captureTime,
            captureTimeShort: captureTimeShort,
            dimensions: pixelWidth > 0 ? "\(pixelWidth) × \(pixelHeight)" : "Unknown",
            fileSize: fileSize,
            focalLength: focalLength,
            shutterSpeed: shutterSpeed,
            aperture: aperture,
            iso: iso
        )
    }

    nonisolated private func makeImage(from source: CGImageSource, maxPixelSize: Int) -> NSImage? {
        guard let cgImage = makeCGImage(from: source, maxPixelSize: maxPixelSize) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: .zero)
    }

    nonisolated private func makeCGImage(from source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: false
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    nonisolated private static func parseExifDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: value)
    }

    nonisolated private static func formattedExifNumber(_ value: Any?, prefix: String = "", suffix: String = "") -> String {
        guard let number = makeDouble(value) else { return "Unknown" }
        return "\(prefix)\(number.formatted(.number.precision(.fractionLength(0...1))))\(suffix)"
    }

    nonisolated private static func formattedISO(_ value: Any?) -> String {
        if let values = value as? [Int], let first = values.first {
            return "ISO \(first)"
        }

        if let values = value as? [NSNumber], let first = values.first {
            return "ISO \(first.intValue)"
        }

        return "Unknown"
    }

    nonisolated private static func formattedShutter(_ value: Any?) -> String {
        guard let exposure = makeDouble(value), exposure > 0 else { return "Unknown" }
        if exposure >= 1 {
            return "\(exposure.formatted(.number.precision(.fractionLength(1)))) s"
        }
        let denominator = Int((1 / exposure).rounded())
        return "1/\(max(1, denominator)) s"
    }

    nonisolated private static func makeDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as Double: number
        case let number as NSNumber: number.doubleValue
        default: nil
        }
    }
}

private struct PixelAnalysis {
    let score: Double
    let reasons: [String]
    let averageBrightness: Double
    let contrast: Double
    let edgeEnergy: Double
}

private struct PixelAnalyzer {
    nonisolated init() {}

    nonisolated func analyze(_ image: CGImage) -> PixelAnalysis {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: Int(height * bytesPerRow))

        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return PixelAnalysis(
                score: 50,
                reasons: ["Evaluation unavailable"],
                averageBrightness: 0.5,
                contrast: 0.5,
                edgeEnergy: 0.5
            )
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var luminance = [Double](repeating: 0, count: width * height)
        var totalBrightness = 0.0

        for index in 0..<(width * height) {
            let offset = index * bytesPerPixel
            let red = Double(data[offset]) / 255
            let green = Double(data[offset + 1]) / 255
            let blue = Double(data[offset + 2]) / 255
            let value = (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
            luminance[index] = value
            totalBrightness += value
        }

        let count = Double(width * height)
        let average = totalBrightness / count

        var variance = 0.0
        var edgeAccumulation = 0.0

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let current = luminance[index]
                variance += pow(current - average, 2)

                if x + 1 < width {
                    edgeAccumulation += abs(current - luminance[index + 1])
                }
                if y + 1 < height {
                    edgeAccumulation += abs(current - luminance[index + width])
                }
            }
        }

        let contrast = min(1, sqrt(variance / count) * 2.8)
        let edgeEnergy = min(1, edgeAccumulation / (count * 0.18))

        var score = 100.0
        var reasons: [String] = []

        if average > 0.82 {
            score -= 28
            reasons.append("Likely overexposed")
        } else if average < 0.18 {
            score -= 28
            reasons.append("Likely underexposed")
        }

        if contrast < 0.14 {
            score -= 18
            reasons.append("Low contrast")
        }

        if edgeEnergy < 0.22 {
            score -= 26
            reasons.append("Soft detail or camera shake")
        } else if edgeEnergy < 0.32 {
            score -= 12
            reasons.append("Mild softness")
        }

        if average > 0.72 && contrast < 0.18 {
            score -= 10
            reasons.append("Flat highlights")
        }

        return PixelAnalysis(
            score: score,
            reasons: reasons,
            averageBrightness: average,
            contrast: contrast,
            edgeEnergy: edgeEnergy
        )
    }
}

private extension Double {
    nonisolated var formattedPercent: String {
        self.formatted(.percent.precision(.fractionLength(0)))
    }
}
