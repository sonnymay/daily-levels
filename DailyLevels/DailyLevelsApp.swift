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
    @State private var store = Store()

    init() {
        // Unit tests supply their own isolated containers; keep the otherwise-unused app host
        // in memory so it never races the simulator's Application Support directory setup.
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isTesting)
        // Production still uses one local SwiftData store. `try!` is acceptable here: if the
        // on-device store can't open, the app genuinely can't function.
        let container = try! ModelContainer(for: FocusSession.self, configurations: configuration)
        self.container = container
        let engine = FocusEngine(context: container.mainContext)
        #if DEBUG
        engine.applyDebugLaunchArguments()   // no-op unless -seedDemoData / -autoStart passed
        #endif
        // `_engine = State(...)` is how you seed a @State value from inside init.
        _engine = State(initialValue: engine)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(engine)
                .environment(store)
                .preferredColorScheme(.light)   // calm cream UI is light by design (SPEC §4)
        }
        .modelContainer(container)
    }
}
