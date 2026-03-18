//
//  lotusApp.swift
//  lotus
//
//  Created by ocowchun on 2026/3/16.
//

import SwiftUI

@main
struct lotusApp: App {
    @State private var shortcutStore: ShortcutStore
    @State private var reviewStore: ReviewStore

    init() {
        let shortcutStore = ShortcutStore()
        _shortcutStore = State(wrappedValue: shortcutStore)
        _reviewStore = State(wrappedValue: ReviewStore(shortcutStore: shortcutStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: reviewStore)
                .environment(shortcutStore)
        }

        Settings {
            SettingsView()
                .environment(shortcutStore)
        }
    }
}
