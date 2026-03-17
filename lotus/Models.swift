//
//  Models.swift
//  lotus
//

import AppKit
import Foundation
import SwiftUI

enum PhotoDecision: String, CaseIterable, Codable {
    case undecided
    case keep
    case reject

    var title: String {
        switch self {
        case .undecided: "Undecided"
        case .keep: "Keep"
        case .reject: "Reject"
        }
    }

    var iconName: String {
        switch self {
        case .undecided: "circle.dotted"
        case .keep: "checkmark.circle.fill"
        case .reject: "trash.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .undecided: .secondary
        case .keep: .green
        case .reject: .red
        }
    }
}

enum ReviewFilter: String, CaseIterable, Identifiable {
    case all
    case undecided
    case keep
    case reject

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    func matches(_ decision: PhotoDecision) -> Bool {
        switch self {
        case .all: true
        case .undecided: decision == .undecided
        case .keep: decision == .keep
        case .reject: decision == .reject
        }
    }
}

struct MetadataValue: Identifiable {
    let label: String
    let value: String
    var id: String { "\(label)-\(value)" }
}

enum MetadataPanelMode: String, CaseIterable {
    case concise
    case full

    var title: String {
        switch self {
        case .concise: "Concise"
        case .full: "Full"
        }
    }
}

struct PhotoMetadata {
    let captureTime: String
    let captureTimeShort: String
    let dimensions: String
    let fileSize: String
    let focalLength: String
    let shutterSpeed: String
    let aperture: String
    let iso: String

    var captureEntries: [MetadataValue] {
        [
            MetadataValue(label: "Captured", value: captureTime),
            MetadataValue(label: "Dimensions", value: dimensions)
        ]
    }

    var exposureEntries: [MetadataValue] {
        [
            MetadataValue(label: "Focal Length", value: focalLength),
            MetadataValue(label: "Shutter", value: shutterSpeed),
            MetadataValue(label: "Aperture", value: aperture),
            MetadataValue(label: "ISO", value: iso)
        ]
    }

    var fileEntries: [MetadataValue] {
        [MetadataValue(label: "File Size", value: fileSize)]
    }

    var conciseEntries: [MetadataValue] {
        [
            MetadataValue(label: "Focal Length", value: focalLength),
            MetadataValue(label: "Shutter", value: shutterSpeed),
            MetadataValue(label: "Aperture", value: aperture),
            MetadataValue(label: "ISO", value: iso)
        ]
    }

    var allEntries: [MetadataValue] {
        captureEntries + exposureEntries + fileEntries
    }

    var secondaryEntries: [MetadataValue] {
        captureEntries + fileEntries
    }
}

struct ScoreBreakdown: Identifiable {
    let title: String
    let value: String
    var id: String { "\(title)-\(value)" }
}

enum ScoreLabel {
    case good
    case warning
    case poor

    var title: String {
        switch self {
        case .good: "Good"
        case .warning: "Warning"
        case .poor: "Poor"
        }
    }

    var tint: Color {
        switch self {
        case .good: .green
        case .warning: .orange
        case .poor: .red
        }
    }
}

struct PhotoScore {
    let value: Int
    let label: ScoreLabel
    let reasons: [String]
    let breakdown: [ScoreBreakdown]
}

enum AnalysisState {
    case pending
    case ready(PhotoScore)
    case failed
}

struct PhotoRecord: Identifiable {
    let id: UUID
    let url: URL
    let filename: String
    var metadata: PhotoMetadata
    var decision: PhotoDecision
    var analysis: AnalysisState
    var thumbnail: NSImage?
}

struct ReviewSummary {
    let keepCount: Int
    let rejectCount: Int
    let undecidedCount: Int

    static func make(from photos: [PhotoRecord]) -> ReviewSummary {
        var keepCount = 0
        var rejectCount = 0
        var undecidedCount = 0

        for photo in photos {
            switch photo.decision {
            case .keep: keepCount += 1
            case .reject: rejectCount += 1
            case .undecided: undecidedCount += 1
            }
        }

        return ReviewSummary(
            keepCount: keepCount,
            rejectCount: rejectCount,
            undecidedCount: undecidedCount
        )
    }
}

struct ReviewCompletion {
    let folderName: String
    let keepCount: Int
    let trashedCount: Int

    var title: String {
        trashedCount > 0 ? "Rejected Photos Moved To Trash" : "Review Complete"
    }

    var message: String {
        if trashedCount > 0 {
            "\(trashedCount) rejected photo(s) were moved to Trash. \(keepCount) kept photo(s) remain in place."
        } else {
            "No rejected photos needed to be moved. \(keepCount) photo(s) were marked keep."
        }
    }
}
