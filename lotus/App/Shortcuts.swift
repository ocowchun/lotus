//
//  Shortcuts.swift
//  lotus
//

import AppKit
import Foundation
import Observation
import SwiftUI

enum ShortcutKey: String, CaseIterable, Identifiable, Codable {
    case j
    case k
    case s
    case d
    case u
    case m
    case space
    case upArrow
    case downArrow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .j: "J"
        case .k: "K"
        case .s: "S"
        case .d: "D"
        case .u: "U"
        case .m: "M"
        case .space: "Space"
        case .upArrow: "Up Arrow"
        case .downArrow: "Down Arrow"
        }
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case previousPrimary
    case previousSecondary
    case nextPrimary
    case nextSecondary
    case keep
    case reject
    case undecided
    case more
    case zoom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .previousPrimary: "Previous"
        case .previousSecondary: "Previous (Alt)"
        case .nextPrimary: "Next"
        case .nextSecondary: "Next (Alt)"
        case .keep: "Keep"
        case .reject: "Reject"
        case .undecided: "Undecided"
        case .more: "Toggle Metadata Mode"
        case .zoom: "Zoom"
        }
    }
}

struct ReviewShortcuts: Codable {
    var previousPrimary: ShortcutKey = .upArrow
    var previousSecondary: ShortcutKey = .k
    var nextPrimary: ShortcutKey = .downArrow
    var nextSecondary: ShortcutKey = .j
    var keep: ShortcutKey = .s
    var reject: ShortcutKey = .d
    var undecided: ShortcutKey = .u
    var more: ShortcutKey = .m
    var zoom: ShortcutKey = .space

    func key(for action: ShortcutAction) -> ShortcutKey {
        switch action {
        case .previousPrimary: previousPrimary
        case .previousSecondary: previousSecondary
        case .nextPrimary: nextPrimary
        case .nextSecondary: nextSecondary
        case .keep: keep
        case .reject: reject
        case .undecided: undecided
        case .more: more
        case .zoom: zoom
        }
    }

    func updated(_ action: ShortcutAction, key: ShortcutKey) -> ReviewShortcuts {
        var copy = self
        switch action {
        case .previousPrimary: copy.previousPrimary = key
        case .previousSecondary: copy.previousSecondary = key
        case .nextPrimary: copy.nextPrimary = key
        case .nextSecondary: copy.nextSecondary = key
        case .keep: copy.keep = key
        case .reject: copy.reject = key
        case .undecided: copy.undecided = key
        case .more: copy.more = key
        case .zoom: copy.zoom = key
        }
        return copy
    }

    func conflict(for action: ShortcutAction, key: ShortcutKey) -> ShortcutAction? {
        for candidate in ShortcutAction.allCases where candidate != action {
            if self.key(for: candidate) == key {
                return candidate
            }
        }
        return nil
    }
}

@MainActor
@Observable
final class ShortcutStore {
    var shortcuts: ReviewShortcuts {
        didSet { save() }
    }

    private let storageKey = "lotus.review.shortcuts"

    init() {
        if
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(ReviewShortcuts.self, from: data)
        {
            shortcuts = saved
        } else {
            shortcuts = ReviewShortcuts()
        }
    }

    func update(action: ShortcutAction, key: ShortcutKey) throws {
        if let conflict = shortcuts.conflict(for: action, key: key) {
            throw ShortcutConflictError(existingAction: conflict)
        }

        shortcuts = shortcuts.updated(action, key: key)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct ShortcutConflictError: LocalizedError {
    let existingAction: ShortcutAction

    var errorDescription: String? {
        "\(existingAction.title) already uses that shortcut."
    }
}

struct ReviewKeyboardMonitor: ViewModifier {
    let store: ReviewStore
    let shortcuts: ReviewShortcuts

    func body(content: Content) -> some View {
        content
            .background {
                KeyboardEventBridge { event in
                    guard let key = ShortcutKey(event: event) else {
                        return event
                    }

                    let activeKeys = [
                        shortcuts.previousPrimary,
                        shortcuts.previousSecondary,
                        shortcuts.nextPrimary,
                        shortcuts.nextSecondary,
                        shortcuts.keep,
                        shortcuts.reject,
                        shortcuts.undecided,
                        shortcuts.more,
                        shortcuts.zoom
                    ]

                    guard activeKeys.contains(key) else { return event }
                    store.handleShortcut(key)
                    return nil
                }
            }
    }
}

private struct KeyboardEventBridge: NSViewRepresentable {
    let handler: (NSEvent) -> NSEvent?

    func makeNSView(context: Context) -> KeyboardEventView {
        let view = KeyboardEventView()
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: KeyboardEventView, context: Context) {
        nsView.handler = handler
    }
}

private final class KeyboardEventView: NSView {
    var handler: ((NSEvent) -> NSEvent?)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let handler = self?.handler else { return event }
            return handler(event)
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

private extension ShortcutKey {
    init?(event: NSEvent) {
        switch event.keyCode {
        case 126: self = .upArrow
        case 125: self = .downArrow
        case 49: self = .space
        default:
            guard let character = event.charactersIgnoringModifiers?.lowercased(), character.count == 1 else {
                return nil
            }

            switch character {
            case "j": self = .j
            case "k": self = .k
            case "s": self = .s
            case "d": self = .d
            case "u": self = .u
            case "m": self = .m
            default: return nil
            }
        }
    }
}

struct SettingsView: View {
    @Environment(ShortcutStore.self) private var shortcutStore
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Review Shortcuts") {
                ForEach(ShortcutAction.allCases) { action in
                    HStack {
                        Text(action.title)
                        Spacer()

                        Picker(action.title, selection: Binding(
                            get: { shortcutStore.shortcuts.key(for: action) },
                            set: { newKey in
                                do {
                                    try shortcutStore.update(action: action, key: newKey)
                                    errorMessage = nil
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        )) {
                            ForEach(ShortcutKey.allCases) { key in
                                Text(key.title).tag(key)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
            }

            Section {
                Text("Arrow and letter shortcuts are available in this first build. Changes apply immediately.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460, height: 420)
    }
}
