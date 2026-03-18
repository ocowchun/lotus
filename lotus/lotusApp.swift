//
//  lotusApp.swift
//  lotus
//
//  Created by ocowchun on 2026/3/16.
//

import SwiftUI

@main
struct lotusApp: App {
    @StateObject private var shortcutStore: ShortcutStore
    @State private var reviewStore: ReviewStore

    init() {
        let shortcutStore = ShortcutStore()
        _shortcutStore = StateObject(wrappedValue: shortcutStore)
        _reviewStore = State(wrappedValue: ReviewStore(shortcutStore: shortcutStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: reviewStore)
                .environmentObject(shortcutStore)
        }

        Settings {
            SettingsView()
                .environmentObject(shortcutStore)
        }
    }
}
