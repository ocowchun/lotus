//
//  ReviewMetadataPanel.swift
//  lotus
//

import SwiftUI

struct MetadataPanel: View {
    let photo: PhotoRecord
    let mode: MetadataPanelMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if mode == .concise {
                ConciseMetadataContent(photo: photo)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    MetadataHeader(photo: photo, mode: mode)
                    FullMetadataContent(photo: photo)
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }
}

private struct MetadataHeader: View {
    let photo: PhotoRecord
    let mode: MetadataPanelMode

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(photo.filename)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text(photo.url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                ModeChip(mode: mode)
                DecisionChip(decision: photo.decision)
            }
        }
    }
}

private struct ModeChip: View {
    let mode: MetadataPanelMode

    var body: some View {
        Text(mode.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(Color(nsColor: .tertiarySystemFill))
            }
            .foregroundStyle(.secondary)
    }
}

private struct ConciseMetadataContent: View {
    let photo: PhotoRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ConciseScoreCard(analysis: photo.analysis)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DecisionChip(decision: photo.decision)
            }

            MetadataMetricGrid(values: photo.metadata.conciseEntries, columns: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ConciseScoreCard: View {
    let analysis: AnalysisState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Score")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            AnalysisSummaryView(analysis: analysis)
                .frame(maxWidth: .infinity, alignment: .leading)

            if case .pending = analysis {
                Text("Evaluating technical quality.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if case .failed = analysis {
                Text("Evaluation unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

private struct MetadataMetricGrid: View {
    let values: [MetadataValue]
    let columns: Int

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: 110), spacing: 12, alignment: .top),
                count: columns
            ),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(values) { value in
                MetadataMetricCard(value: value)
            }
        }
    }
}

private struct MetadataMetricCard: View {
    let value: MetadataValue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value.value)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

private struct FullMetadataContent: View {
    let photo: PhotoRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MetadataMetricSection(photo: photo)

            HStack(alignment: .top, spacing: 16) {
                FullModeEvaluationPanel(photo: photo)
                FullModeScoreDetail(photo: photo)
            }
        }
    }
}

private struct MetadataMetricSection: View {
    let photo: PhotoRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetadataMetricGrid(values: photo.metadata.conciseEntries, columns: 4)
            MetadataMetricGrid(values: photo.metadata.secondaryEntries, columns: 3)
        }
    }
}

private struct FullModeScoreDetail: View {
    let photo: PhotoRecord

    var body: some View {
        Group {
            if case .ready(let score) = photo.analysis {
                ScoreBreakdownPanel(breakdown: score.breakdown)
            } else {
                ScoreStatusPanel(analysis: photo.analysis)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
