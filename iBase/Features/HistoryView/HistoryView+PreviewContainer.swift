import SwiftUI
import SwiftData

@MainActor
struct _HistoryViewPreview: View {
  @State var path = NavigationPath()
  @State var currentValue: UInt64 = 2026
  @State var selectedBase: Int = 10

  let container: ModelContainer

  var body: some View {
    NavigationStack {
      HistoryView(path: self.$path, currentValue: self.$currentValue, selectedBase: self.$selectedBase)
        .navigationTitle("History")
    }
    .modelContainer(self.container)
    .preferredColorScheme(.dark)
  }
}

extension _HistoryViewPreview {
  /// Edge cases on purpose: 0, `UInt64.max`, base 2 (longest string) and base 36 (densest) (docs/07).
  static let seededContainer: ModelContainer = {
    return Self.makeContainer(seeding: [
      HistoryEntry(value: 2026, enteredBase: 10),
      HistoryEntry(value: 126, enteredBase: 16),
      HistoryEntry(value: 0, enteredBase: 2),
      HistoryEntry(value: .max, enteredBase: 36),
      HistoryEntry(value: .max, enteredBase: 2)
    ])
  }()

  /// Past the disclosure threshold, so the search field appears (docs/06).
  static let crowdedContainer: ModelContainer = {
    return Self.makeContainer(seeding: (0..<HistoryView.searchThreshold + 2).map { index in
      return HistoryEntry(value: UInt64(index) * 1234, enteredBase: 16)
    })
  }()

  static let emptyContainer: ModelContainer = {
    return Self.makeContainer(seeding: [])
  }()

  private static func makeContainer(seeding entries: [HistoryEntry]) -> ModelContainer {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: HistoryEntry.self, configurations: config)

      entries.forEach { entry in
        container.mainContext.insert(entry)
      }

      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }
}

#Preview("History · edge cases") {
  _HistoryViewPreview(container: _HistoryViewPreview.seededContainer)
}

#Preview("History · search disclosed") {
  _HistoryViewPreview(container: _HistoryViewPreview.crowdedContainer)
}

#Preview("History · empty") {
  _HistoryViewPreview(container: _HistoryViewPreview.emptyContainer)
}
