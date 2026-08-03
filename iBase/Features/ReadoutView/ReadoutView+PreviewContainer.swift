import SwiftUI
import SwiftData

@MainActor
struct _ReadoutViewPreview: View {
  @State var path = NavigationPath()
  @State var currentValue: UInt64 = 2026
  @State var selectedBase: Int = 10

  var body: some View {
    ReadoutView(path: self.$path, currentValue: self.$currentValue, selectedBase: self.$selectedBase)
      .modelContainer(Self.previewContainer)
  }
}

extension _ReadoutViewPreview {
  /// Seeded with edge cases on purpose: 0, `UInt64.max`, base 2 and base 36 (docs/07).
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: HistoryEntry.self, configurations: config)

      container.mainContext.insert(HistoryEntry(value: 2026, enteredBase: 10))
      container.mainContext.insert(HistoryEntry(value: 0, enteredBase: 2))
      container.mainContext.insert(HistoryEntry(value: .max, enteredBase: 36))

      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }()
}

#Preview("Readout · 2026") {
  _ReadoutViewPreview()
    .preferredColorScheme(.dark)
}

#Preview("Readout · UInt64.max") {
  _ReadoutViewPreview(currentValue: .max, selectedBase: 36)
    .preferredColorScheme(.dark)
}

#Preview("Readout · zero, base 2") {
  _ReadoutViewPreview(currentValue: 0, selectedBase: 2)
    .preferredColorScheme(.dark)
}
