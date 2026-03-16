//
//  ContentView.swift
//  lotus
//
//  Created by ocowchun on 2026/3/16.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ReviewStore
    @EnvironmentObject private var shortcutStore: ShortcutStore

    var body: some View {
        Group {
            if store.photos.isEmpty {
                EmptyStateView(
                    isImporting: store.isImporting,
                    errorMessage: store.errorMessage,
                    selectFolder: store.selectFolder
                )
            } else {
                ReviewWorkspaceView(store: store)
            }
        }
        .frame(minWidth: 1120, minHeight: 720)
        .background(Color(nsColor: .windowBackgroundColor))
        .modifier(ReviewKeyboardMonitor(store: store, shortcuts: shortcutStore.shortcuts))
    }
}

private struct EmptyStateView: View {
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

private struct ReviewWorkspaceView: View {
    @ObservedObject var store: ReviewStore

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
    @ObservedObject var store: ReviewStore

    var body: some View {
        HStack(spacing: 12) {
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

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                CountBadge(title: "Keep", count: store.summary.keepCount, tint: PhotoDecision.keep.tint)
                CountBadge(title: "Reject", count: store.summary.rejectCount, tint: PhotoDecision.reject.tint)
                CountBadge(title: "Undecided", count: store.summary.undecidedCount, tint: PhotoDecision.undecided.tint)
            }

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

private struct CurrentPhotoPane: View {
    @ObservedObject var store: ReviewStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(alignment: .leading, spacing: 14) {
                    PreviewStage(store: store)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(proxy.size.height * 0.8, 360))

                    if let photo = store.currentPhoto {
                        MetadataPanel(photo: photo, detailsExpanded: store.isDetailsExpanded)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                .padding(20)

                if store.isZoomed, let image = store.currentDisplayImage {
                    ZoomOverlay(image: image, close: store.toggleZoom)
                        .transition(.opacity)
                }
            }
        }
    }
}

private struct PreviewStage: View {
    @ObservedObject var store: ReviewStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))

            VStack(spacing: 12) {
                if let image = store.currentDisplayImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(18)
                } else if store.isPreviewLoading {
                    ProgressView("Loading preview...")
                        .controlSize(.large)
                } else {
                    ContentUnavailableView(
                        "No Photo Selected",
                        systemImage: "photo",
                        description: Text("Select a photo from the list to start reviewing.")
                    )
                }
            }
        }
    }
}

private struct ZoomOverlay: View {
    let image: NSImage
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(.black.opacity(0.92))
                .ignoresSafeArea()

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: close) {
                Label("Close", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.85))
            .padding(18)
        }
    }
}

private struct MetadataPanel: View {
    let photo: PhotoRecord
    let detailsExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                DecisionChip(decision: photo.decision)
            }

            HStack(alignment: .top, spacing: 28) {
                MetadataColumn(title: "Capture", values: photo.metadata.captureEntries)
                MetadataColumn(title: "Exposure", values: photo.metadata.exposureEntries)
                MetadataColumn(title: "File", values: photo.metadata.fileEntries)
            }

            ScoreSection(photo: photo, detailsExpanded: detailsExpanded)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }
}

private struct MetadataColumn: View {
    let title: String
    let values: [MetadataValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(values) { value in
                VStack(alignment: .leading, spacing: 2) {
                    Text(value.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(value.value)
                        .font(.subheadline.weight(.medium))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ScoreSection: View {
    let photo: PhotoRecord
    let detailsExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Evaluation")
                    .font(.headline)

                Spacer()

                switch photo.analysis {
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

            switch photo.analysis {
            case .pending:
                Text("Lotus is computing an initial technical evaluation for this photo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .failed:
                Text("Lotus could not evaluate this photo yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .ready(let score):
                FlowLayout(spacing: 8) {
                    ForEach(score.reasons, id: \.self) { reason in
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

                if detailsExpanded {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(score.breakdown) { item in
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
        }
    }
}

private struct SidebarPane: View {
    @ObservedObject var store: ReviewStore

    var body: some View {
        VStack(spacing: 0) {
            SidebarToolbar(store: store)
            Divider()
            PhotoList(store: store)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct SidebarToolbar: View {
    @ObservedObject var store: ReviewStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Filter", selection: Binding(
                get: { store.filter },
                set: { store.setFilter($0) }
            )) {
                ForEach(ReviewFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("\(store.visiblePhotos.count) visible")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if store.isImporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding(14)
    }
}

private struct PhotoList: View {
    @ObservedObject var store: ReviewStore

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: Binding(
                get: { store.selectedPhotoID },
                set: { newValue in
                    if let newValue {
                        store.selectPhoto(id: newValue)
                    }
                }
            )) {
                ForEach(store.visiblePhotos) { photo in
                    PhotoRow(photo: photo)
                        .tag(photo.id)
                        .id(photo.id)
                }
            }
            .listStyle(.sidebar)
            .onAppear {
                scrollToSelectedPhoto(with: proxy)
            }
            .onChange(of: store.selectedPhotoID) { _, _ in
                scrollToSelectedPhoto(with: proxy)
            }
            .onChange(of: store.visiblePhotos.map(\.id)) { _, _ in
                scrollToSelectedPhoto(with: proxy)
            }
        }
    }

    private func scrollToSelectedPhoto(with proxy: ScrollViewProxy) {
        guard let selectedPhotoID = store.selectedPhotoID else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.16)) {
                proxy.scrollTo(selectedPhotoID, anchor: .center)
            }
        }
    }
}

private struct PhotoRow: View {
    let photo: PhotoRecord

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(image: photo.thumbnail)

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.filename)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if case .ready(let score) = photo.analysis {
                        Text("\(score.value)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(score.label.tint)
                    }

                    Text(photo.metadata.captureTimeShort)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: photo.decision.iconName)
                .foregroundStyle(photo.decision.tint)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.vertical, 4)
    }
}

private struct ThumbnailView: View {
    let image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(width: 52, height: 52)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DecisionChip: View {
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

private struct FlowLayout: Layout {
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
