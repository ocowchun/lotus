//
//  ReviewPreviewPane.swift
//  lotus
//

import AppKit
import SwiftUI

struct CurrentPhotoPane: View {
    let store: ReviewStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(alignment: .leading, spacing: 14) {
                    PreviewStage(store: store)
                        .frame(maxWidth: .infinity)
                        .frame(height: previewHeight(in: proxy.size.height))

                    if let photo = store.currentPhoto {
                        MetadataPanel(photo: photo, mode: store.metadataMode)
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

    private func previewHeight(in availableHeight: CGFloat) -> CGFloat {
        let ratio: CGFloat = store.metadataMode == .concise ? 0.68 : 0.50
        return max(availableHeight * ratio, 300)
    }
}

private struct PreviewStage: View {
    let store: ReviewStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))

            PreviewStageContent(
                image: store.currentDisplayImage,
                isPreviewLoading: store.isPreviewLoading
            )
        }
    }
}

private struct PreviewStageContent: View {
    let image: NSImage?
    let isPreviewLoading: Bool

    var body: some View {
        VStack(spacing: 12) {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
            } else if isPreviewLoading {
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
