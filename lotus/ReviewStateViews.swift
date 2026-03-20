//
//  ReviewStateViews.swift
//  lotus
//

import SwiftUI

struct CompletionStateView: View {
    let completion: ReviewCompletion
    let selectFolder: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: completion.trashedCount > 0 ? "trash.circle" : "checkmark.circle")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Text(completion.title)
                    .font(.system(size: 28, weight: .semibold))

                Text(completion.folderName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(completion.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            Button(action: selectFolder) {
                Label("Review Another Folder", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct EmptyStateView: View {
    let isImporting: Bool
    let errorMessage: String?
    let selectFolder: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Review A Folder Of Photos")
                    .font(.system(size: 28, weight: .semibold))

                Text("Select a folder to scan photos, review them in order, and make keep or reject decisions in memory.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            Button(action: selectFolder) {
                Label("Select Folder", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isImporting)

            if isImporting {
                ProgressView("Scanning folder...")
                    .controlSize(.regular)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct ReviewWorkspaceView: View {
    let store: ReviewStore

    var body: some View {
        VStack(spacing: 0) {
            ReviewHeaderView(store: store)

            Divider()

            HSplitView {
                CurrentPhotoPane(store: store)
                    .frame(minWidth: 640, idealWidth: 760)

                SidebarPane(store: store)
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
            }
        }
    }
}

private struct ReviewHeaderView: View {
    let store: ReviewStore

    var body: some View {
        HStack(spacing: 12) {
            ReviewHeaderStatusView(store: store)

            Spacer(minLength: 12)

            ReviewHeaderCountsView(summary: store.summary)

            Button(action: store.selectFolder) {
                Label("Change Folder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ReviewHeaderStatusView: View {
    let store: ReviewStore

    var body: some View {
        HStack(spacing: 10) {
            Text(store.folderURL?.lastPathComponent ?? "Review")
                .font(.headline)

            Text(store.positionText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            if store.isImporting {
                Text("Scanning \(store.photos.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
    }
}

private struct ReviewHeaderCountsView: View {
    let summary: ReviewSummary

    var body: some View {
        HStack(spacing: 8) {
            CountBadge(title: "Keep", count: summary.keepCount, tint: PhotoDecision.keep.tint)
            CountBadge(title: "Reject", count: summary.rejectCount, tint: PhotoDecision.reject.tint)
            CountBadge(title: "Undecided", count: summary.undecidedCount, tint: PhotoDecision.undecided.tint)
        }
    }
}

private struct CountBadge: View {
    let title: String
    let count: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(count)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.12))
        }
    }
}
