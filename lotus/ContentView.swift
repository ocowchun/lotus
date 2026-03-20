//
//  ContentView.swift
//  lotus
//
//  Created by ocowchun on 2026/3/16.
//

import SwiftUI

struct ContentView: View {
    @Environment(ShortcutStore.self) private var shortcutStore

    let store: ReviewStore

    private var contentState: ReviewContentState {
        if let completion = store.completion {
            return .completion(completion)
        }

        if store.photos.isEmpty {
            return .empty(
                isImporting: store.isImporting,
                errorMessage: store.errorMessage
            )
        }

        return .workspace
    }

    var body: some View {
        ReviewContentContainer(store: store, contentState: contentState)
            .frame(minWidth: 1120, minHeight: 720)
            .background(Color(nsColor: .windowBackgroundColor))
            .modifier(ReviewKeyboardMonitor(store: store, shortcuts: shortcutStore.shortcuts))
    }
}

private enum ReviewContentState {
    case completion(ReviewCompletion)
    case empty(isImporting: Bool, errorMessage: String?)
    case workspace

    var showsWorkspace: Bool {
        if case .workspace = self {
            return true
        }

        return false
    }
}

private struct ReviewContentContainer: View {
    let store: ReviewStore
    let contentState: ReviewContentState

    var body: some View {
        ZStack {
            ReviewWorkspaceView(store: store)
                .opacity(contentState.showsWorkspace ? 1 : 0)
                .allowsHitTesting(contentState.showsWorkspace)
                .accessibilityHidden(!contentState.showsWorkspace)

            switch contentState {
            case .completion(let completion):
                CompletionStateView(
                    completion: completion,
                    selectFolder: store.selectFolder
                )
            case .empty(let isImporting, let errorMessage):
                EmptyStateView(
                    isImporting: isImporting,
                    errorMessage: errorMessage,
                    selectFolder: store.selectFolder
                )
            case .workspace:
                EmptyView()
            }
        }
    }
}
