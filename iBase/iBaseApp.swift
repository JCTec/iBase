import AppIntents
import SwiftUI
import SwiftData

@main
struct iBaseApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      HistoryEntry.self,
    ])
    let launchArguments = ProcessInfo.processInfo.arguments
    let usesTemporaryStore = launchArguments.contains("-UITesting") || launchArguments.contains("-ShowcaseData")

    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: usesTemporaryStore)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      iBaseNavigationView()
        .preferredColorScheme(.dark) // dark-only, flagged in 00
    }
    .modelContainer(self.sharedModelContainer)
    #if os(macOS)
    .defaultSize(width: 900.0, height: 760.0)
    #endif
  }
}

// MARK: App Intents

/// The primary action is open-app only (docs/00, docs/08). A `ConvertNumberIntent` is the
/// recorded growth path; open-app ships first.
struct OpeniBaseIntent: AppIntent {
  static let title: LocalizedStringResource = "Open iBase"
  static let description = IntentDescription("Open iBase and see the number in every base.")
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    return .result()
  }
}

struct iBaseShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpeniBaseIntent(),
      phrases: [
        "Open \(.applicationName)",
        "Convert a number with \(.applicationName)"
      ],
      shortTitle: "Open iBase",
      systemImageName: "number.square.fill"
    )
  }
}
