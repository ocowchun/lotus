//
//  ReviewSidebar.swift
//  lotus
//

import AppKit
import SwiftUI

struct SidebarPane: View {
    let store: ReviewStore

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
    let store: ReviewStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(
                "Filter",
                selection: Binding(
                    get: { store.filter },
                    set: { store.setFilter($0) }
                )
            ) {
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
    let store: ReviewStore

    var body: some View {
        ScrollViewReader { proxy in
            List(
                selection: Binding(
                    get: { store.selectedPhotoID },
                    set: { newValue in
                        if let newValue {
                            store.selectPhoto(id: newValue)
                        }
                    }
                )
            ) {
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
