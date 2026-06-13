//
//  DailyLevelsApp.swift
//  Daily Levels
//
//  App entry point. Creates the SwiftData container and a single shared FocusEngine,
//  injected into the view tree.
//

import SwiftUI
import SwiftData

@main
struct DailyLevelsApp: App {
    private let container: ModelContainer
    @State private var engine: FocusEngine

    init() {
        // One local SwiftData store for FocusSession. `try!` is acceptable here: if the
        // on-device store can't open, the app genuinely can't function.
        let container = try! ModelContainer(for: FocusSession.self)
        self.container = container
        // `_engine = State(...)` is how you seed a @State value from inside init.
        _engine = State(initialValue: FocusEngine(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(engine)
        }
        .modelContainer(container)
    }
}
