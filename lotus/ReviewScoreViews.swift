//
//  ReviewScoreViews.swift
//  lotus
//

import SwiftUI

struct FullModeEvaluationPanel: View {
    let photo: PhotoRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Evaluation")
                    .font(.headline)

                Spacer()

                AnalysisSummaryView(analysis: photo.analysis)
            }

            ScoreSectionBody(analysis: photo.analysis, showExpandedEvaluation: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

struct ScoreStatusPanel: View {
    let analysis: AnalysisState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)

            ScoreSectionBody(analysis: analysis, showExpandedEvaluation: false)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

struct ScoreBreakdownPanel: View {
    let breakdown: [ScoreBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Technical Breakdown")
                .font(.headline)

            ScoreBreakdownView(breakdown: breakdown)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

struct AnalysisSummaryView: View {
    let analysis: AnalysisState

    var body: some View {
        switch analysis {
        case .pending:
            Label("Analyzing...", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed:
            Label("Unavailable", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .ready(let score):
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score.value) / 100")
                    .font(.title3.weight(.semibold))
                Text(score.label.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(score.label.tint)
            }
        }
    }
}

struct ScoreSectionBody: View {
    let analysis: AnalysisState
    let showExpandedEvaluation: Bool

    var body: some View {
        switch analysis {
        case .pending:
            Text("Lotus is computing an initial technical evaluation for this photo.")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .failed:
            Text("Lotus could not evaluate this photo yet.")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .ready(let score):
            ReadyScoreSection(score: score, showExpandedEvaluation: showExpandedEvaluation)
        }
    }
}

private struct ReadyScoreSection: View {
    let score: PhotoScore
    let showExpandedEvaluation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScoreReasonsView(reasons: score.reasons)

            if showExpandedEvaluation {
                Divider()
                ScoreBreakdownView(breakdown: score.breakdown)
            }
        }
    }
}

private struct ScoreReasonsView: View {
    let reasons: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(reasons, id: \.self) { reason in
                Text(reason)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(Color(nsColor: .tertiarySystemFill))
                    }
            }
        }
    }
}

private struct ScoreBreakdownView: View {
    let breakdown: [ScoreBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(breakdown) { item in
                HStack {
                    Text(item.title)
                    Spacer()
                    Text(item.value)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            HStack {
                Text("Similar Set")
                Spacer()
                Text("Not analyzed in this workflow-first build")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
}

struct DecisionChip: View {
    let decision: PhotoDecision

    var body: some View {
        Label(decision.title, systemImage: decision.iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(decision.tint.opacity(0.15))
            }
            .foregroundStyle(decision.tint)
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat) {
        self.spacing = spacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth, lineWidth > 0 {
                totalHeight += lineHeight + spacing
                maxLineWidth = max(maxLineWidth, lineWidth - spacing)
                lineWidth = 0
                lineHeight = 0
            }

            lineWidth += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        maxLineWidth = max(maxLineWidth, lineWidth - spacing)
        totalHeight += lineHeight

        return CGSize(width: maxLineWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
